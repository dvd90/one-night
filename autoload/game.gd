extends Node
## Top-level game flow state machine: boot → menu → district → safehouse
## (ARCHITECTURE.md §2). M0 stub: states + transitions exist, screens don't.

enum State { BOOT, MENU, DISTRICT, SAFEHOUSE }

var state: State = State.BOOT


func _ready() -> void:
	# M0: no title screen yet — the main scene is the test level, so we jump
	# straight to DISTRICT. M5 replaces this with the real title → play flow.
	change_state(State.DISTRICT)


func change_state(next: State) -> void:
	if next == state:
		return
	var previous: State = state
	state = next
	EventBus.game_state_changed.emit(state_name(previous), state_name(next))


static func state_name(value: State) -> StringName:
	match value:
		State.BOOT:
			return &"boot"
		State.MENU:
			return &"menu"
		State.DISTRICT:
			return &"district"
		State.SAFEHOUSE:
			return &"safehouse"
	return &"unknown"
