extends "res://tests/lite_test.gd"
## Settings-store tests (node-free static functions only).

const ConfigScript := preload("res://autoload/config.gd")


func test_defaults_include_all_ps1_toggles() -> void:
	for key: StringName in [
		&"ps1/vertex_snap",
		&"ps1/snap_resolution",
		&"ps1/affine_mapping",
		&"ps1/scanlines",
		&"camera/screenshake",
	]:
		assert_true(ConfigScript.DEFAULTS.has(key), "missing default for %s" % key)


func test_merge_applies_known_overrides() -> void:
	# reason: mirrors the heterogeneous settings dictionary.
	var overrides: Dictionary[StringName, Variant] = {&"ps1/vertex_snap": false}
	var merged := ConfigScript.merged_with_defaults(overrides)
	assert_eq(merged[&"ps1/vertex_snap"], false)
	assert_eq(merged[&"ps1/affine_mapping"], ConfigScript.DEFAULTS[&"ps1/affine_mapping"])


func test_merge_drops_unknown_keys() -> void:
	# reason: mirrors the heterogeneous settings dictionary.
	var overrides: Dictionary[StringName, Variant] = {&"bogus/key": 1}
	var merged := ConfigScript.merged_with_defaults(overrides)
	assert_false(merged.has(&"bogus/key"))
	assert_eq(merged.size(), ConfigScript.DEFAULTS.size())
