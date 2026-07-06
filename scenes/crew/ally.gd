extends Combatant
## Crew ally (ROADMAP M3): fights beside the player, obeys the crew command
## (mob = engage freely, regroup = stick to the player), goes down and gets
## revived on wave clear. Same combat parts as everyone else.

## How close the ally stays to the player when regrouping/idle, in m.
@export var follow_distance: float = 2.2
## How far from the player the ally is willing to chase a target, in m.
@export var leash_range: float = 12.0
@export var attack_move: MoveData

var command: StringName = &"mob"

var _attack_cooldown: int = 0
var _player: Combatant = null
var _enemy_target: Combatant = null


func _ready() -> void:
	super()
	add_to_group("heroes")
	add_to_group("crew")
	EventBus.crew_command_changed.connect(_on_command_changed)


func _physics_process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		_player = _find_player()
	if _enemy_target == null or not is_instance_valid(_enemy_target) \
			or _enemy_target.state == State.DOWN:
		_enemy_target = _find_enemy()
	if hitstop_remaining <= 0:
		_think()
	super(delta)


func _think() -> void:
	if _attack_cooldown > 0:
		_attack_cooldown -= 1
	if state in [State.ATTACK, State.DODGE, State.HITSTUN, State.DOWN]:
		return
	if command == &"regroup" or _enemy_target == null or attack_move == null:
		return
	var enemy_data := data as EnemyData
	var to_enemy := _enemy_target.global_position - global_position
	to_enemy.y = 0.0
	if to_enemy.length() <= enemy_data.attack_range and _attack_cooldown <= 0:
		_turn_instantly(to_enemy)
		if try_attack(attack_move):
			_attack_cooldown = enemy_data.attack_cooldown_ticks


func _desired_direction() -> Vector3:
	if _player == null:
		return Vector3.ZERO
	var to_player := _player.global_position - global_position
	to_player.y = 0.0
	var engaging := command == &"mob" and _enemy_target != null \
			and to_player.length() < leash_range
	if engaging:
		var to_enemy := _enemy_target.global_position - global_position
		to_enemy.y = 0.0
		if to_enemy.length() > (data as EnemyData).attack_range * 0.8:
			return to_enemy.normalized()
		return Vector3.ZERO
	if to_player.length() > follow_distance:
		return to_player.normalized()
	return Vector3.ZERO


func _on_command_changed(new_command: StringName) -> void:
	command = new_command


func _find_player() -> Combatant:
	var nodes := get_tree().get_nodes_in_group("player")
	if nodes.is_empty():
		return null
	# reason: group nodes are untyped; the cast documents the contract.
	var node: Node = nodes[0]
	return node as Combatant


func _find_enemy() -> Combatant:
	var nearest: Combatant = null
	var nearest_dist := INF
	for node: Node in get_tree().get_nodes_in_group("enemies"):
		if node is not Combatant:
			continue
		var enemy := node as Combatant
		if enemy.state == State.DOWN:
			continue
		var dist := global_position.distance_squared_to(enemy.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = enemy
	return nearest
