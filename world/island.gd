class_name Island
extends Node3D
## Builds the island scene from an IslandLayout: terrain, sea, trees, rocks, clouds, and the
## villages, fields and stone circle as they stand at the start of the pilot (static for now).

## Corners of the two triangles in each terrain cell, as (x, z) offsets: the pilot's
## triangulation (Three.js PlaneGeometry), wound clockwise for Godot.
const TRIANGLE_CORNERS: Array[Vector2i] = [
	Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1),
	Vector2i(0, 1), Vector2i(1, 0), Vector2i(1, 1),
]

var layout: IslandLayout

var _clouds: Array[Node3D] = []
var _cloud_speeds: Array[float] = []


func _ready() -> void:
	_build_terrain()
	_build_sea()
	_build_trees()
	_build_rocks()
	_build_clouds()
	for v: Dictionary in layout.villages():
		_build_village(v)
	_build_stone_circle()
	_build_fields()


func _process(delta: float) -> void:
	var wrap_x := Tuning.num("clouds.wrap_x_m")
	for i in _clouds.size():
		var c := _clouds[i]
		c.position.x += _cloud_speeds[i] * delta
		if c.position.x > wrap_x:
			c.position.x = -wrap_x


func _build_terrain() -> void:
	var pal := _terrain_palette()
	var n := layout.verts_per_side
	var colors := PackedColorArray()
	colors.resize(n * n)
	for j in n:
		for i in n:
			colors[j * n + i] = _terrain_color(i, j, pal)

	var verts := PackedVector3Array()
	var vcols := PackedColorArray()
	var segs := layout.segments
	verts.resize(segs * segs * TRIANGLE_CORNERS.size())
	vcols.resize(verts.size())
	var k := 0
	for iy in segs:
		for ix in segs:
			for o in TRIANGLE_CORNERS:
				var idx := (iy + o.y) * n + ix + o.x
				verts[k] = Vector3(layout.corner(ix + o.x), layout.heights[idx], layout.corner(iy + o.y))
				vcols[k] = colors[idx]
				k += 1

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_COLOR] = vcols
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var mi := MeshInstance3D.new()
	mi.name = "Terrain"
	mi.mesh = mesh
	mi.material_override = MeshKit.material(Color.WHITE)
	add_child(mi)


## The terrain colour settings, read once: numbers as floats, colours in linear space.
func _terrain_palette() -> Dictionary:
	var pal: Dictionary = (Tuning.value("terrain_colors") as Dictionary).duplicate()
	for key: String in pal:
		if pal[key] is String:
			pal[key] = Color.html(pal[key]).srgb_to_linear()
		else:
			pal[key] = float(pal[key])
	return pal


