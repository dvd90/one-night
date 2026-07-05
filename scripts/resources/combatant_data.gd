class_name CombatantData
extends Resource
## Shared combatant tunables: vitals, locomotion, and dodge frame data.

@export var max_health: float = 100.0
@export var movement: MovementData

@export_group("Dodge", "dodge_")
@export var dodge_duration_ticks: int = 24
@export var dodge_iframe_start: int = 2
@export var dodge_iframe_end: int = 14
@export var dodge_speed: float = 9.0
@export var dodge_cooldown_ticks: int = 18
