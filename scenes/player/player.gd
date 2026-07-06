extends Combatant
## Player: camera-relative movement, light combo string, heavy, block, dodge.
## Reads Input Map actions only (mobile-first hard rule 7) — the touch layer
## feeds the same actions, so this script never knows about devices.

## The light combo string, in order. Landing inputs inside a move's cancel
## window chains to the next entry.
@export var light_combo: Array[MoveData] = []
@export var heavy_move: MoveData
## How far away a soft-target enemy can be, in m.
@export var target_range: float = 5.0

## Current crew command, toggled with the `command` action.
var crew_command: StringName = &"mob"

var _combo_index: int = 0

@onready var camera_rig: Node3D = $CameraRig


func _ready() -> void:
	super()
	add_to_group("player")
	add_to_group("heroes")


func _physics_process(delta: float) -> void:
	if state != State.DOWN and hitstop_remaining <= 0:
		_read_combat_input()
	super(delta)


func _desired_direction() -> Vector3:
	var raw := Input.get_vector(&"move_left", &"move_right", &"move_forward", &"move_back")
	if raw.length_squared() < 0.01:
		return Vector3.ZERO
	# Camera-relative: forward on the stick is away from the camera.
	var yaw: float = camera_rig.global_rotation.y
	return Vector3(raw.x, 0.0, raw.y).rotated(Vector3.UP, yaw)


func _wants_block() -> bool:
	return Input.is_action_pressed(&"block")


func _read_combat_input() -> void:
	if Input.is_action_just_pressed(&"attack_light"):
		_try_light()
	elif Input.is_action_just_pressed(&"attack_heavy") and heavy_move != null:
		_face_soft_target()
		if try_attack(heavy_move):
			_combo_index = 0
	elif Input.is_action_just_pressed(&"dodge"):
		try_dodge(_desired_direction())
	elif Input.is_action_just_pressed(&"command"):
		crew_command = &"regroup" if crew_command == &"mob" else &"mob"
		EventBus.crew_command_changed.emit(crew_command)


func _try_light() -> void:
	if light_combo.is_empty():
		return
	# Continue the string only when cancelling out of the previous light.
	var next_index := 0
	if state == State.ATTACK and current_move != null \
			and light_combo.has(current_move):
		next_index = (_combo_index + 1) % light_combo.size()
	_face_soft_target()
	if try_attack(light_combo[next_index]):
		_combo_index = next_index


## Soft targeting: snap facing toward the nearest live enemy in range, so
## attacks connect without a lock-on (GAME_DESIGN.md §6).
func _face_soft_target() -> void:
	var nearest: Combatant = null
	var nearest_dist := target_range
	for node: Node in get_tree().get_nodes_in_group("enemies"):
		if node is not Combatant:
			continue
		var enemy := node as Combatant
		if enemy.state == State.DOWN:
			continue
		var dist := global_position.distance_to(enemy.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = enemy
	if nearest != null:
		_turn_instantly(nearest.global_position - global_position)
