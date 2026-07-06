extends Node
## Global signal hub for decoupled, cross-cutting events (ARCHITECTURE.md §4).
##
## Emitters call `EventBus.<signal>.emit(...)`; listeners connect in `_ready`.
## Keep this a dumb pipe: no state, no logic. Signals are declared here even
## though this class never emits them itself, hence the warning ignores.

# -- Game flow ---------------------------------------------------------------

@warning_ignore("unused_signal")
signal game_state_changed(previous: StringName, next: StringName)

@warning_ignore("unused_signal")
signal district_started(district_id: StringName)

@warning_ignore("unused_signal")
signal district_completed(district_id: StringName)

# -- Combat ------------------------------------------------------------------

@warning_ignore("unused_signal")
signal hit_landed(attacker: Node, target: Node, damage: float)

@warning_ignore("unused_signal")
signal enemy_downed(enemy: Node)

## Normalized 0..1 combat intensity; drives MusicDirector and heat later.
@warning_ignore("unused_signal")
signal combat_intensity_changed(intensity: float)

# -- Crew --------------------------------------------------------------------

## Current crew command: &"mob" (engage freely) or &"regroup" (stay close).
@warning_ignore("unused_signal")
signal crew_command_changed(command: StringName)

# -- Meta --------------------------------------------------------------------

# reason: settings values are heterogeneous (bool/float/int), so Variant.
@warning_ignore("unused_signal")
signal setting_changed(key: StringName, value: Variant)

@warning_ignore("unused_signal")
signal save_completed()
