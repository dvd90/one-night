extends RefCounted
## Minimal test base with GUT-compatible assertion names (assert_eq/
## assert_true/assert_false take the same arguments as GUT's).
##
## This exists because the GUT addon couldn't be fetched in the sandboxed
## dev environment (see OPEN_QUESTIONS.md). Once GUT is installed from the
## Asset Library, porting a test is just: `extends "res://tests/lite_test.gd"`
## → `extends GutTest`.

var failures: Array[String] = []


func assert_true(condition: bool, message: String = "") -> void:
	if not condition:
		failures.append("assert_true failed. %s" % message)


func assert_false(condition: bool, message: String = "") -> void:
	if condition:
		failures.append("assert_false failed. %s" % message)


# reason: generic assertion compares values of any type, like GUT's.
func assert_eq(got: Variant, expected: Variant, message: String = "") -> void:
	if got != expected:
		failures.append(
			"assert_eq failed: got %s, expected %s. %s" % [str(got), str(expected), message]
		)
