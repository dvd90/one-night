class_name Combatant
extends CharacterBody3D
## Base combatant: state machine + tick-stepped attacks + hit resolution
## (ARCHITECTURE.md §5). Player and enemies extend this; all gameplay runs in
## _physics_process (fixed 60 Hz) — the determinism hard rule.
##
## Expected child nodes: $Hitbox (Area3D, monitoring off by default) and
## $Hurtbox (Area3D, monitorable). Hitbox layers/masks are set per-scene so
## player hitboxes only ever overlap enemy hurtboxes and vice versa.

signal health_changed(current: float, maximum: float)
signal downed()
signal weapon_changed(weapon: WeaponData, hits_left: int)

enum State { IDLE, MOVE, ATTACK, BLOCK, DODGE, HITSTUN, DOWN }

@export var data: CombatantData

var state: State = State.IDLE
var health: float = 100.0
var facing: Vector3 = Vector3.FORWARD

# Attack bookkeeping (ticks counted from move start).
var current_move: MoveData = null
var attack_tick: int = 0

# Dodge bookkeeping (ticks counted from dodge start).
var dodge_tick: int = 0

# Hit reactions.
var hitstun_remaining: int = 0
var hitstop_remaining: int = 0

# Held environmental weapon (GAME_DESIGN.md §6), null when bare-handed.
var weapon: WeaponData = null
var weapon_hits_left: int = 0

var _hit_this_swing: Array[Combatant] = []
var _dodge_direction: Vector3 = Vector3.FORWARD
var _dodge_cooldown: int = 0

@onready var hitbox: Area3D = $Hitbox
@onready var hurtbox: Area3D = $Hurtbox


func _ready() -> void:
	assert(data != null, "%s needs a CombatantData resource" % name)
	assert(data.movement != null, "%s's CombatantData needs a MovementData" % name)
	health = data.max_health
	hitbox.monitoring = false


func _physics_process(delta: float) -> void:
	# Hitstop: the impact freeze. Skip everything, including gravity.
	if hitstop_remaining > 0:
		hitstop_remaining -= 1
		return

	if _dodge_cooldown > 0:
		_dodge_cooldown -= 1

	match state:
		State.ATTACK:
			_tick_attack(delta)
		State.DODGE:
			_tick_dodge(delta)
		State.HITSTUN:
			_tick_hitstun(delta)
		State.DOWN:
			_apply_gravity(delta)
			velocity.x = move_toward(velocity.x, 0.0, data.movement.deceleration * delta)
			velocity.z = move_toward(velocity.z, 0.0, data.movement.deceleration * delta)
		_:
			_tick_locomotion(delta)

	move_and_slide()


## Overridden by subclasses: return the desired move direction (world space,
## y = 0, length <= 1) for this tick. Base combatants stand still.
func _desired_direction() -> Vector3:
	return Vector3.ZERO


## Overridden by subclasses: true while the block input/intent is held.
func _wants_block() -> bool:
	return false


# -- State ticks -------------------------------------------------------------


func _tick_locomotion(delta: float) -> void:
	_apply_gravity(delta)
	var direction := _desired_direction()
	var blocking := _wants_block()
	if blocking:
		direction = Vector3.ZERO

	var target := direction * data.movement.max_speed
	var rate := data.movement.acceleration if direction.length_squared() > 0.01 \
			else data.movement.deceleration
	velocity.x = move_toward(velocity.x, target.x, rate * delta)
	velocity.z = move_toward(velocity.z, target.z, rate * delta)

	if direction.length_squared() > 0.01:
		_turn_toward(direction, delta)
		state = State.MOVE
	else:
		state = State.BLOCK if blocking else State.IDLE


func _tick_attack(delta: float) -> void:
	_apply_gravity(delta)
	var phase := CombatMath.phase_for_tick(current_move, attack_tick)

	# Small forward lunge while the swing is coming out.
	var lunge := facing * current_move.lunge_speed \
			if phase != CombatMath.Phase.RECOVERY else Vector3.ZERO
	velocity.x = lunge.x
	velocity.z = lunge.z

	hitbox.monitoring = CombatMath.is_active_tick(current_move, attack_tick)
	if hitbox.monitoring:
		_resolve_hitbox_overlaps()

	attack_tick += 1
	if attack_tick >= current_move.total_ticks():
		_end_attack()


func _tick_dodge(delta: float) -> void:
	_apply_gravity(delta)
	velocity.x = _dodge_direction.x * data.dodge_speed
	velocity.z = _dodge_direction.z * data.dodge_speed
	dodge_tick += 1
	if dodge_tick >= data.dodge_duration_ticks:
		_dodge_cooldown = data.dodge_cooldown_ticks
		state = State.IDLE


func _tick_hitstun(delta: float) -> void:
	_apply_gravity(delta)
	velocity.x = move_toward(velocity.x, 0.0, data.movement.deceleration * 0.5 * delta)
	velocity.z = move_toward(velocity.z, 0.0, data.movement.deceleration * 0.5 * delta)
	hitstun_remaining -= 1
	if hitstun_remaining <= 0:
		state = State.IDLE


# -- Actions -----------------------------------------------------------------


func try_attack(move: MoveData) -> bool:
	if state == State.ATTACK:
		if not CombatMath.can_cancel_on_tick(current_move, attack_tick):
			return false
	elif state in [State.DODGE, State.HITSTUN, State.DOWN]:
		return false
	current_move = move
	attack_tick = 0
	_hit_this_swing.clear()
	hitbox.monitoring = false
	state = State.ATTACK
	return true


