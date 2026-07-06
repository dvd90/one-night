extends Control
## Round on-screen action button: presses feed one Input Map action, so it's
## indistinguishable from a keyboard/gamepad press to gameplay code.
## Self-drawn circle + label — no textures needed.

@export var action: StringName = &"attack_light"
@export var label: String = "ATK"
@export var color: Color = Color(1.0, 1.0, 1.0, 0.2)

var _touch_index: int = -1


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed and _touch_index == -1 \
				and get_global_rect().has_point(touch.position):
			_touch_index = touch.index
			_send_action(true)
			queue_redraw()
		elif not touch.pressed and touch.index == _touch_index:
			_touch_index = -1
			_send_action(false)
			queue_redraw()


## InputEventAction via parse_input_event updates polled action state AND
## flows through _input/_unhandled_input (needed by e.g. the pause menu) —
## unlike Input.action_press, which only sets polled state.
func _send_action(pressed: bool) -> void:
	var action_event := InputEventAction.new()
	action_event.action = action
	action_event.pressed = pressed
	Input.parse_input_event(action_event)


func _draw() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.5
	var fill := color
	if _touch_index != -1:
		fill.a = minf(fill.a * 2.5, 0.8)
	draw_circle(center, radius, fill)
	draw_arc(center, radius, 0.0, TAU, 32, Color(1, 1, 1, 0.3), 2.0)
	var font := get_theme_default_font()
	var font_size := get_theme_default_font_size()
	var text_size := font.get_string_size(label, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	draw_string(
		font,
		center + Vector2(-text_size.x * 0.5, text_size.y * 0.3),
		label,
		HORIZONTAL_ALIGNMENT_CENTER,
		-1,
		font_size,
		Color(1, 1, 1, 0.75)
	)
