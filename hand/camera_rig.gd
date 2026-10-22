class_name CameraRig
extends Node3D
## The god's view: an orbit camera around a target on the ground (pilot: "Camera controller").
## Pulling the land is 1:1 (the grabbed point stays under the cursor) and glides on when let go;
## every other move eases along openblack's ZoomInterpolator curve so nothing snaps.
##
## Mouse: left-drag pulls the land, right- or middle-drag rotates and tilts, the wheel zooms toward
## the cursor, double-click flies there. Trackpad: two-finger scroll slides the map (with Option it
## rotates and tilts), pinch zooms toward the fingers. Keys come from data/controls.json.

enum Mode { NONE, PAN, ROTATE }

var layout: IslandLayout
var camera: Camera3D

var _yaw: EasedValue
var _pitch: EasedValue
var _dist: EasedValue
var _tx: EasedValue
var _tz: EasedValue
var _ty := 0.0
var _fling := Vector2.ZERO
var _mode := Mode.NONE
var _grab := Vector3.ZERO
var _moved_px := 0.0
## Recent target positions while pulling the land: Vector3(time_s, x, z), for the fling.
var _history: Array[Vector3] = []
## While a zoom eases, this world point is held under this screen point.
var _zoom_anchor: Variant = null
var _zoom_anchor_screen := Vector2.ZERO


func _ready() -> void:
	camera = Camera3D.new()
	camera.fov = Tuning.num("camera.fov_deg")
	camera.near = Tuning.num("camera.near_m")
	camera.far = Tuning.num("camera.far_m")
	add_child(camera)
	_yaw = EasedValue.new(0.0)
	_pitch = EasedValue.new(0.0)
	_dist = EasedValue.new(0.0)
	_tx = EasedValue.new(0.0)
	_tz = EasedValue.new(0.0)
	var start: Dictionary = Tuning.value("camera.start")
	set_pose(start["x"], start["z"], start["yaw"], start["pitch"], start["distance"])


## Jumps straight to a view (used at start and for screenshots).
func set_pose(x: float, z: float, yaw: float, pitch: float, distance: float) -> void:
	var target := _clamp_target(Vector2(x, z))
	_tx.snap(target.x)
	_tz.snap(target.y)
	_yaw.snap(yaw)
	_pitch.snap(_clamp_pitch(pitch))
	_dist.snap(_clamp_dist(distance))
	_ty = layout.ground_at(target.x, target.y)
	_fling = Vector2.ZERO
	_zoom_anchor = null
	_apply()


func fly_to(x: float, z: float) -> void:
	var duration := Tuning.num("camera.fly_to_s")
	var goal := _clamp_target(Vector2(x, z))
	_fling = Vector2.ZERO
	_zoom_anchor = null
	_tx.ease_to(goal.x, duration)
	_tz.ease_to(goal.y, duration)
	_dist.ease_to(_clamp_dist(_dist.goal * Tuning.num("camera.fly_to_zoom_factor")), duration)


func fly_home() -> void:
	for v: Dictionary in layout.villages():
		if v["owned"]:
			fly_to(v["x"], v["z"])
			return


## Current view as [x, z, yaw, pitch, distance], for the debug overlay.
func pose() -> Array[float]:
	return [_tx.value, _tz.value, _yaw.value, _pitch.value, _dist.value]


func _process(delta: float) -> void:
	_handle_keys(delta)
	if _mode != Mode.PAN and not _tx.is_moving() and _fling != Vector2.ZERO:
		_set_target(Vector2(_tx.value, _tz.value) + _fling * delta)
		_fling *= exp(-Tuning.num("camera.fling_decay_per_s") * delta)
		if _fling.length() < 0.05:
			_fling = Vector2.ZERO
	for v in [_yaw, _pitch, _dist, _tx, _tz]:
		(v as EasedValue).advance(delta)
	var follow := 1.0 - exp(-Tuning.num("camera.target_follow_ground_rate") * delta)
	_ty = lerpf(_ty, layout.ground_at(_tx.value, _tz.value), follow)
	_apply()
	if _zoom_anchor != null:
		_anchor_under(_zoom_anchor, _zoom_anchor_screen)
		if not _dist.is_moving():
			_zoom_anchor = null


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("camera_home"):
		fly_home()
	elif event is InputEventMouseButton:
		_on_mouse_button(event)
	elif event is InputEventMouseMotion:
		_on_mouse_motion(event)
	elif event is InputEventPanGesture:
		_on_pan_gesture(event)
	elif event is InputEventMagnifyGesture:
		var magnify := event as InputEventMagnifyGesture
		_zoom_at(magnify.position, pow(magnify.factor, -Tuning.num("camera.pinch_zoom_strength")))


