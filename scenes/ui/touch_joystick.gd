extends Control
## Virtual joystick: drags inside this control feed the move_* actions with
## analog strength, so gameplay code only ever reads Input Map actions
## (CLAUDE.md hard rule 7). Draws its own base + knob — no textures needed.

@export var radius: float = 80.0
@export var deadzone: float = 0.15

var _touch_index: int = -1
var _vector: Vector2 = Vector2.ZERO


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed and _touch_index == -1 \
				and get_global_rect().has_point(touch.position):
			_touch_index = touch.index
			_update_vector(touch.position)
		elif not touch.pressed and touch.index == _touch_index:
			_touch_index = -1
			_set_vector(Vector2.ZERO)
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if drag.index == _touch_index:
			_update_vector(drag.position)


func _update_vector(screen_position: Vector2) -> void:
	var center := get_global_rect().get_center()
	var offset := (screen_position - center) / radius
	_set_vector(offset.limit_length(1.0))


func _set_vector(value: Vector2) -> void:
	_vector = value if value.length() >= deadzone else Vector2.ZERO
	_feed_axis(&"move_left", &"move_right", _vector.x)
	_feed_axis(&"move_forward", &"move_back", _vector.y)
	queue_redraw()


func _feed_axis(negative: StringName, positive: StringName, value: float) -> void:
	if value < 0.0:
		Input.action_press(negative, -value)
		Input.action_release(positive)
	elif value > 0.0:
		Input.action_press(positive, value)
		Input.action_release(negative)
	else:
		Input.action_release(negative)
		Input.action_release(positive)


func _draw() -> void:
	var center := size * 0.5
	draw_circle(center, radius, Color(1, 1, 1, 0.08))
	draw_arc(center, radius, 0.0, TAU, 32, Color(1, 1, 1, 0.25), 2.0)
	draw_circle(center + _vector * radius * 0.6, radius * 0.35, Color(1, 1, 1, 0.22))
