class_name MeshKit
## Low-poly placeholder meshes and the shared flat-shaded materials (docs/ART_DIRECTION.md).
## Colours are sRGB; materials convert them.

const FLAT_SHADER := preload("res://world/flat.gdshader")

static var _materials: Dictionary = {}


## The flat-shaded matte material for a colour, shared by everything of that colour.
static func material(color: Color, glow: Color = Color.BLACK, glow_energy: float = 0.0) -> ShaderMaterial:
	var key := "%s/%s/%s" % [color.to_html(), glow.to_html(), glow_energy]
	if _materials.has(key):
		return _materials[key]
	var m := ShaderMaterial.new()
	m.shader = FLAT_SHADER
	m.set_shader_parameter("albedo", color)
	m.set_shader_parameter("emission", glow)
	m.set_shader_parameter("emission_energy", glow_energy)
	_materials[key] = m
	return m


## Additive, unshaded glow (motes, the prayer pillar).
static func glow_material(color: Color, opacity: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.albedo_color = Color(color, opacity)
	return m


static func box(size: Vector3) -> BoxMesh:
	var m := BoxMesh.new()
	m.size = size
	return m


static func cylinder(top_radius: float, bottom_radius: float, height: float, segments: int) -> CylinderMesh:
	var m := CylinderMesh.new()
	m.top_radius = top_radius
	m.bottom_radius = bottom_radius
	m.height = height
	m.radial_segments = segments
	m.rings = 0
	return m


static func cone(radius: float, height: float, segments: int) -> CylinderMesh:
	return cylinder(0.0, radius, height, segments)


static func torus(radius: float, tube: float) -> TorusMesh:
	var m := TorusMesh.new()
	m.inner_radius = radius - tube
	m.outer_radius = radius + tube
	m.rings = 10
	m.ring_segments = 6
	return m


static func icosahedron(radius: float) -> ArrayMesh:
	var t := (1.0 + sqrt(5.0)) / 2.0
	var v: Array[Vector3] = [
		Vector3(-1, t, 0), Vector3(1, t, 0), Vector3(-1, -t, 0), Vector3(1, -t, 0),
		Vector3(0, -1, t), Vector3(0, 1, t), Vector3(0, -1, -t), Vector3(0, 1, -t),
		Vector3(t, 0, -1), Vector3(t, 0, 1), Vector3(-t, 0, -1), Vector3(-t, 0, 1),
	]
	var faces: Array[Vector3i] = [
		Vector3i(0, 11, 5), Vector3i(0, 5, 1), Vector3i(0, 1, 7), Vector3i(0, 7, 10), Vector3i(0, 10, 11),
		Vector3i(1, 5, 9), Vector3i(5, 11, 4), Vector3i(11, 10, 2), Vector3i(10, 7, 6), Vector3i(7, 1, 8),
		Vector3i(3, 9, 4), Vector3i(3, 4, 2), Vector3i(3, 2, 6), Vector3i(3, 6, 8), Vector3i(3, 8, 9),
		Vector3i(4, 9, 5), Vector3i(2, 4, 11), Vector3i(6, 2, 10), Vector3i(8, 6, 7), Vector3i(9, 8, 1),
	]
	for i in v.size():
		v[i] = v[i].normalized() * radius
	return _from_faces(v, faces)


static func octahedron(radius: float) -> ArrayMesh:
	var v: Array[Vector3] = [
		Vector3(radius, 0, 0), Vector3(-radius, 0, 0), Vector3(0, radius, 0),
		Vector3(0, -radius, 0), Vector3(0, 0, radius), Vector3(0, 0, -radius),
	]
	var faces: Array[Vector3i] = [
		Vector3i(0, 2, 4), Vector3i(0, 4, 3), Vector3i(0, 3, 5), Vector3i(0, 5, 2),
		Vector3i(1, 2, 5), Vector3i(1, 5, 3), Vector3i(1, 3, 4), Vector3i(1, 4, 2),
	]
	return _from_faces(v, faces)


## A copy of a mesh with its vertices moved by a transform (to bake offsets into MultiMesh parts).
static func moved(mesh: Mesh, xform: Transform3D) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.append_from(mesh, 0, xform)
	return st.commit()


## Adds a mesh in a colour under a parent node.
static func part(parent: Node3D, mesh: Mesh, color: Color, position: Vector3, rotation_y: float = 0.0, glow: Color = Color.BLACK, glow_energy: float = 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = material(color, glow, glow_energy)
	mi.position = position
	mi.rotation.y = rotation_y
	parent.add_child(mi)
	return mi


## Faces are listed counter-clockwise seen from outside; Godot's front faces are clockwise.
static func _from_faces(v: Array[Vector3], faces: Array[Vector3i]) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for f in faces:
		st.add_vertex(v[f.x])
		st.add_vertex(v[f.z])
		st.add_vertex(v[f.y])
	st.generate_normals()
	return st.commit()
