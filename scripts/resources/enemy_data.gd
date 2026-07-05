class_name EnemyData
extends CombatantData
## Enemy-only tunables layered on top of the shared combatant data.

@export_group("AI")
## Distance at which the enemy notices and pursues the player, in m.
@export var aggro_range: float = 14.0
## Distance at which the enemy commits to an attack, in m.
@export var attack_range: float = 1.6
## Minimum ticks between attack attempts.
@export var attack_cooldown_ticks: int = 45
## Preferred spacing from other enemies (separation steering), in m.
@export var separation_radius: float = 1.2
## Flash (currency) awarded when this enemy is KO'd.
@export var flash_reward: int = 5
