class_name IslandLayout
extends RefCounted
## The island's shape and placements, from data/island.json. Plain data and maths, no scene,
## so the simulation and tests can ask "how high is the ground here?" without rendering anything.
## Heights follow the pilot's rawHeight / exactHeight / heightAt (docs/pilot/index.html, "World layout and terrain").

var data: Dictionary
var size_m: float
var segments: int
var cell_m: float
var half_m: float
var verts_per_side: int
var sea_floor_m: float
## Heights at the grid corners, row by row (z), stored as 32-bit floats like the pilot's HMAP.
var heights := PackedFloat32Array()

var _terrain: Dictionary
var _mountain: Dictionary
var _hill_x: float
var _hill_z: float
var _flats: Array[Dictionary] = []


static func from_file(path: String) -> IslandLayout:
	var text := FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(text)
	assert(parsed is Dictionary, "Could not read %s" % path)
	return IslandLayout.new(parsed)


func _init(island: Dictionary) -> void:
	data = island
	_terrain = data["terrain"]
	_mountain = data["mountain"]
	size_m = _terrain["size_m"]
	segments = int(_terrain["segments"])
	cell_m = size_m / segments
	half_m = size_m / 2.0
	verts_per_side = segments + 1
	sea_floor_m = _terrain["sea_floor_m"]
	var hill_village := village(str(data["hill"]["village"]))
	_hill_x = hill_village["x"]
	_hill_z = hill_village["z"]
	_build_flats()
	_build_heights()


func villages() -> Array:
	return data["villages"]


func village(id: String) -> Dictionary:
	for v: Dictionary in data["villages"]:
		if v["id"] == id:
			return v
	assert(false, "No village with id %s" % id)
	return {}


## The pilot's height before villages, fields and the circle are flattened.
func raw_height(x: float, z: float) -> float:
	var offsets: Dictionary = _terrain["noise_offsets"]
	var warp_scale: float = _terrain["warp_scale"]
	var warp_amount: float = _terrain["warp_amount_m"]
	var wx := x + PilotNoise.fbm(x * warp_scale + offsets["warp_x"][0], z * warp_scale + offsets["warp_x"][1]) * warp_amount
	var wz := z + PilotNoise.fbm(x * warp_scale + offsets["warp_z"][0], z * warp_scale + offsets["warp_z"][1]) * warp_amount
	var r := Vector2(wx, wz * float(_terrain["z_squash"])).length()
	var fade: Array = _terrain["land_fade_m"]
	var land := 1.0 - smoothstep(fade[0], fade[1], r)

	var roll_scale: float = _terrain["roll_scale"]
	var roll := PilotNoise.fbm(x * roll_scale + offsets["roll"][0], z * roll_scale + offsets["roll"][1]) * 0.5 + 0.5
	var h: float = _terrain["base_height_m"] + roll * float(_terrain["roll_height_m"])

	var md2 := _dist2(x, z, _mountain["x"], _mountain["z"])
	var sigma: float = _mountain["sigma_m"]
	var rough_scale: float = _mountain["rough_scale"]
	var rough := PilotNoise.fbm(x * rough_scale, z * rough_scale) * 0.5 + 0.5
	h += float(_mountain["height_m"]) * exp(-md2 / (2.0 * sigma * sigma)) * (float(_mountain["rough_min"]) + float(_mountain["rough_range"]) * rough)

	var hill: Dictionary = data["hill"]
	var hill_sigma: float = hill["sigma_m"]
	h += float(hill["height_m"]) * exp(-_dist2(x, z, _hill_x, _hill_z) / (2.0 * hill_sigma * hill_sigma))
	return h * land + (1.0 - land) * sea_floor_m


## Height with villages, fields and the stone circle flattened.
func exact_height(x: float, z: float) -> float:
	var h := raw_height(x, z)
	var inner: float = _terrain["flat_inner_fraction"]
	for f in _flats:
		var d := sqrt(_dist2(x, z, f["x"], f["z"]))
		var r: float = f["r"]
		if d < r:
			h = lerpf(h, f["h"], 1.0 - smoothstep(r * inner, r, d))
	return h


## Bilinear height of the terrain grid; the sea floor outside it.
func height_at(x: float, z: float) -> float:
	var fx := (x + half_m) / cell_m
	var fz := (z + half_m) / cell_m
	if fx < 0.0 or fz < 0.0 or fx >= segments or fz >= segments:
		return sea_floor_m
	var i := floori(fx)
	var j := floori(fz)
	var tx := fx - i
	var tz := fz - j
	var row := j * verts_per_side
	var a := heights[row + i]
	var b := heights[row + i + 1]
	var c := heights[row + verts_per_side + i]
	var d := heights[row + verts_per_side + i + 1]
	return lerpf(lerpf(a, b, tx), lerpf(c, d, tx), tz)


## Height of the land, or of the sea surface where the land is under water.
func ground_at(x: float, z: float) -> float:
	return maxf(height_at(x, z), 0.0)


## Where a ray first meets the ground or sea, or null if it never does (pilot: screenToGround).
func ray_to_ground(origin: Vector3, dir: Vector3) -> Variant:
	var t := 1.0
	var prev := t
	for _step in 500:
		if t >= 1600.0:
			break
		var p := origin + dir * t
		if p.y <= ground_at(p.x, p.z):
			var lo := prev
			var hi := t
			for _k in 9:
				var mid := (lo + hi) / 2.0
				var q := origin + dir * mid
				if q.y <= ground_at(q.x, q.z):
					hi = mid
				else:
					lo = mid
			return origin + dir * hi
		prev = t
		t += maxf(0.6, t * 0.012)
	return null


## Grid corner (i, j) to world x or z.
func corner(i: int) -> float:
	return -half_m + i * cell_m


func _build_flats() -> void:
	var min_h: float = _terrain["flat_min_height_m"]
	for v: Dictionary in data["villages"]:
		_add_flat(v["x"], v["z"], float(v["radius_m"]) + float(_terrain["village_flat_pad_m"]), min_h)
	for f: Dictionary in data["fields"]:
		var r := maxf(f["w"], f["d"]) * float(_terrain["field_flat_scale"]) + float(_terrain["field_flat_pad_m"])
		_add_flat(f["x"], f["z"], r, min_h)
	var circle: Dictionary = data["stone_circle"]
	_add_flat(circle["x"], circle["z"], circle["flatten_radius_m"], min_h)


func _add_flat(x: float, z: float, r: float, min_h: float) -> void:
	_flats.append({"x": x, "z": z, "r": r, "h": maxf(min_h, raw_height(x, z))})


func _build_heights() -> void:
	heights.resize(verts_per_side * verts_per_side)
	for j in verts_per_side:
		for i in verts_per_side:
			heights[j * verts_per_side + i] = exact_height(corner(i), corner(j))


static func _dist2(x: float, z: float, cx: float, cz: float) -> float:
	return (x - cx) * (x - cx) + (z - cz) * (z - cz)
