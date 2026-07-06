extends Pickup
## Grants an environmental weapon (bat/pipe) on walk-over.

@export var weapon: WeaponData


func _apply(target: Combatant) -> void:
	target.equip_weapon(weapon)
