extends SceneTree
## Minimal headless test runner, used until GUT is installed (see
## OPEN_QUESTIONS.md). Discovers res://tests/test_*.gd, runs every test_*
## method on a fresh instance, and exits non-zero on any failure.
##
## Run from the project root:
##   godot --headless -s tests/lite_test_runner.gd

const TESTS_DIR := "res://tests"


func _initialize() -> void:
	var total := 0
	var failed := 0
	var dir := DirAccess.open(TESTS_DIR)
	if dir == null:
		push_error("Cannot open %s" % TESTS_DIR)
		quit(1)
		return

	for file_name: String in dir.get_files():
		if not (file_name.begins_with("test_") and file_name.ends_with(".gd")):
			continue
		var script: GDScript = load(TESTS_DIR.path_join(file_name))
		for method: Dictionary in script.get_script_method_list():
			var method_name: String = method["name"]
			if not method_name.begins_with("test_"):
				continue
			total += 1
			# reason: test scripts share only the lite_test.gd base contract.
			var test_case: Variant = script.new()
			test_case.call(method_name)
			var failures: Array[String] = test_case.failures
			if failures.is_empty():
				print("  PASS  %s :: %s" % [file_name, method_name])
			else:
				failed += 1
				for failure: String in failures:
					printerr("  FAIL  %s :: %s — %s" % [file_name, method_name, failure])

	print("%d/%d tests passed." % [total - failed, total])
	quit(0 if failed == 0 else 1)
