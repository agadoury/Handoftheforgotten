extends TestCase
## The camera rig's controls, driven with synthetic input events in a 1280x720 viewport.

const STEP := 1.0 / 60.0


func _make_rig() -> CameraRig:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1280, 720)
	add_to_tree(viewport)
	var rig := CameraRig.new()
	rig.layout = IslandLayout.from_file("res://data/island.json")
	viewport.add_child(rig)
	return rig


func _run(rig: CameraRig, seconds: float) -> void:
	for _i in ceili(seconds / STEP):
		rig._process(STEP)


func _press(rig: CameraRig, button: MouseButton, at: Vector2, pressed: bool, double: bool = false) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = button
	e.position = at
	e.pressed = pressed
	e.double_click = double
	rig._unhandled_input(e)


func _move(rig: CameraRig, from: Vector2, to: Vector2) -> void:
	var e := InputEventMouseMotion.new()
	e.position = to
	e.relative = to - from
	rig._unhandled_input(e)


func test_dragging_keeps_the_grabbed_ground_under_the_cursor() -> void:
	var rig := _make_rig()
	var start := Vector2(640, 420)
	var grabbed: Vector3 = rig._ground_under(start)
	_press(rig, MOUSE_BUTTON_LEFT, start, true)
	var at := start
	for k in 10:
		var next := start + Vector2(-25, 12) * (k + 1)
		_move(rig, at, next)
		at = next
	var under: Vector3 = rig._ray_plane(at, grabbed.y)
	assert_almost_eq(under.x, grabbed.x, 0.01, "grabbed point x")
	assert_almost_eq(under.z, grabbed.z, 0.01, "grabbed point z")


func test_letting_go_while_moving_flings_the_land() -> void:
	var rig := _make_rig()
	var at := Vector2(640, 420)
	_press(rig, MOUSE_BUTTON_LEFT, at, true)
	for k in 6:
		var next := at + Vector2(-30, 0)
		_move(rig, at, next)
		at = next
	_press(rig, MOUSE_BUTTON_LEFT, at, false)
	var before: Array[float] = rig.pose()
	_run(rig, 0.25)
	var after: Array[float] = rig.pose()
	var glide := Vector2(after[0] - before[0], after[1] - before[1]).length()
	assert_true(glide > 1.0, "the land keeps gliding after release (moved %.2f m)" % glide)


func test_a_click_without_moving_does_not_fling() -> void:
	var rig := _make_rig()
	var at := Vector2(640, 420)
	_press(rig, MOUSE_BUTTON_LEFT, at, true)
	_move(rig, at, at + Vector2(2, 1))
	_press(rig, MOUSE_BUTTON_LEFT, at + Vector2(2, 1), false)
	var before: Array[float] = rig.pose()
	_run(rig, 0.5)
	var after: Array[float] = rig.pose()
	assert_almost_eq(after[0], before[0], 1e-6, "target x unchanged")
	assert_almost_eq(after[1], before[1], 1e-6, "target z unchanged")


func test_wheel_zoom_keeps_the_ground_under_the_cursor() -> void:
	var rig := _make_rig()
	var cursor := Vector2(900, 300)
	var anchor: Vector3 = rig._ground_under(cursor)
	var dist_before: float = rig.pose()[4]
	for _i in 3:
		_press(rig, MOUSE_BUTTON_WHEEL_UP, cursor, true)
	_run(rig, 1.0)
	assert_true(rig.pose()[4] < dist_before * 0.8, "zoomed in")
	var under: Vector3 = rig._ray_plane(cursor, anchor.y)
	assert_almost_eq(under.x, anchor.x, 0.05, "anchor x")
	assert_almost_eq(under.z, anchor.z, 0.05, "anchor z")


func test_double_click_flies_to_the_ground_there() -> void:
	var rig := _make_rig()
	var at := Vector2(300, 500)
	var target: Vector3 = rig._ground_under(at)
	_press(rig, MOUSE_BUTTON_LEFT, at, true, true)
	_run(rig, Tuning.num("camera.fly_to_s") + 0.1)
	var p := rig.pose()
	assert_almost_eq(p[0], target.x, 0.01, "arrived x")
	assert_almost_eq(p[1], target.z, 0.01, "arrived z")


func test_right_drag_rotates_and_tilts_within_limits() -> void:
	var rig := _make_rig()
	var before := rig.pose()
	_press(rig, MOUSE_BUTTON_RIGHT, Vector2(640, 360), true)
	_move(rig, Vector2(640, 360), Vector2(740, 2000))
	_press(rig, MOUSE_BUTTON_RIGHT, Vector2(740, 2000), false)
	_run(rig, 1.0)
	var after := rig.pose()
	assert_almost_eq(after[2], before[2] - 100 * Tuning.num("camera.rotate_rad_per_px"), 1e-4, "yaw")
	assert_almost_eq(after[3], Tuning.num("camera.pitch_max"), 1e-4, "pitch stops at its limit")


func test_limits_hold() -> void:
	var rig := _make_rig()
	rig.set_pose(500, 0, 0, 3, 1000)
	var p := rig.pose()
	assert_almost_eq(Vector2(p[0], p[1]).length(), Tuning.num("camera.target_radius_from_centre_m"), 1e-3, "target radius")
	assert_almost_eq(p[3], Tuning.num("camera.pitch_max"), 1e-6, "pitch")
	assert_almost_eq(p[4], Tuning.num("camera.distance_max"), 1e-6, "distance")
	rig.set_pose(0, -58, 0, 0, 0)
	var cam := rig.camera.global_position
	assert_true(cam.y >= rig.layout.ground_at(cam.x, cam.z) + Tuning.num("camera.min_height_above_ground_m") - 1e-3, "camera stays above the mountain")
