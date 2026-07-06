extends CanvasLayer
## Combat HUD: player health, flash, weapon durability, wave, crew command,
## boss health, and a center message line.

@onready var health_bar: ProgressBar = $HealthBar
@onready var flash_label: Label = $FlashLabel
@onready var weapon_label: Label = $WeaponLabel
@onready var wave_label: Label = $WaveLabel
@onready var command_label: Label = $CommandLabel
@onready var boss_bar: ProgressBar = $BossBar
@onready var boss_name_label: Label = $BossBar/BossName
@onready var message_label: Label = $Message


func _ready() -> void:
	EventBus.crew_command_changed.connect(_on_command_changed)


func bind_player(player: Combatant) -> void:
	health_bar.max_value = player.data.max_health
	health_bar.value = player.health
	player.health_changed.connect(_on_player_health_changed)
	player.weapon_changed.connect(_on_player_weapon_changed)


func bind_boss(boss: Combatant, boss_title: String) -> void:
	boss_bar.max_value = boss.data.max_health
	boss_bar.value = boss.health
	boss_name_label.text = boss_title
	boss_bar.visible = true
	boss.health_changed.connect(_on_boss_health_changed)


func hide_boss() -> void:
	boss_bar.visible = false


func set_flash(total: int) -> void:
	flash_label.text = "FLASH %d" % total


func set_wave(wave: int, total_waves: int) -> void:
	if wave > total_waves:
		wave_label.text = "BOSS"
	else:
		wave_label.text = "WAVE %d/%d" % [wave, total_waves]


func show_message(text: String) -> void:
	message_label.text = text
	message_label.visible = true


func hide_message() -> void:
	message_label.visible = false


func _on_player_health_changed(current: float, _maximum: float) -> void:
	health_bar.value = current


func _on_player_weapon_changed(weapon: WeaponData, hits_left: int) -> void:
	if weapon == null:
		weapon_label.text = ""
	else:
		weapon_label.text = "%s ×%d" % [weapon.display_name, hits_left]


func _on_boss_health_changed(current: float, _maximum: float) -> void:
	boss_bar.value = current
	if current <= 0.0:
		boss_bar.visible = false


func _on_command_changed(command: StringName) -> void:
	command_label.text = "CREW: %s" % String(command).to_upper()
