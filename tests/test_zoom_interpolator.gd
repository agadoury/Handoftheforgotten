extends TestCase
## openblack's interpolator test (reference: test/test_interpolator.cpp, ExpValues), plus the camera's use of it.

# Ported from openblack: test/test_interpolator.cpp (GPL v3). Built as ZoomInterpolator(0, 1, 0, 1):
# zero start velocity, end velocity 1.
const EXPECTED: Array[float] = [
	0.0, 0.0002970099, 0.0011761596, 0.0026198092, 0.0046105585, 0.007131247, 0.010164955, 0.013695003,
	0.01770495, 0.022178598, 0.027099982, 0.032453388, 0.038223337, 0.044394586, 0.050952133, 0.05788123,
	0.06516734, 0.07279619, 0.08075373, 0.08902619, 0.09759998, 0.10646179, 0.115598544, 0.12499741,
	0.13464576, 0.14453122, 0.15464173, 0.16496536, 0.1754905, 0.18620574, 0.19709992, 0.2081621,
	0.21938165, 0.23074806, 0.24225119, 0.2538811, 0.26562795, 0.2774824, 0.28943512, 0.3014772,
	0.31359977, 0.32579434, 0.33805263, 0.3503667, 0.3627286, 0.3751309, 0.3875662, 0.40002745,
	0.41250777, 0.42500058, 0.43749958, 0.44999853, 0.46249175, 0.47497338, 0.4874381, 0.4998808,
	0.51229644, 0.52468055, 0.53702843, 0.549336, 0.5615994, 0.57381487, 0.58597875, 0.59808797,
	0.6101395, 0.6221305, 0.6340587, 0.6459215, 0.65771705, 0.6694435, 0.6810993, 0.6926831,
	0.7041937, 0.71563053, 0.72699296, 0.73828053, 0.749493, 0.7606305, 0.7716938, 0.7826829,
	0.7935991, 0.80444336, 0.815217, 0.8259213, 0.83655834, 0.8471303, 0.8576393, 0.86808753,
	0.8784783, 0.88881457, 0.899099, 0.90933526, 0.91952777, 0.9296801, 0.93979585, 0.94988,
	0.95993733, 0.96997285, 0.97999096, 0.98999786, 0.9999989, 1.0,
]


func test_matches_openblack_expected_values() -> void:
	var curve := ZoomInterpolator.new(0.0, 1.0, 0.0, 1.0)
	for i in EXPECTED.size():
		var t := i / float(EXPECTED.size() - 1)
		assert_almost_eq(curve.position_at(t), EXPECTED[i], 1e-2, "position at t=%.3f" % t)


func test_matches_expected_values_exactly_at_their_sample_points() -> void:
	# The values are the curve at t = i / 100 (the last one repeats the end); openblack reads them
	# at i / 101, which is why its test needs a 1e-2 tolerance. They were computed in 32-bit floats.
	var curve := ZoomInterpolator.new(0.0, 1.0, 0.0, 1.0)
	for i in 101:
		assert_almost_eq(curve.position_at(i / 100.0), EXPECTED[i], 1e-5, "position at t=%.2f" % (i / 100.0))


func test_ends_hit_their_points_and_velocities() -> void:
	var curve := ZoomInterpolator.new(10.0, 50.0, 4.0, 0.0)
	assert_almost_eq(curve.position_at(0.0), 10.0, 1e-9, "start")
	assert_almost_eq(curve.position_at(1.0), 50.0, 1e-9, "end")
	assert_almost_eq(curve.velocity_at(0.0), 4.0, 1e-9, "start velocity")
	assert_almost_eq(curve.velocity_at(1.0), 0.0, 1e-9, "end velocity")


func test_same_start_and_end_does_not_divide_by_zero() -> void:
	var curve := ZoomInterpolator.new(3.0, 3.0, 1.0, 1.0)
	assert_almost_eq(curve.position_at(0.5), 3.0, 1e-9, "position")
	assert_almost_eq(curve.velocity_at(0.5), 0.0, 1e-9, "velocity")


func test_eased_value_reaches_goal_in_its_duration() -> void:
	var v := EasedValue.new(0.0)
	v.ease_to(10.0, 0.5)
	for _i in 4:
		v.advance(0.1)
	assert_true(v.value > 0.0 and v.value < 10.0, "still gliding after 0.4 s")
	v.advance(0.1)
	assert_almost_eq(v.value, 10.0, 1e-9, "arrived after 0.5 s")
	assert_true(not v.is_moving(), "stopped")


func test_retargeting_keeps_velocity_continuous() -> void:
	var v := EasedValue.new(0.0)
	v.ease_to(10.0, 0.5)
	v.advance(0.2)
	var before := v.velocity()
	v.ease_to(-5.0, 0.5)
	assert_almost_eq(v.velocity(), before, 1e-6, "velocity carried into the new curve")