func _on_mouse_button(e: InputEventMouseButton) -> void:
	match e.button_index:
		MOUSE_BUTTON_LEFT:
			if e.pressed and e.double_click:
				_mode = Mode.NONE
				var hit: Variant = _ground_under(e.position)
				if hit != null:
					fly_to((hit as Vector3).x, (hit as Vector3).z)
			elif e.pressed:
				_start_pan(e.position)
			elif _mode == Mode.PAN:
				_end_pan()
		MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE:
			if e.pressed:
				_mode = Mode.ROTATE
			elif _mode == Mode.ROTATE:
				_mode = Mode.NONE
		MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN:
			if e.pressed:
				var notches := e.factor if e.factor > 0.0 else 1.0
				var direction := -1.0 if e.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0
				_zoom_at(e.position, exp(direction * notches * Tuning.num("camera.wheel_zoom_per_notch")))


func _on_mouse_motion(e: InputEventMouseMotion) -> void:
	match _mode:
		Mode.PAN:
			_moved_px += e.relative.length()
			var hit: Variant = _ray_plane(e.position, _grab.y)
			if hit == null:
				return
			var delta := Vector2(_grab.x - (hit as Vector3).x, _grab.z - (hit as Vector3).z)
			var cap := _dist.value * Tuning.num("camera.pan_drag_cap_per_distance")
			if delta.length() > cap:
				delta = delta.normalized() * cap
			_set_target(Vector2(_tx.value, _tz.value) + delta)
			_apply()
			_record_history()
		Mode.ROTATE:
			_rotate_by(-e.relative.x * Tuning.num("camera.rotate_rad_per_px"), e.relative.y * Tuning.num("camera.tilt_rad_per_px"))


## Two-finger scroll on a trackpad: slide the map, or rotate and tilt with Option held.
func _on_pan_gesture(e: InputEventPanGesture) -> void:
	if e.alt_pressed:
		_rotate_by(e.delta.x * Tuning.num("camera.trackpad_rotate_rad_per_unit"), -e.delta.y * Tuning.num("camera.trackpad_tilt_rad_per_unit"))
		return
	var k := Tuning.num("camera.trackpad_pan_per_distance") * _dist.value
	_move_relative(e.delta.x * k, e.delta.y * k)


func _start_pan(screen: Vector2) -> void:
	_mode = Mode.PAN
	var hit: Variant = _ground_under(screen)
	if hit == null:
		hit = _ray_plane(screen, 0.0)
	if hit == null:
		_mode = Mode.NONE
		return
	_grab = hit
	_moved_px = 0.0
	_fling = Vector2.ZERO
	_zoom_anchor = null
	_tx.snap(_tx.value)
	_tz.snap(_tz.value)
	_history.clear()
	_record_history()


func _end_pan() -> void:
	_mode = Mode.NONE
	_fling = Vector2.ZERO
	if _moved_px < Tuning.num("camera.click_max_move_px") or _history.size() < 2:
		return
	var first := _history[0]
	var last := _history[-1]
	var dt := maxf(0.016, last.x - first.x)
	_fling = Vector2(last.y - first.y, last.z - first.z) / dt
	_fling = _fling.limit_length(Tuning.num("camera.fling_max_m_s"))


func _record_history() -> void:
	var now := Time.get_ticks_msec() / 1000.0
	_history.append(Vector3(now, _tx.value, _tz.value))
	var window := Tuning.num("camera.fling_window_s")
	while _history.size() > 2 and now - _history[0].x > window:
		_history.pop_front()


