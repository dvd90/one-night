class_name WeaponData
extends Resource
## Environmental weapon tunables (GAME_DESIGN.md §6): flat bonuses on top of
## the wielder's move data, with limited durability.

@export var weapon_name: StringName = &"bat"
@export var display_name: String = "BAT"
@export var damage_bonus: float = 6.0
@export var knockback_bonus: float = 1.5
## Number of landed hits before the weapon breaks.
@export var durability: int = 8
