extends Node
## Loads every tunable from data/ and registers the key bindings.
## Read values with dotted paths: Tuning.num("camera.pitch_min").

const TUNING_PATH := "res://data/tuning.json"
const CONTROLS_PATH := "res://data/controls.json"

var data: Dictionary = {}


func _init() -> void:
	data = load_json(TUNING_PATH)
	_register_controls(load_json(CONTROLS_PATH))


func load_json(path: String) -> Dictionary:
	var text := FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(text)
	assert(parsed is Dictionary, "Could not read %s" % path)
	return parsed


func value(path: String) -> Variant:
	var node: Variant = data
	for key in path.split("."):
		assert(node is Dictionary and (node as Dictionary).has(key), "Missing tuning value: %s" % path)
		node = (node as Dictionary)[key]
	return node


func num(path: String) -> float:
	return float(value(path))


func color(path: String) -> Color:
	return Color.html(str(value(path)))


## The same colour converted to linear space, for vertex and instance colours.
func color_linear(path: String) -> Color:
	return color(path).srgb_to_linear()


func vec3(path: String) -> Vector3:
	var a: Array = value(path)
	return Vector3(a[0], a[1], a[2])


func _register_controls(controls: Dictionary) -> void:
	for action: String in controls:
		if action.begins_with("_"):
			continue
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for key_name: String in controls[action]:
			var keycode := OS.find_keycode_from_string(key_name)
			assert(keycode != KEY_NONE, "Unknown key name in controls.json: %s" % key_name)
			var event := InputEventKey.new()
			event.physical_keycode = keycode
			InputMap.action_add_event(action, event)
