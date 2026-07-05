extends "res://tests/lite_test.gd"
## Save schema + migration tests (node-free static functions only).

const SaveManagerScript := preload("res://autoload/save_manager.gd")


func test_default_save_is_current_version() -> void:
	var save := SaveManagerScript.default_save()
	assert_eq(save["version"], SaveManagerScript.SCHEMA_VERSION)
	assert_eq(save["district"], "docks", "a fresh game starts at the Docks")
	assert_eq(save["flash"], 0)


func test_migrate_unversioned_save_fills_missing_fields() -> void:
	# reason: simulating a legacy, schemaless on-disk save.
	var legacy: Dictionary[String, Variant] = {"flash": 25}
	var migrated := SaveManagerScript.migrate(legacy)
	assert_eq(migrated["version"], SaveManagerScript.SCHEMA_VERSION)
	assert_eq(migrated["flash"], 25, "existing fields survive migration")
	assert_true(migrated.has("upgrades"), "missing fields are filled in")
	assert_true(migrated.has("crew"), "missing fields are filled in")


func test_migrate_preserves_unknown_fields() -> void:
	# reason: forward-compat data from a newer minor build must survive.
	var save: Dictionary[String, Variant] = {"version": 0, "modded_extra": true}
	var migrated := SaveManagerScript.migrate(save)
	assert_eq(migrated["modded_extra"], true)


func test_migrate_current_version_is_unchanged() -> void:
	var save := SaveManagerScript.default_save()
	save["flash"] = 999
	var migrated := SaveManagerScript.migrate(save)
	assert_eq(migrated, save)
