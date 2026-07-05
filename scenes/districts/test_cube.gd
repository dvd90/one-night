extends MeshInstance3D
## Tumbles and bobs the M0 test cube so the PS1 vertex snapping is visible.
## Runs in _physics_process (fixed 60 Hz) per the determinism rule; rendering
## smoothness comes from physics interpolation, not from _process.

@export var turn_speed_deg: float = 45.0
@export var bob_height: float = 0.35
@export var bob_speed: float = 1.5

var _base_height: float = 0.0
var _elapsed: float = 0.0


func _ready() -> void:
	_base_height = position.y


func _physics_process(delta: float) -> void:
	_elapsed += delta
	rotate_y(deg_to_rad(turn_speed_deg) * delta)
	rotate_x(deg_to_rad(turn_speed_deg * 0.4) * delta)
	position.y = _base_height + sin(_elapsed * bob_speed * TAU) * bob_height
