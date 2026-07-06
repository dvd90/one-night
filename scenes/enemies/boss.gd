extends "res://scenes/enemies/fodder.gd"
## District gang leader (ROADMAP M3): a two-phase boss on top of the fodder
## FSM. Phase 2 (below half health) fights faster and mixes in the slam.

## Guard-breaking heavy used from phase 2 (and as an opener surprise).
@export var slam_move: MoveData
## Cooldown multiplier once phase 2 hits.
@export var phase2_tempo: float = 0.6

var _swing_count: int = 0


func phase() -> int:
	return CombatMath.boss_phase(health, data.max_health)


func _pick_move() -> MoveData:
	if slam_move == null:
		return attack_move
	if phase() == 2:
		# Alternate jab / slam so the guard-break stays readable.
		_swing_count += 1
		return slam_move if _swing_count % 2 == 0 else attack_move
	return attack_move


func _cooldown_ticks() -> int:
	var base := (data as EnemyData).attack_cooldown_ticks
	if phase() == 2:
		return maxi(int(round(float(base) * phase2_tempo)), 1)
	return base
