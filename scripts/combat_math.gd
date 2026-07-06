class_name CombatMath
extends RefCounted
## Node-free combat math (ARCHITECTURE.md §5) — static functions only, so the
## whole file is unit-testable without a running scene.

enum Phase { STARTUP, ACTIVE, RECOVERY, DONE }


## Which phase of a move a given tick (counted from move start) falls in.
static func phase_for_tick(move: MoveData, tick: int) -> Phase:
	if tick < move.startup_ticks:
		return Phase.STARTUP
	if tick < move.startup_ticks + move.active_ticks:
		return Phase.ACTIVE
	if tick < move.total_ticks():
		return Phase.RECOVERY
	return Phase.DONE


## True when the hitbox should be live on this tick.
static func is_active_tick(move: MoveData, tick: int) -> bool:
	return phase_for_tick(move, tick) == Phase.ACTIVE


## True when a queued follow-up may cancel the current move on this tick.
static func can_cancel_on_tick(move: MoveData, tick: int) -> bool:
	if move.cancel_from_tick <= 0:
		return tick >= move.total_ticks()
	return tick >= move.cancel_from_tick


## Knockback velocity for a victim at `to_pos` hit from `from_pos`.
## Purely horizontal direction plus an explicit vertical lift.
static func knockback_velocity(
	from_pos: Vector3, to_pos: Vector3, speed: float, lift: float
) -> Vector3:
	var away := to_pos - from_pos
	away.y = 0.0
	# Degenerate overlap: shove the victim backward along +Z deterministically.
	var direction := away.normalized() if away.length_squared() > 0.0001 else Vector3(0, 0, 1)
	return direction * speed + Vector3.UP * lift


## Damage that gets through a (possibly) blocking defender.
## A successful block negates damage entirely unless the move guard-breaks.
static func damage_after_block(damage: float, blocked: bool, guard_break: bool) -> float:
	if blocked and not guard_break:
		return 0.0
	return damage


## Whether a defender facing `facing` blocks a hit coming from `to_attacker`.
## Blocks only cover the frontal arc (dot > 0.25 ≈ ±75°).
static func is_frontal(facing: Vector3, to_attacker: Vector3) -> bool:
	var flat_facing := Vector3(facing.x, 0.0, facing.z).normalized()
	var flat_to := Vector3(to_attacker.x, 0.0, to_attacker.z).normalized()
	return flat_facing.dot(flat_to) > 0.25


## True if `tick` (counted from dodge start) is inside the i-frame window.
static func is_iframe_tick(data: CombatantData, tick: int) -> bool:
	return tick >= data.dodge_iframe_start and tick <= data.dodge_iframe_end


## Hitstun after the defender's armor scale; a connected hit always stuns
## for at least 1 tick so feedback never fully disappears.
static func scaled_hitstun(base_ticks: int, scale: float) -> int:
	return maxi(int(round(float(base_ticks) * scale)), 1)


## Boss phase from remaining health: phase 2 at or below half.
static func boss_phase(health: float, max_health: float) -> int:
	return 2 if health <= max_health * 0.5 else 1
