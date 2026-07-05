extends Node
## Tunables + user settings store (CLAUDE.md hard rule 3, ARCHITECTURE.md §4).
##
## M0 scope: the user-settings store with the PS1 presentation toggles.
## Later milestones add loading of gameplay Resources (moves, enemies,
## economy) here so balance lives in `data/*.tres`, not in code.

const SETTINGS_PATH := "user://settings.cfg"
const SETTINGS_SECTION := "settings"

## Every material that carries `ps1_snap.gdshader`. The PS1 toggles are pushed
## into these shared materials, so per-mesh materials stay dumb.
const PS1_MATERIALS: Array[ShaderMaterial] = [
	preload("res://assets/materials/ps1_base_material.tres"),
	preload("res://assets/materials/ps1_crimson_material.tres"),
]

## Single source of truth for setting keys and their default values.
## `ps1/scanlines` is stored now but only consumed once `ps1_post.gdshader`
## lands (M6); `camera/screenshake` is consumed by the camera rig (M1+).
# reason: settings values are heterogeneous (bool/float), so Variant values.
const DEFAULTS: Dictionary[StringName, Variant] = {
	&"ps1/vertex_snap": true,
	&"ps1/snap_resolution": 240.0,
	&"ps1/affine_mapping": true,
	&"ps1/scanlines": false,
	&"camera/screenshake": true,
}

# reason: mirrors DEFAULTS, heterogeneous values.
var _settings: Dictionary[StringName, Variant] = {}


func _ready() -> void:
	_settings = load_settings()
	apply_ps1_settings()


# reason: settings values are heterogeneous, callers know their key's type.
func get_setting(key: StringName) -> Variant:
	assert(DEFAULTS.has(key), "Unknown setting key: %s" % key)
	return _settings.get(key, DEFAULTS.get(key))


# reason: settings values are heterogeneous, callers know their key's type.
func set_setting(key: StringName, value: Variant) -> void:
	assert(DEFAULTS.has(key), "Unknown setting key: %s" % key)
	if _settings.get(key) == value:
		return
	_settings[key] = value
	save_settings()
	apply_ps1_settings()
	EventBus.setting_changed.emit(key, value)


## Pushes the current PS1 toggles into every shared PS1 material.
func apply_ps1_settings() -> void:
	for material: ShaderMaterial in PS1_MATERIALS:
		material.set_shader_parameter(&"snap_enabled", get_setting(&"ps1/vertex_snap"))
		material.set_shader_parameter(&"snap_resolution", get_setting(&"ps1/snap_resolution"))
		material.set_shader_parameter(&"affine_enabled", get_setting(&"ps1/affine_mapping"))


func load_settings() -> Dictionary[StringName, Variant]:
	var file := ConfigFile.new()
	# reason: ConfigFile values are schemaless on disk.
	var overrides: Dictionary[StringName, Variant] = {}
	if file.load(SETTINGS_PATH) == OK:
		for key: String in file.get_section_keys(SETTINGS_SECTION):
			overrides[StringName(key)] = file.get_value(SETTINGS_SECTION, key)
	return merged_with_defaults(overrides)


func save_settings() -> void:
	var file := ConfigFile.new()
	for key: StringName in _settings:
		file.set_value(SETTINGS_SECTION, String(key), _settings[key])
	var err := file.save(SETTINGS_PATH)
	if err != OK:
		push_error("Failed to save settings to %s (error %d)" % [SETTINGS_PATH, err])


## Node-free merge so it stays unit-testable: unknown keys are dropped,
## known keys override the defaults.
static func merged_with_defaults(
	overrides: Dictionary[StringName, Variant]
) -> Dictionary[StringName, Variant]:
	# reason: mirrors DEFAULTS, heterogeneous values.
	var merged: Dictionary[StringName, Variant] = DEFAULTS.duplicate()
	for key: StringName in overrides:
		if merged.has(key):
			merged[key] = overrides[key]
	return merged
