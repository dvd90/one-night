extends Node3D
## The Docks arena: an endless-wave brawl to exercise M1+M2 (combat feel
## first — GAME_DESIGN.md pillars). Owns wave spawning, the hit-spark pool,
## combat intensity, and the lose/retry loop.

const HIT_SPARK_SCENE := preload("res://scenes/vfx/hit_spark.tscn")
const SPARK_POOL_SIZE := 8
## Ticks (60 Hz) between the player going down and the retry reload.
const RESTART_DELAY_TICKS := 150
## Ticks of breather between cleared wave and the next one.
const WAVE_DELAY_TICKS := 90

@export var fodder_scene: PackedScene
@export var base_wave_size: int = 3
@export var max_wave_size: int = 8

var wave: int = 0
var _alive: int = 0
var _restart_countdown: int = -1
var _next_wave_countdown: int = -1
var _sparks: Array[CPUParticles3D] = []
var _next_spark: int = 0

@onready var player: Combatant = $Player
@onready var hud: CanvasLayer = $HUD
@onready var spawn_points: Array[Node] = $SpawnPoints.get_children()


func _ready() -> void:
	hud.bind_player(player)
	player.downed.connect(_on_player_downed)
	EventBus.hit_landed.connect(_on_hit_landed)
	for i: int in SPARK_POOL_SIZE:
		var spark: CPUParticles3D = HIT_SPARK_SCENE.instantiate()
		add_child(spark)
		_sparks.append(spark)
	_spawn_wave()


func _physics_process(_delta: float) -> void:
	if _restart_countdown > 0:
		_restart_countdown -= 1
		if _restart_countdown == 0:
			get_tree().reload_current_scene()
	if _next_wave_countdown > 0:
		_next_wave_countdown -= 1
		if _next_wave_countdown == 0:
			_spawn_wave()


func _spawn_wave() -> void:
	wave += 1
	hud.set_wave(wave)
	hud.hide_message()
	var count := mini(base_wave_size + wave - 1, max_wave_size)
	for i: int in count:
		var fodder: Combatant = fodder_scene.instantiate()
		var point: Node3D = spawn_points[i % spawn_points.size()]
		# Deterministic ring offset so stacked spawns don't overlap.
		var offset := Vector3(1.2, 0.0, 0.0).rotated(Vector3.UP, TAU * float(i) / float(count))
		fodder.position = point.position + offset
		fodder.downed.connect(_on_enemy_downed)
		add_child(fodder)
	_alive = count
	EventBus.combat_intensity_changed.emit(clampf(float(_alive) / float(max_wave_size), 0.0, 1.0))


func _on_enemy_downed() -> void:
	_alive -= 1
	EventBus.combat_intensity_changed.emit(clampf(float(_alive) / float(max_wave_size), 0.0, 1.0))
	if _alive <= 0 and _restart_countdown < 0:
		hud.show_message("WAVE CLEAR")
		_next_wave_countdown = WAVE_DELAY_TICKS


func _on_player_downed() -> void:
	hud.show_message("YOU'RE DOWN")
	_restart_countdown = RESTART_DELAY_TICKS


func _on_hit_landed(_attacker: Node, target: Node, damage: float) -> void:
	if damage <= 0.0 or target is not Node3D:
		return
	var spark := _sparks[_next_spark]
	_next_spark = (_next_spark + 1) % _sparks.size()
	spark.global_position = (target as Node3D).global_position + Vector3.UP * 1.1
	spark.restart()
