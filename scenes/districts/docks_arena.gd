extends Node3D
## The Docks district (vertical slice): DistrictData-driven waves → bruisers
## → gang leader, with pickups, flash rewards, crew revive, and win/lose flow.
## All spawning/timing runs on the 60 Hz tick.

const HIT_SPARK_SCENE := preload("res://scenes/vfx/hit_spark.tscn")
const SPARK_POOL_SIZE := 8
## Ticks of breather between cleared wave and the next one.
const WAVE_DELAY_TICKS := 120
const BOSS_TITLE := "WHARF RAT KING"

@export var district: DistrictData
@export var fodder_scene: PackedScene
@export var bruiser_scene: PackedScene
@export var boss_scene: PackedScene
@export var weapon_pickup_scene: PackedScene
@export var health_pickup_scene: PackedScene

var wave: int = 0
var flash_earned: int = 0

var _alive: int = 0
var _next_wave_countdown: int = -1
var _boss_spawned: bool = false
var _game_over: bool = false
var _sparks: Array[CPUParticles3D] = []
var _next_spark: int = 0
var _pickup_cycle: int = 0

@onready var player: Combatant = $Player
@onready var ally: Combatant = $Ally
@onready var hud: CanvasLayer = $HUD
@onready var end_screen: CanvasLayer = $EndScreen
@onready var spawn_points: Array[Node] = $SpawnPoints.get_children()


func _ready() -> void:
	hud.bind_player(player)
	hud.set_flash(0)
	player.downed.connect(_on_player_downed)
	EventBus.hit_landed.connect(_on_hit_landed)
	EventBus.crew_command_changed.emit(&"mob")
	for i: int in SPARK_POOL_SIZE:
		var spark: CPUParticles3D = HIT_SPARK_SCENE.instantiate()
		add_child(spark)
		_sparks.append(spark)
	_spawn_wave()


func _physics_process(_delta: float) -> void:
	if _game_over:
		return
	if _next_wave_countdown > 0:
		_next_wave_countdown -= 1
		if _next_wave_countdown == 0:
			_spawn_wave()


func _total_waves() -> int:
	return district.wave_fodder.size()


func _spawn_wave() -> void:
	wave += 1
	hud.set_wave(wave, _total_waves())
	hud.hide_message()
	if wave > _total_waves():
		_spawn_boss_wave()
		return
	var fodder_count: int = district.wave_fodder[wave - 1]
	var bruiser_count: int = 0
	if wave - 1 < district.wave_bruisers.size():
		bruiser_count = district.wave_bruisers[wave - 1]
	for i: int in fodder_count:
		_spawn_enemy(fodder_scene, i, fodder_count)
	for i: int in bruiser_count:
		_spawn_enemy(bruiser_scene, i + fodder_count, fodder_count + bruiser_count)
	_alive = fodder_count + bruiser_count
	if district.weapon_every_n_waves > 0 and wave % district.weapon_every_n_waves == 0:
		_spawn_pickup(weapon_pickup_scene)
	_emit_intensity()


func _spawn_boss_wave() -> void:
	_boss_spawned = true
	hud.show_message("THE KING IS HERE")
	var boss: Combatant = boss_scene.instantiate()
	boss.position = _spawn_position(0, 1) + Vector3(0, 0, 4)
	# Order matters: award the boss's flash before _on_boss_downed banks it.
	boss.downed.connect(_on_enemy_downed.bind(boss))
	boss.downed.connect(_on_boss_downed)
	add_child(boss)
	hud.bind_boss(boss, BOSS_TITLE)
	for i: int in district.boss_extra_fodder:
		_spawn_enemy(fodder_scene, i, district.boss_extra_fodder)
	_alive = 1 + district.boss_extra_fodder
	EventBus.combat_intensity_changed.emit(1.0)


func _spawn_enemy(scene: PackedScene, index: int, count: int) -> void:
	var enemy: Combatant = scene.instantiate()
	enemy.position = _spawn_position(index, count)
	enemy.downed.connect(_on_enemy_downed.bind(enemy))
	add_child(enemy)


func _spawn_position(index: int, count: int) -> Vector3:
	var point: Node3D = spawn_points[index % spawn_points.size()]
	# Deterministic ring offset so stacked spawns don't overlap.
	var angle := TAU * float(index) / float(maxi(count, 1))
	return point.position + Vector3(1.2, 0.0, 0.0).rotated(Vector3.UP, angle)


func _spawn_pickup(scene: PackedScene) -> void:
	var pickup: Node3D = scene.instantiate()
	# Rotate through arena-center-ish drop spots, deterministically.
	_pickup_cycle += 1
	var angle := TAU * float(_pickup_cycle % 6) / 6.0
	pickup.position = Vector3(5.0, 0.4, 0.0).rotated(Vector3.UP, angle)
	add_child(pickup)


func _on_enemy_downed(enemy: Combatant) -> void:
	_alive -= 1
	var enemy_data := enemy.data as EnemyData
	if enemy_data != null:
		flash_earned += enemy_data.flash_reward
		hud.set_flash(flash_earned)
	_emit_intensity()
	if _alive <= 0 and not _game_over and not _boss_spawned:
		_on_wave_cleared()


func _on_wave_cleared() -> void:
	hud.show_message("WAVE CLEAR")
	ally.revive(0.6)
	if district.heal_every_wave:
		_spawn_pickup(health_pickup_scene)
	_next_wave_countdown = WAVE_DELAY_TICKS


func _on_boss_downed() -> void:
	if _game_over:
		return
	_game_over = true
	hud.hide_boss()
	_bank_flash()
	end_screen.show_victory(flash_earned)


func _on_player_downed() -> void:
	if _game_over:
		return
	_game_over = true
	_bank_flash()
	end_screen.show_defeat(flash_earned)


## Earned flash persists win or lose — the night goes on (M5 economy stub).
func _bank_flash() -> void:
	var save := SaveManager.load_game()
	save["flash"] = int(save["flash"]) + flash_earned
	SaveManager.save_game(save)


func _emit_intensity() -> void:
	EventBus.combat_intensity_changed.emit(clampf(float(_alive) / 8.0, 0.0, 1.0))


func _on_hit_landed(_attacker: Node, target: Node, damage: float) -> void:
	if damage <= 0.0 or target is not Node3D:
		return
	var spark := _sparks[_next_spark]
	_next_spark = (_next_spark + 1) % _sparks.size()
	spark.global_position = (target as Node3D).global_position + Vector3.UP * 1.1
	spark.restart()
