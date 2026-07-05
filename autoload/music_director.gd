extends Node
## Interactive-music director stub (ARCHITECTURE.md §10).
##
## M6 gives this an AudioStreamInteractive graph (base + combat layers +
## boss) with beat-synced transitions. For now it just tracks the combat
## intensity that will drive those transitions.

var intensity: float = 0.0


func _ready() -> void:
	EventBus.combat_intensity_changed.connect(_on_combat_intensity_changed)


func _on_combat_intensity_changed(value: float) -> void:
	intensity = clampf(value, 0.0, 1.0)
