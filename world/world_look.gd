class_name WorldLook
extends Node
## Sun, sky, ambient light and fog. They blend from the kind palette toward the cruel one as the
## player's alignment drops below zero (pilot: updateWorldLook). Alignment is -1 (cruel) to +1 (kind).

## The player's alignment. Nothing sets it yet except the debug keys.
var alignment := 0.0

var environment: Environment
var sun: DirectionalLight3D
var _sky_material: ShaderMaterial
var _shown_blend := -1.0


func _ready() -> void:
	_sky_material = ShaderMaterial.new()
	_sky_material.shader = preload("res://world/sky.gdshader")
	var sun_dir := Tuning.vec3("world_look.sun_direction").normalized()
	_sky_material.set_shader_parameter("sun_direction", sun_dir)
	_sky_material.set_shader_parameter("ambient_ground", Tuning.color("world_look.ambient_ground"))
	_sky_material.set_shader_parameter("exposure", Tuning.num("world_look.exposure"))
	_sky_material.set_shader_parameter("white", Tuning.num("world_look.tonemap_white"))
	set_ambient_energy(Tuning.num("world_look.ambient_energy"))

	var sky := Sky.new()
	sky.sky_material = _sky_material
	sky.radiance_size = Sky.RADIANCE_SIZE_64

	environment = Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	# The pilot's materials reflect only the sun, not the sky.
	environment.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	environment.tonemap_mode = Environment.TONE_MAPPER_ACES
	environment.tonemap_exposure = Tuning.num("world_look.exposure")
	environment.tonemap_white = Tuning.num("world_look.tonemap_white")
	environment.fog_enabled = true
	environment.fog_mode = Environment.FOG_MODE_DEPTH
	environment.fog_density = 1.0
	environment.fog_depth_begin = Tuning.num("world_look.fog_begin_m")
	environment.fog_depth_end = Tuning.num("world_look.fog_end_m")
	environment.fog_depth_curve = Tuning.num("world_look.fog_curve")
	environment.fog_sky_affect = 0.0
	environment.fog_sun_scatter = 0.0
	environment.fog_aerial_perspective = 0.0

	var world_env := WorldEnvironment.new()
	world_env.environment = environment
	add_child(world_env)

	sun = DirectionalLight3D.new()
	sun.name = "Sun"
	sun.basis = Basis.looking_at(-sun_dir, Vector3.UP)
	sun.light_energy = Tuning.num("world_look.sun_energy")
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = Tuning.num("world_look.shadow_distance_m")
	add_child(sun)
	_apply(0.0)


func _process(delta: float) -> void:
	var target := clampf(-alignment, 0.0, 1.0) * Tuning.num("world_look.cruel_blend_max")
	var blend := move_toward(_shown_blend, target, Tuning.num("world_look.blend_rate_per_s") * delta)
	if blend != _shown_blend:
		_apply(blend)


func _unhandled_input(event: InputEvent) -> void:
	var step := Tuning.num("world_look.preview_alignment_step")
	if event.is_action_pressed("align_kinder"):
		alignment = clampf(alignment + step, -1.0, 1.0)
	elif event.is_action_pressed("align_crueler"):
		alignment = clampf(alignment - step, -1.0, 1.0)


func set_ambient_energy(energy: float) -> void:
	_sky_material.set_shader_parameter("ambient_energy", energy)


## Shows the world at a blend of 0 (kind) to 1 (fully cruel) at once, for screenshots.
func show_alignment(value: float) -> void:
	alignment = value
	_apply(clampf(-alignment, 0.0, 1.0) * Tuning.num("world_look.cruel_blend_max"))


func _apply(blend: float) -> void:
	_shown_blend = blend
	_sky_material.set_shader_parameter("top_color", _display(_mix("sky_top", blend)))
	_sky_material.set_shader_parameter("horizon_color", _display(_mix("sky_horizon", blend)))
	_sky_material.set_shader_parameter("sun_color", _display(_mix("sun", blend)))
	_sky_material.set_shader_parameter("ambient_sky", _mix("ambient_sky", blend))
	environment.fog_light_color = _mix("sky_horizon", blend)
	sun.light_color = _mix("light", blend)


func _mix(key: String, blend: float) -> Color:
	return Tuning.color("world_look.kind." + key).lerp(Tuning.color("world_look.cruel." + key), blend)


## A colour as raw sRGB values, for shader uniforms that work in display colours.
static func _display(c: Color) -> Vector3:
	return Vector3(c.r, c.g, c.b)

