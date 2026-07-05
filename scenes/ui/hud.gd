extends CanvasLayer
## Minimal combat HUD: health bar, wave counter, center message.

@onready var health_bar: ProgressBar = $HealthBar
@onready var wave_label: Label = $WaveLabel
@onready var message_label: Label = $Message


func bind_player(player: Combatant) -> void:
	health_bar.max_value = player.data.max_health
	health_bar.value = player.health
	player.health_changed.connect(_on_player_health_changed)


func set_wave(wave: int) -> void:
	wave_label.text = "WAVE %d" % wave


func show_message(text: String) -> void:
	message_label.text = text
	message_label.visible = true


func hide_message() -> void:
	message_label.visible = false


func _on_player_health_changed(current: float, _maximum: float) -> void:
	health_bar.value = current
