class_name MovementData
extends Resource
## Locomotion tunables (CLAUDE.md hard rule 3 — no magic numbers in scripts).

@export var max_speed: float = 6.0
@export var acceleration: float = 40.0
@export var deceleration: float = 32.0
## How fast the visual facing turns toward the move direction, in rad/s.
@export var turn_speed: float = 12.0
@export var gravity: float = 24.0
