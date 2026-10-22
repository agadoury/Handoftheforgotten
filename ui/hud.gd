class_name Hud
extends CanvasLayer
## The prototype's small HUD: a title tablet, the controls (toggle with ?), and a debug readout (F3).
## Colours follow docs/ART_DIRECTION.md via data/tuning.json "ui".

const HELP_TEXT := """Drag the ground to pull the land; let go while moving to fling it
Right-drag or middle-drag to rotate and tilt
Scroll to zoom toward the cursor · double-click to fly there
Trackpad: two-finger scroll slides, pinch zooms, Option + scroll rotates
Keys: WASD or arrows move · Q/E rotate · R/F zoom · H flies home
[ and ] preview the sky turning cruel or kind · ? hides this · F3 debug"""

var camera_rig: CameraRig
var world_look: WorldLook

var _help: PanelContainer
var _debug: Label


func _ready() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	var margin := int(Tuning.num("ui.margin_px"))

	var title := _panel(root)
	var title_label := _label(title, "Hand of the Forgotten  ·  prototype", Tuning.color("ui.gold_light"), int(Tuning.num("ui.title_size_px")))
	title_label.uppercase = true
	_pin(title, Control.PRESET_TOP_LEFT, margin)

	_help = _panel(root)
	_label(_help, HELP_TEXT, Tuning.color("ui.parchment"), int(Tuning.num("ui.font_size_px")))
	_pin(_help, Control.PRESET_BOTTOM_LEFT, margin)

	var debug_panel := _panel(root)
	_debug = _label(debug_panel, "", Tuning.color("ui.dim"), int(Tuning.num("ui.font_size_px")))
	_pin(debug_panel, Control.PRESET_TOP_RIGHT, margin)
	debug_panel.visible = false


func _process(_delta: float) -> void:
	var panel := _debug.get_parent() as Control
	if not panel.visible:
		return
	var p := camera_rig.pose()
	_debug.text = "%d fps\ntarget %.1f, %.1f\nyaw %.2f  pitch %.2f\ndistance %.1f m\nalignment %+.2f" % [
		Engine.get_frames_per_second(), p[0], p[1], p[2], p[3], p[4], world_look.alignment]


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_help"):
		_help.visible = not _help.visible
	elif event.is_action_pressed("toggle_debug"):
		set_debug_visible(not (_debug.get_parent() as Control).visible)


func set_help_visible(on: bool) -> void:
	_help.visible = on


func set_debug_visible(on: bool) -> void:
	(_debug.get_parent() as Control).visible = on


## Pins a panel to a corner of the screen, a margin in from the edges, growing away from the corner.
func _pin(panel: Control, corner: Control.LayoutPreset, margin: int) -> void:
	panel.set_anchors_and_offsets_preset(corner, Control.PRESET_MODE_MINSIZE, margin)
	var right := corner == Control.PRESET_TOP_RIGHT or corner == Control.PRESET_BOTTOM_RIGHT
	var bottom := corner == Control.PRESET_BOTTOM_LEFT or corner == Control.PRESET_BOTTOM_RIGHT
	panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN if right else Control.GROW_DIRECTION_END
	panel.grow_vertical = Control.GROW_DIRECTION_BEGIN if bottom else Control.GROW_DIRECTION_END


func _panel(parent: Control) -> PanelContainer:
	var style := StyleBoxFlat.new()
	style.bg_color = Tuning.color("ui.panel")
	style.border_color = Tuning.color("ui.line")
	style.set_border_width_all(1)
	style.set_corner_radius_all(int(Tuning.num("ui.corner_radius_px")))
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", style)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(panel)
	return panel


func _label(parent: Control, text: String, color: Color, size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", size)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label