func _handle_keys(delta: float) -> void:
	var right := Input.get_axis("camera_left", "camera_right")
	var back := Input.get_axis("camera_forward", "camera_back")
	if right != 0.0 or back != 0.0:
		var step := _dist.value * Tuning.num("camera.key_move_per_distance_s") * delta
		_move_relative(right * step, back * step)
	var turn := Input.get_axis("camera_rotate_right", "camera_rotate_left")
	if turn != 0.0:
		_rotate_by(turn * Tuning.num("camera.key_rotate_rad_s") * delta, 0.0)
	var zoom := Input.get_axis("camera_zoom_in", "camera_zoom_out")
	if zoom != 0.0:
		var ease_s := Tuning.num("camera.ease_s")
		_dist.ease_to(_clamp_dist(_dist.goal * (1.0 + zoom * Tuning.num("camera.key_zoom_rate_s") * delta)), ease_s)


## Moves the target across the ground in the camera's frame (right, toward the camera).
func _move_relative(right: float, back: float) -> void:
	var c := cos(_yaw.value)
	var s := sin(_yaw.value)
	_fling = Vector2.ZERO
	_set_target(Vector2(_tx.value + right * c + back * s, _tz.value - right * s + back * c))


func _rotate_by(yaw: float, pitch: float) -> void:
	var ease_s := Tuning.num("camera.ease_s")
	_yaw.ease_to(_yaw.goal + yaw, ease_s)
	_pitch.ease_to(_clamp_pitch(_pitch.goal + pitch), ease_s)


## Zooms by a factor (below 1 is closer), keeping the ground under the screen point where it is.
func _zoom_at(screen: Vector2, factor: float) -> void:
	var anchor: Variant = _ground_under(screen)
	if anchor == null:
		anchor = _ray_plane(screen, _ty)
	_zoom_anchor = anchor
	_zoom_anchor_screen = screen
	_dist.ease_to(_clamp_dist(_dist.goal * factor), Tuning.num("camera.ease_s"))


func _anchor_under(world: Vector3, screen: Vector2) -> void:
	var hit: Variant = _ray_plane(screen, world.y)
	if hit == null:
		return
	var h := hit as Vector3
	_set_target(Vector2(_tx.value + world.x - h.x, _tz.value + world.z - h.z))
	_apply()


func _set_target(p: Vector2) -> void:
	var clamped := _clamp_target(p)
	if clamped != p:
		_fling = Vector2.ZERO
	_tx.snap(clamped.x)
	_tz.snap(clamped.y)


func _apply() -> void:
	var yaw := _yaw.value
	var pitch := _pitch.value
	var dist := _dist.value
	var target := Vector3(_tx.value, _ty, _tz.value)
	var pos := target + Vector3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch)) * dist
	pos.y = maxf(pos.y, layout.ground_at(pos.x, pos.z) + Tuning.num("camera.min_height_above_ground_m"))
	camera.look_at_from_position(pos, target)


func _ground_under(screen: Vector2) -> Variant:
	return layout.ray_to_ground(camera.project_ray_origin(screen), camera.project_ray_normal(screen))


func _ray_plane(screen: Vector2, plane_y: float) -> Variant:
	var origin := camera.project_ray_origin(screen)
	var dir := camera.project_ray_normal(screen)
	if absf(dir.y) < 1e-4:
		return null
	var t := (plane_y - origin.y) / dir.y
	if t < 0.0:
		return null
	return origin + dir * t


func _clamp_target(p: Vector2) -> Vector2:
	return p.limit_length(Tuning.num("camera.target_radius_from_centre_m"))


func _clamp_pitch(pitch: float) -> float:
	return clampf(pitch, Tuning.num("camera.pitch_min"), Tuning.num("camera.pitch_max"))


func _clamp_dist(dist: float) -> float:
	return clampf(dist, Tuning.num("camera.distance_min"), Tuning.num("camera.distance_max"))
