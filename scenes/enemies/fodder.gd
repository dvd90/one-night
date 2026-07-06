extends Combatant
## Fodder enemy (Wharf Rat tier): the cheap FSM from GAME_DESIGN.md §8 —
## approach → telegraph/attack (MoveData startup is the telegraph) → recover.
## M3 moves crowds of these onto MultiMesh + FodderManager; this full-scene
## version is the M2 "one enemy done properly" step.

## Ticks a KO'd body stays before despawning (ragdoll-lite comes in M6).
const DESPAWN_TICKS := 180

@export var attack_move: MoveData

var _attack_cooldown: int = 0
var _down_ticks: int = 0
# Nearest hero (player or crew ally) this enemy is hunting.
var _target: Combatant = null


func _ready() -> void:
	super()
	add_to_group("enemies")


func _physics_process(delta: float) -> void:
	if state == State.DOWN:
		_down_ticks += 1
		# Cheap KO read: tip over, then let gravity sink the body once world
		# collision is off, and free it.
		rotation.x = move_toward(rotation.x, -PI * 0.5, 4.0 * delta)
		if _down_ticks == DESPAWN_TICKS - 60:
			collision_mask = 0
		if _down_ticks >= DESPAWN_TICKS:
			queue_free()
			return
	if _target == null or not is_instance_valid(_target) or _target.state == State.DOWN:
		_target = _find_target()
	if hitstop_remaining <= 0:
		_think()
	super(delta)


func _think() -> void:
	if _attack_cooldown > 0:
		_attack_cooldown -= 1
	if state in [State.ATTACK, State.DODGE, State.HITSTUN, State.DOWN]:
		return
	if _target == null:
		return
	var enemy_data := data as EnemyData
	var to_target := _target.global_position - global_position
	to_target.y = 0.0
	var move := _pick_move()
	if to_target.length() <= enemy_data.attack_range \
			and _attack_cooldown <= 0 and move != null:
		_turn_instantly(to_target)
		if try_attack(move):
			_attack_cooldown = _cooldown_ticks()


## Overridable hooks so heavier enemies (boss) can vary moves and tempo.
func _pick_move() -> MoveData:
	return attack_move


func _cooldown_ticks() -> int:
	return (data as EnemyData).attack_cooldown_ticks


func _desired_direction() -> Vector3:
	if _target == null:
		return Vector3.ZERO
	var enemy_data := data as EnemyData
	var to_target := _target.global_position - global_position
	to_target.y = 0.0
	var distance := to_target.length()
	if distance > enemy_data.aggro_range:
		return Vector3.ZERO
	var direction := Vector3.ZERO
	# Seek, but keep a little spacing so the mob doesn't stack into one column.
	if distance > enemy_data.attack_range * 0.8:
		direction = to_target.normalized()
	return (direction + _separation(enemy_data)).limit_length(1.0)


## Simple separation steering away from nearby packmates.
func _separation(enemy_data: EnemyData) -> Vector3:
	var push := Vector3.ZERO
	for node: Node in get_tree().get_nodes_in_group("enemies"):
		if node == self or node is not Combatant:
			continue
		var other := node as Combatant
		var away := global_position - other.global_position
		away.y = 0.0
		var dist := away.length()
		if dist < enemy_data.separation_radius and dist > 0.001:
			push += away / dist * (1.0 - dist / enemy_data.separation_radius)
	return push * 0.8


## Nearest live hero (player or crew ally).
func _find_target() -> Combatant:
	var nearest: Combatant = null
	var nearest_dist := INF
	for node: Node in get_tree().get_nodes_in_group("heroes"):
		if node is not Combatant:
			continue
		var hero := node as Combatant
		if hero.state == State.DOWN:
			continue
		var dist := global_position.distance_squared_to(hero.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = hero
	return nearest