## The pilot's vertex colours: sand, grass, rock and peak by height and slope, dirt around villages.
func _terrain_color(i: int, j: int, pal: Dictionary) -> Color:
	var x := layout.corner(i)
	var z := layout.corner(j)
	var y := layout.heights[j * layout.verts_per_side + i]
	var probe: float = pal["slope_probe_m"]
	var slope := absf(layout.height_at(x + probe, z) - layout.height_at(x - probe, z)) \
		+ absf(layout.height_at(x, z + probe) - layout.height_at(x, z - probe))
	var noise_scale: float = pal["grass_noise_scale"]
	var noise := PilotNoise.fbm(x * noise_scale, z * noise_scale) * 0.5 + 0.5

	var c: Color
	if y < pal["wet_below_m"]:
		c = pal["sand_wet"]
	elif y < pal["sand_below_m"]:
		c = pal["sand"]
	else:
		var dark := clampf(noise * pal["grass_noise_gain"] + (y - pal["grass_dark_from_m"]) * pal["grass_dark_per_m"], 0.0, 1.0)
		c = (pal["grass_light"] as Color).lerp(pal["grass_dark"], dark)
		var rock_slope: float = pal["rock_slope"]
		var rock_above: float = pal["rock_above_m"]
		if slope > rock_slope or y > rock_above:
			var r := clampf((slope - rock_slope) * pal["rock_per_slope"] + (y - rock_above) * pal["rock_per_m"], 0.0, 1.0)
			c = c.lerp(pal["rock"], r)
		var peak_above: float = pal["peak_above_m"]
		if y > peak_above:
			c = c.lerp(pal["peak"], clampf((y - peak_above) * pal["peak_per_m"], 0.0, pal["peak_max"]))

	for v: Dictionary in layout.villages():
		var reach: float = float(v["radius_m"]) * pal["village_dirt_fraction"]
		var dv := Vector2(x - float(v["x"]), z - float(v["z"])).length()
		if dv < reach:
			c = c.lerp(pal["dirt"], (1.0 - dv / reach) * pal["village_dirt_strength"])
	var circle: Dictionary = layout.data["stone_circle"]
	var circle_reach: float = pal["circle_dirt_radius_m"]
	var dc := Vector2(x - float(circle["x"]), z - float(circle["z"])).length()
	if dc < circle_reach:
		c = c.lerp(pal["dirt"], (1.0 - dc / circle_reach) * pal["circle_dirt_strength"])

	var jitter: float = 1.0 + (PilotNoise.hash2(i, j) - 0.5) * pal["jitter"]
	return Color(c.r * jitter, c.g * jitter, c.b * jitter)


func _build_sea() -> void:
	var size := Tuning.num("sea.size_m")
	var plane := PlaneMesh.new()
	plane.size = Vector2(size, size)
	var subdivisions := int(Tuning.num("sea.subdivisions"))
	plane.subdivide_width = subdivisions - 1
	plane.subdivide_depth = subdivisions - 1
	var m := ShaderMaterial.new()
	m.shader = preload("res://world/sea.gdshader")
	m.set_shader_parameter("color", Tuning.color("sea.color"))
	m.set_shader_parameter("seabed", Tuning.color("sea.seabed"))
	m.set_shader_parameter("seabed_mix", Tuning.num("sea.seabed_mix"))
	m.set_shader_parameter("roughness", Tuning.num("sea.roughness"))
	for axis in ["x", "z"]:
		var key := "sea.swell_%s." % axis
		m.set_shader_parameter("swell_" + axis, Vector3(Tuning.num(key + "amplitude_m"), Tuning.num(key + "frequency"), Tuning.num(key + "speed")))
	m.set_shader_parameter("offset", Tuning.num("sea.offset_m"))
	var mi := MeshInstance3D.new()
	mi.name = "Sea"
	mi.mesh = plane
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)


func _build_trees() -> void:
	var trees: Array = layout.data["trees"]
	var trunk_mesh := MeshKit.moved(MeshKit.cylinder(0.22, 0.34, 2.2, 6), Transform3D(Basis(), Vector3(0, 1.1, 0)))
	var pine_mesh := MeshKit.moved(MeshKit.cone(1.5, 3.8, 7), Transform3D(Basis(), Vector3(0, 3.6, 0)))
	var oak_mesh := MeshKit.moved(MeshKit.icosahedron(1.75), Transform3D(Basis(), Vector3(0, 3.4, 0)))
	var pines: Array[Transform3D] = []
	var oaks: Array[Transform3D] = []
	var pine_tints: Array[Color] = []
	var oak_tints: Array[Color] = []
	var trunks: Array[Transform3D] = []
	var tint_range: Array = Tuning.value("objects.tree_tint_range")
	var sink := Tuning.num("objects.tree_sink_m")
	for i in trees.size():
		var t: Array = trees[i]
		var x: float = t[0]
		var z: float = t[1]
		var scale_s: float = t[3]
		var xform := Transform3D(Basis(Vector3.UP, float(t[4])).scaled(Vector3.ONE * scale_s), Vector3(x, layout.height_at(x, z) - sink, z))
		trunks.append(xform)
		var tint := lerpf(tint_range[0], tint_range[1], PilotNoise.hash2(i, 7919))
		if int(t[2]) == 1:
			pines.append(xform)
			pine_tints.append(Tuning.color_linear("objects.tree_pine") * tint)
		else:
			oaks.append(xform)
			oak_tints.append(Tuning.color_linear("objects.tree_oak") * tint)
	_add_multimesh("Trunks", trunk_mesh, trunks, [], Tuning.color("objects.trunk"))
	_add_multimesh("Pines", pine_mesh, pines, pine_tints, Color.WHITE)
	_add_multimesh("Oaks", oak_mesh, oaks, oak_tints, Color.WHITE)


