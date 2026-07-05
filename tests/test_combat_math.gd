extends "res://tests/lite_test.gd"
## Combat math tests: tick/phase resolution, cancel windows, knockback,
## block interaction, i-frame windows (ROADMAP M2).

const CombatMathScript := preload("res://scripts/combat_math.gd")
const MoveDataScript := preload("res://scripts/resources/move_data.gd")
const CombatantDataScript := preload("res://scripts/resources/combatant_data.gd")


# reason: helper returns a script instance; typed as Resource for clarity.
func _make_move() -> Resource:
	var move: Resource = MoveDataScript.new()
	move.startup_ticks = 5
	move.active_ticks = 3
	move.recovery_ticks = 10
	move.cancel_from_tick = 12
	return move


func test_phase_boundaries() -> void:
	var move := _make_move()
	assert_eq(CombatMathScript.phase_for_tick(move, 0), CombatMathScript.Phase.STARTUP)
	assert_eq(CombatMathScript.phase_for_tick(move, 4), CombatMathScript.Phase.STARTUP)
	assert_eq(CombatMathScript.phase_for_tick(move, 5), CombatMathScript.Phase.ACTIVE)
	assert_eq(CombatMathScript.phase_for_tick(move, 7), CombatMathScript.Phase.ACTIVE)
	assert_eq(CombatMathScript.phase_for_tick(move, 8), CombatMathScript.Phase.RECOVERY)
	assert_eq(CombatMathScript.phase_for_tick(move, 17), CombatMathScript.Phase.RECOVERY)
	assert_eq(CombatMathScript.phase_for_tick(move, 18), CombatMathScript.Phase.DONE)


func test_active_ticks_match_phase() -> void:
	var move := _make_move()
	assert_false(CombatMathScript.is_active_tick(move, 4))
	assert_true(CombatMathScript.is_active_tick(move, 5))
	assert_true(CombatMathScript.is_active_tick(move, 7))
	assert_false(CombatMathScript.is_active_tick(move, 8))


func test_cancel_window() -> void:
	var move := _make_move()
	assert_false(CombatMathScript.can_cancel_on_tick(move, 11))
	assert_true(CombatMathScript.can_cancel_on_tick(move, 12))
	move.cancel_from_tick = 0
	assert_false(
		CombatMathScript.can_cancel_on_tick(move, 17),
		"cancel disabled: recovery must play out"
	)
	assert_true(CombatMathScript.can_cancel_on_tick(move, 18))


func test_knockback_is_horizontal_plus_lift() -> void:
	var velocity: Vector3 = CombatMathScript.knockback_velocity(
		Vector3.ZERO, Vector3(2, 5, 0), 6.0, 2.0
	)
	assert_true(velocity.is_equal_approx(Vector3(6, 2, 0)), "got %s" % velocity)


func test_knockback_degenerate_overlap_is_deterministic() -> void:
	var a: Vector3 = CombatMathScript.knockback_velocity(Vector3.ZERO, Vector3.ZERO, 5.0, 1.0)
	var b: Vector3 = CombatMathScript.knockback_velocity(Vector3.ZERO, Vector3.ZERO, 5.0, 1.0)
	assert_eq(a, b)
	assert_true(a.length() > 0.0, "still shoves the victim somewhere")


func test_block_negates_damage_unless_guard_break() -> void:
	assert_eq(CombatMathScript.damage_after_block(10.0, false, false), 10.0)
	assert_eq(CombatMathScript.damage_after_block(10.0, true, false), 0.0)
	assert_eq(CombatMathScript.damage_after_block(10.0, true, true), 10.0)


func test_block_covers_frontal_arc_only() -> void:
	var facing := Vector3(0, 0, 1)
	assert_true(CombatMathScript.is_frontal(facing, Vector3(0, 0, 1)))
	assert_true(CombatMathScript.is_frontal(facing, Vector3(0.5, 0, 1)))
	assert_false(CombatMathScript.is_frontal(facing, Vector3(0, 0, -1)), "backstab")
	assert_false(CombatMathScript.is_frontal(facing, Vector3(1, 0, 0)), "flank")


func test_iframe_window() -> void:
	var data: Resource = CombatantDataScript.new()
	data.dodge_iframe_start = 2
	data.dodge_iframe_end = 14
	assert_false(CombatMathScript.is_iframe_tick(data, 1))
	assert_true(CombatMathScript.is_iframe_tick(data, 2))
	assert_true(CombatMathScript.is_iframe_tick(data, 14))
	assert_false(CombatMathScript.is_iframe_tick(data, 15))