func try_dodge(direction: Vector3) -> bool:
	if state in [State.ATTACK, State.DODGE, State.HITSTUN, State.DOWN]:
		return false
	if _dodge_cooldown > 0:
		return false
	_dodge_direction = direction.normalized() if direction.length_squared() > 0.01 else facing
	_turn_instantly(_dodge_direction)
	dodge_tick = 0
	state = State.DODGE
	return true


## Full hit resolution on the defender side (ARCHITECTURE.md §5).
func take_hit(attacker: Combatant, move: MoveData) -> void:
	if state == State.DOWN:
		return
	# Dodge i-frames: clean whiff.
	if state == State.DODGE and CombatMath.is_iframe_tick(data, dodge_tick):
		return

	var to_attacker := attacker.global_position - global_position
	var blocked := state == State.BLOCK and CombatMath.is_frontal(facing, to_attacker)
	var raw_damage := move.damage + attacker.weapon_damage_bonus()
	var damage := CombatMath.damage_after_block(raw_damage, blocked, move.guard_break)
	attacker.spend_weapon_hit()

	if blocked and damage <= 0.0:
		# Chip-free block: small pushback, no stun. Guard-break falls through.
		velocity += CombatMath.knockback_velocity(
			attacker.global_position, global_position, move.knockback_speed * 0.4, 0.0
		)
		EventBus.hit_landed.emit(attacker, self, 0.0)
		return

	health = maxf(health - damage, 0.0)
	health_changed.emit(health, data.max_health)
	hitstop_remaining = move.hitstop_ticks
	attacker.hitstop_remaining = move.hitstop_ticks
	EventBus.hit_landed.emit(attacker, self, damage)

	if health <= 0.0:
		_enter_down_state()
		return

	velocity = CombatMath.knockback_velocity(
		attacker.global_position,
		global_position,
		move.knockback_speed + attacker.weapon_knockback_bonus(),
		move.knockback_lift
	)
	hitstun_remaining = CombatMath.scaled_hitstun(move.hitstun_ticks, data.hitstun_scale)
	_interrupt_attack()
	state = State.HITSTUN


func heal(amount: float) -> void:
	if state == State.DOWN:
		return
	health = minf(health + amount, data.max_health)
	health_changed.emit(health, data.max_health)


## Brings a downed combatant back up (crew revive — GAME_DESIGN.md §7).
func revive(health_fraction: float = 0.5) -> void:
	if state != State.DOWN:
		return
	health = clampf(data.max_health * health_fraction, 1.0, data.max_health)
	hurtbox.set_deferred("monitorable", true)
	rotation.x = 0.0
	state = State.IDLE
	health_changed.emit(health, data.max_health)


# -- Weapons -----------------------------------------------------------------


func equip_weapon(new_weapon: WeaponData) -> void:
	weapon = new_weapon
	weapon_hits_left = new_weapon.durability if new_weapon != null else 0
	weapon_changed.emit(weapon, weapon_hits_left)


func weapon_damage_bonus() -> float:
	return weapon.damage_bonus if weapon != null else 0.0


func weapon_knockback_bonus() -> float:
	return weapon.knockback_bonus if weapon != null else 0.0


## One durability charge per connected hit; the weapon breaks at zero.
func spend_weapon_hit() -> void:
	if weapon == null:
		return
	weapon_hits_left -= 1
	if weapon_hits_left <= 0:
		weapon = null
		weapon_hits_left = 0
	weapon_changed.emit(weapon, weapon_hits_left)


# -- Internals ---------------------------------------------------------------


func _resolve_hitbox_overlaps() -> void:
	for area: Area3D in hitbox.get_overlapping_areas():
		var owner_node := area.get_owner()
		if owner_node is not Combatant:
			continue
		var victim := owner_node as Combatant
		if victim == self or _hit_this_swing.has(victim):
			continue
		_hit_this_swing.append(victim)
		victim.take_hit(self, current_move)


func _end_attack() -> void:
	hitbox.monitoring = false
	current_move = null
	state = State.IDLE


func _interrupt_attack() -> void:
	if state == State.ATTACK:
		hitbox.monitoring = false
		current_move = null


func _enter_down_state() -> void:
	_interrupt_attack()
	state = State.DOWN
	velocity = Vector3.ZERO
	hurtbox.set_deferred("monitorable", false)
	downed.emit()


func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= data.movement.gravity * delta


func _turn_toward(direction: Vector3, delta: float) -> void:
	var flat := Vector3(direction.x, 0.0, direction.z)
	if flat.length_squared() < 0.0001:
		return
	flat = flat.normalized()
	var current_angle := atan2(facing.x, facing.z)
	var target_angle := atan2(flat.x, flat.z)
	var new_angle := rotate_toward(current_angle, target_angle, data.movement.turn_speed * delta)
	facing = Vector3(sin(new_angle), 0.0, cos(new_angle))
	rotation.y = new_angle


func _turn_instantly(direction: Vector3) -> void:
	var flat := Vector3(direction.x, 0.0, direction.z)
	if flat.length_squared() < 0.0001:
		return
	facing = flat.normalized()
	rotation.y = atan2(facing.x, facing.z)