func _build_rocks() -> void:
	var rocks: Array = layout.data["rocks"]
	var mesh := MeshKit.icosahedron(1.0)
	var xforms: Array[Transform3D] = []
	var lift := Tuning.num("objects.rock_lift_per_size")
	var squash_xz: Array = Tuning.value("objects.rock_squash_xz")
	var squash_y: Array = Tuning.value("objects.rock_squash_y")
	for i in rocks.size():
		var r: Array = rocks[i]
		var x: float = r[0]
		var z: float = r[1]
		var size: float = r[2]
		# Squash each rock a little differently so they don't look stamped out.
		var squash := Vector3(
			lerpf(squash_xz[0], squash_xz[1], PilotNoise.hash2(i, 1)),
			lerpf(squash_y[0], squash_y[1], PilotNoise.hash2(i, 2)),
			lerpf(squash_xz[0], squash_xz[1], PilotNoise.hash2(i, 3)))
		var rock_basis := Basis(Vector3.UP, float(r[3])).scaled(squash * size)
		xforms.append(Transform3D(rock_basis, Vector3(x, layout.height_at(x, z) + size * lift, z)))
	_add_multimesh("Rocks", mesh, xforms, [], Tuning.color("objects.rock"))


func _add_multimesh(node_name: String, mesh: Mesh, xforms: Array[Transform3D], tints: Array[Color], color: Color) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = not tints.is_empty()
	mm.mesh = mesh
	mm.instance_count = xforms.size()
	for i in xforms.size():
		mm.set_instance_transform(i, xforms[i])
		if mm.use_colors:
			mm.set_instance_color(i, tints[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.name = node_name
	mmi.multimesh = mm
	mmi.material_override = MeshKit.material(color)
	add_child(mmi)


func _build_clouds() -> void:
	var flatten := Tuning.num("clouds.flatten")
	var mat := MeshKit.material(Tuning.color("clouds.color"))
	for c: Dictionary in layout.data["clouds"]:
		var cloud := Node3D.new()
		cloud.position = Vector3(c["x"], c["y"], c["z"])
		for b: Array in c["blobs"]:
			var mi := MeshInstance3D.new()
			mi.mesh = MeshKit.icosahedron(b[3])
			mi.material_override = mat
			mi.position = Vector3(b[0], b[1], b[2])
			mi.scale.y = flatten
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			cloud.add_child(mi)
		add_child(cloud)
		_clouds.append(cloud)
		_cloud_speeds.append(c["speed"])


## A village as it stands at the start: totem and flag, houses on their ring of slots,
## the storehouse with its piles, and the ring of influence motes.
func _build_village(v: Dictionary) -> void:
	var o := "objects."
	var vx: float = v["x"]
	var vz: float = v["z"]
	var radius: float = v["radius_m"]
	var owned: bool = v["owned"]
	var ring_angle: float = v["ring_angle"]
	var centre := Vector3(vx, layout.ground_at(vx, vz), vz)
	var root := Node3D.new()
	root.name = str(v["name"])
	add_child(root)

	# Totem with three bands, a glowing gem and a flag.
	var totem := Node3D.new()
	totem.position = centre
	root.add_child(totem)
	MeshKit.part(totem, MeshKit.cylinder(0.55, 0.7, 5.4, 8), Tuning.color(o + "totem"), Vector3(0, 2.7, 0))
	for q in 3:
		MeshKit.part(totem, MeshKit.torus(0.66, 0.14), Tuning.color(o + "band"), Vector3(0, 1.2 + q * 1.5, 0))
	MeshKit.part(totem, MeshKit.octahedron(0.75), Tuning.color(o + "grain"), Vector3(0, 6, 0), 0.0, Tuning.color(o + "grain_glow"), 1.0)
	MeshKit.part(totem, MeshKit.cylinder(0.07, 0.07, 5, 5), Tuning.color(o + "door"), Vector3(1.3, 4.4, 0))
	MeshKit.part(totem, MeshKit.box(Vector3(1.9, 1.2, 0.04)), Tuning.color(o + ("flag_owned" if owned else "flag_neutral")), Vector3(2.25, 6.2, 0))

	# Houses on a ring of slots, doors facing the centre.
	var slots := int(Tuning.num("villages.house_slots"))
	var ring_r := radius * Tuning.num("villages.house_ring_fraction_of_radius")
	for k in int(v["houses"]):
		var a := ring_angle + k / float(slots) * TAU
		var pos := centre + Vector3(cos(a), 0, sin(a)) * ring_r
		pos.y = layout.ground_at(pos.x, pos.z)
		_build_house(root, pos, centre)

	# Storehouse: a shed with food and wood piles out front, facing away from the centre.
	var sa := ring_angle + PI / 8.0
	var sp := centre + Vector3(cos(sa), 0, sin(sa)) * Tuning.num("villages.store_offset_m")
	sp.y = layout.ground_at(sp.x, sp.z)
	var store := Node3D.new()
	store.position = sp
	store.basis = Basis.looking_at(Vector3(sp.x - centre.x, 0, sp.z - centre.z), Vector3.UP, true)
	root.add_child(store)
	MeshKit.part(store, MeshKit.box(Vector3(4.2, 2, 3)), Tuning.color(o + "store"), Vector3(0, 1, -0.8))
	MeshKit.part(store, MeshKit.cone(3.4, 1.8, 4), Tuning.color(o + "roof"), Vector3(0, 2.9, -0.8), PI / 4.0)
	var grains := clampi(ceili(float(v["food"]) / Tuning.num("villages.food_per_grain")), 0, 8)
	for q in grains:
		MeshKit.part(store, MeshKit.icosahedron(0.42), Tuning.color(o + "grain"), Vector3(-1.2 + (q % 4) * 0.55, 0.4 + floori(q / 4.0) * 0.5, 1.2 + (q % 2) * 0.3), 0.0, Tuning.color(o + "grain_glow"), 1.0)
	var logs := clampi(ceili(float(v["wood"]) / Tuning.num("villages.wood_per_log")), 0, 6)
	for q in logs:
		var log_mi := MeshKit.part(store, MeshKit.cylinder(0.22, 0.22, 1.8, 6), Tuning.color(o + "log"), Vector3(1.3, 0.25 + floori(q / 3.0) * 0.42, 0.9 + (q % 3) * 0.45))
		log_mi.rotation.z = PI / 2.0

	# Influence motes in a wavy ring around the village.
	var count := int(Tuning.num("villages.mote_count"))
	var mote_r := radius + Tuning.num("villages.mote_ring_pad_m")
	var xforms: Array[Transform3D] = []
	for q in count:
		var a := q / float(count) * TAU
		var r := mote_r + sin(a * 5.0) * 1.2
		var mx := vx + cos(a) * r
		var mz := vz + sin(a) * r
		xforms.append(Transform3D(Basis(), Vector3(mx, layout.ground_at(mx, mz) + 0.45, mz)))
	var mote := SphereMesh.new()
	mote.radius = 0.28
	mote.height = 0.56
	mote.radial_segments = 6
	mote.rings = 3
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mote
	mm.instance_count = xforms.size()
	for i in xforms.size():
		mm.set_instance_transform(i, xforms[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = MeshKit.glow_material(Tuning.color(o + ("motes_owned" if owned else "motes_neutral")), 0.85)
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(mmi)


## A hamlet hut (the pilot's makeHouse at tier 0).
func _build_house(parent: Node3D, pos: Vector3, centre: Vector3) -> void:
	var o := "objects."
	var house := Node3D.new()
	house.position = pos
	house.basis = Basis.looking_at(Vector3(centre.x - pos.x, 0, centre.z - pos.z), Vector3.UP, true)
	parent.add_child(house)
	MeshKit.part(house, MeshKit.box(Vector3(3.2, 2.5, 3.2)), Tuning.color(o + "wall"), Vector3(0, 1.25, 0))
	MeshKit.part(house, MeshKit.cone(2.75, 2.2, 4), Tuning.color(o + "roof"), Vector3(0, 3.6, 0), PI / 4.0)
	MeshKit.part(house, MeshKit.box(Vector3(0.9, 1.5, 0.2)), Tuning.color(o + "door"), Vector3(0, 0.75, 1.6))


func _build_stone_circle() -> void:
	var c: Dictionary = layout.data["stone_circle"]
	var cx: float = c["x"]
	var cz: float = c["z"]
	var ring: float = c["stone_ring_m"]
	var stones := int(c["stones"])
	var root := Node3D.new()
	root.name = "StoneCircle"
	root.position = Vector3(cx, layout.ground_at(cx, cz), cz)
	add_child(root)
	var stone_color := Tuning.color("objects.stone")
	for k in stones:
		var a := k / float(stones) * TAU
		MeshKit.part(root, MeshKit.box(Vector3(1, 3 + (k % 3) * 0.5, 0.7)), stone_color, Vector3(cos(a) * ring, 1.5, sin(a) * ring), -a)
	MeshKit.part(root, MeshKit.cylinder(1.4, 1.7, 0.9, 8), stone_color, Vector3(0, 0.45, 0))

	# The prayer pillar: its height follows prayer power (fixed at the starting power for now).
	var power := Tuning.num("prayer.start_power")
	var height := Tuning.num("prayer.pillar_base_m") + power * Tuning.num("prayer.pillar_per_power_m")
	var pillar_mesh := MeshKit.cylinder(0.9, 1.2, height, 18)
	pillar_mesh.cap_top = false
	pillar_mesh.cap_bottom = false
	var pillar := MeshInstance3D.new()
	pillar.mesh = pillar_mesh
	pillar.position.y = height / 2.0
	pillar.material_override = MeshKit.glow_material(Tuning.color("objects.pillar"), 0.18 + power / Tuning.num("prayer.max_power") * 0.3)
	pillar.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(pillar)


func _build_fields() -> void:
	var stalk := MeshKit.moved(MeshKit.box(Vector3(0.5, 1.1, 0.5)), Transform3D(Basis(), Vector3(0, 0.55, 0)))
	for f: Dictionary in layout.data["fields"]:
		var fx: float = f["x"]
		var fz: float = f["z"]
		var w: float = f["w"]
		var d: float = f["d"]
		var y := layout.ground_at(fx, fz) + 0.06
		MeshKit.part(self, MeshKit.box(Vector3(w, 0.04, d)), Tuning.color("objects.field"), Vector3(fx, y - 0.02, fz))
		var xforms: Array[Transform3D] = []
		for a in floori(w / 1.1):
			for b in floori(d / 1.4):
				xforms.append(Transform3D(Basis(), Vector3(fx - w / 2.0 + 0.55 + a * 1.1, y, fz - d / 2.0 + 0.7 + b * 1.4)))
		_add_multimesh("Wheat", stalk, xforms, [], Tuning.color("objects.stalk"))
