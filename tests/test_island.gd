extends TestCase
## The island's terrain must match the pilot's (samples taken from the running pilot).

const ISLAND_PATH := "res://data/island.json"
const FIXTURE_PATH := "res://tests/fixtures/pilot_heights.json"


func test_heights_match_the_pilot() -> void:
	var layout := IslandLayout.from_file(ISLAND_PATH)
	var fixture: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(FIXTURE_PATH))
	var samples: Array = fixture["samples"]
	assert_true(samples.size() == 400, "fixture has 400 samples")
	for s: Array in samples:
		assert_almost_eq(layout.height_at(s[0], s[1]), s[2], 1e-3, "height at (%.2f, %.2f)" % [s[0], s[1]])


func test_villages_sit_on_flat_dry_ground() -> void:
	var layout := IslandLayout.from_file(ISLAND_PATH)
	for v: Dictionary in layout.villages():
		var x: float = v["x"]
		var z: float = v["z"]
		var centre := layout.height_at(x, z)
		assert_true(centre > 1.0, "%s is above the sea" % v["name"])
		for k in 8:
			var a := k * TAU / 8.0
			var h := layout.height_at(x + cos(a) * 6.0, z + sin(a) * 6.0)
			assert_almost_eq(h, centre, 0.05, "%s is flat 6 m from its centre" % v["name"])


func test_ray_finds_the_ground() -> void:
	var layout := IslandLayout.from_file(ISLAND_PATH)
	var hit: Variant = layout.ray_to_ground(Vector3(20, 120, 26), Vector3.DOWN)
	assert_true(hit is Vector3, "ray straight down hits Brightwater")
	if hit is Vector3:
		assert_almost_eq((hit as Vector3).y, layout.ground_at(20, 26), 0.05, "hit height")
