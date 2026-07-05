extends Node3D
## Third-person camera rig: soft positional lag + auto-yaw behind the player,
## with hit-shake. Runs in _process — camera smoothing is render-cosmetic
## (ARCHITECTURE.md §3); it reads the player's interpolated transform.
##
## `top_level = true` in the scene so the rig ignores the player's rotation.

@export var follow_lag: float = 8.0
## How fast the rig yaws back behind the player's travel direction, in rad/s.
@export var auto_yaw_speed: float = 1.6
@export var shake_decay: float = 8.0
@export var shake_strength: float = 0.18

var _shake: float = 0.0

@onready var _player: CharacterBody3D = get_parent()
@onready var _camera: Camera3D = $SpringArm3D/Camera3D


func _ready() -> void:
	EventBus.hit_landed.connect(_on_hit_landed)


func _process(delta: float) -> void:
	var target: Vector3 = _player.get_global_transform_interpolated().origin
	global_position = global_position.lerp(target, 1.0 - exp(-follow_lag * delta))

	# Lazy auto-follow: drift the yaw toward the player's movement direction.
	var horizontal := Vector2(_player.velocity.x, _player.velocity.z)
	if horizontal.length_squared() > 1.0:
		var travel_yaw := atan2(-horizontal.x, -horizontal.y)
		global_rotation.y = rotate_toward(
			global_rotation.y, travel_yaw, auto_yaw_speed * delta
		)

	if _shake > 0.001:
		_shake = maxf(_shake - shake_decay * delta * _shake, 0.0)
		_camera.h_offset = randf_range(-1.0, 1.0) * _shake
		_camera.v_offset = randf_range(-1.0, 1.0) * _shake
	else:
		_camera.h_offset = 0.0
		_camera.v_offset = 0.0


func _on_hit_landed(_attacker: Node, _target: Node, damage: float) -> void:
	if not bool(Config.get_setting(&"camera/screenshake")):
		return
	if damage <= 0.0:
		return
	_shake = shake_strength * clampf(damage / 10.0, 0.4, 2.0)
