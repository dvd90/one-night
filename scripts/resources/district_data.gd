class_name DistrictData
extends Resource
## One district's encounter script (ARCHITECTURE.md §4): wave composition,
## boss support, and pickup cadence. The arena reads this; it hardcodes nothing.

@export var district_name: StringName = &"docks"
@export var display_name: String = "THE DOCKS"
## Fodder count per wave; the boss wave comes after the last entry.
@export var wave_fodder: Array[int] = [3, 4, 5, 6]
## Bruiser count per wave (same indexing as wave_fodder).
@export var wave_bruisers: Array[int] = [0, 0, 1, 2]
## Fodder that accompany the boss.
@export var boss_extra_fodder: int = 2
## Spawn a health pickup after every cleared wave.
@export var heal_every_wave: bool = true
## Spawn a weapon pickup at the start of every Nth wave (0 = never).
@export var weapon_every_n_waves: int = 2
