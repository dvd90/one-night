class_name Pickup
extends Area3D
## Walk-over pickup base (mobile-first: no extra button needed). Spins and
## bobs in _physics_process; applies itself to the player on contact.

@export var bob_height: float = 0.12
@export var spin_speed_deg: float = 90.0

var _base_height: float = 0.0
var _elapsed: float = 0.0


func _ready() -> void:
	_base_height = position.y
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	_elapsed += delta
	rotate_y(deg_to_rad(spin_speed_deg) * delta)
	position.y = _base_height + (sin(_elapsed * TAU * 0.8) * 0.5 + 0.5) * bob_height


func _on_body_entered(body: Node3D) -> void:
	if body is not Combatant or not body.is_in_group("player"):
		return
	_apply(body as Combatant)
	queue_free()


## Overridden by concrete pickups.
func _apply(_target: Combatant) -> void:
	pass
