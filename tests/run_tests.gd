extends SceneTree
## Runs every test_*.gd in res://tests headless and exits with 1 if any test fails:
##   godot --headless --path . -s res://tests/run_tests.gd
## Tests may be coroutines (await frames) and may add nodes under `tree.root`.

const TEST_DIR := "res://tests"


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	# Let the autoloads finish their first frame.
	await process_frame
	var failed := 0
	var passed := 0
	for file in DirAccess.get_files_at(TEST_DIR):
		if not (file.begins_with("test_") and file.ends_with(".gd")) or file == "test_case.gd":
			continue
		var script: GDScript = load(TEST_DIR.path_join(file))
		for method in script.get_script_method_list():
			var name: String = method["name"]
			if not name.begins_with("test_"):
				continue
			var test: TestCase = script.new()
			test.tree = self
			await test.call(name)
			test.after_each()
			if test.failures.is_empty():
				passed += 1
				print("  ok    %s.%s" % [file.get_basename(), name])
			else:
				failed += 1
				print("  FAIL  %s.%s" % [file.get_basename(), name])
				for message in test.failures.slice(0, 5):
					print("          ", message)
	print("%d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)
