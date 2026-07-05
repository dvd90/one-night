extends Node
## Versioned JSON save to user:// (ARCHITECTURE.md §12). M0 stub.
##
## The schema/migration functions are static and node-free so they stay
## unit-testable without a running scene.

const SAVE_PATH := "user://save.json"
const SCHEMA_VERSION: int = 1


## The canonical empty save for the current schema version.
# reason: save data is heterogeneous JSON, so Variant values.
static func default_save() -> Dictionary[String, Variant]:
	return {
		"version": SCHEMA_VERSION,
		"district": "docks",
		"flash": 0,
		"upgrades": [],
		"crew": [],
		"collectibles": [],
	}


## Migrates a save of any older version up to SCHEMA_VERSION. Unknown fields
## are preserved; missing fields are filled from the current defaults.
# reason: save data is heterogeneous JSON, so Variant values.
static func migrate(data: Dictionary[String, Variant]) -> Dictionary[String, Variant]:
	# reason: duplicate of a heterogeneous save dictionary.
	var migrated: Dictionary[String, Variant] = data.duplicate(true)
	var version: int = int(migrated.get("version", 0))
	if version < 1:
		var base := default_save()
		for key: String in base:
			if not migrated.has(key):
				migrated[key] = base[key]
		version = 1
	migrated["version"] = version
	return migrated


func save_game(data: Dictionary[String, Variant]) -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Failed to open %s for writing (error %d)" % [SAVE_PATH, FileAccess.get_open_error()])
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	EventBus.save_completed.emit()


## Loads and migrates the save; returns a fresh default save when absent
## or unreadable.
# reason: save data is heterogeneous JSON, so Variant values.
func load_game() -> Dictionary[String, Variant]:
	if not FileAccess.file_exists(SAVE_PATH):
		return default_save()
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("Failed to open %s for reading (error %d)" % [SAVE_PATH, FileAccess.get_open_error()])
		return default_save()
	var text := file.get_as_text()
	file.close()
	# reason: JSON.parse_string returns a schemaless Variant.
	var parsed: Variant = JSON.parse_string(text)
	if parsed is not Dictionary:
		push_error("Corrupt save at %s; starting fresh." % SAVE_PATH)
		return default_save()
	# reason: rebuilding a typed dictionary from schemaless JSON.
	var typed: Dictionary[String, Variant] = {}
	for key: Variant in parsed:
		typed[String(key)] = parsed[key]
	return migrate(typed)
