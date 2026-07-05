class_name MoveData
extends Resource
## One attack's frame data, authored in physics ticks @ 60 Hz
## (ARCHITECTURE.md §4-5). Combat states step through startup → active →
## recovery; the hitbox is live only during active ticks.

@export var move_name: StringName = &"move"
@export var startup_ticks: int = 6
@export var active_ticks: int = 3
@export var recovery_ticks: int = 12
@export var damage: float = 10.0
## Horizontal knockback speed applied to the victim, in m/s.
@export var knockback_speed: float = 4.0
## Vertical lift added to knockback, in m/s.
@export var knockback_lift: float = 0.0
@export var hitstun_ticks: int = 14
## Global-feel: both actors freeze for this many ticks on a confirmed hit.
@export var hitstop_ticks: int = 4
## Tick (from move start) at which the next combo input may cancel recovery.
## 0 disables cancelling — the full recovery must play out.
@export var cancel_from_tick: int = 0
@export var guard_break: bool = false
## Forward lunge speed during startup+active, in m/s (closes the gap).
@export var lunge_speed: float = 0.0


func total_ticks() -> int:
	return startup_ticks + active_ticks + recovery_ticks
