extends Pickup
## Restores health on walk-over.

@export var heal_amount: float = 25.0


func _apply(target: Combatant) -> void:
	target.heal(heal_amount)
