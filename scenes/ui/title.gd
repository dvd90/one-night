extends Control
## Title screen: play, PS1/screenshake toggles, banked flash, quit (desktop).

const ARENA_SCENE := "res://scenes/districts/docks_arena.tscn"

@onready var play_button: Button = $Rows/PlayButton
@onready var quit_button: Button = $Rows/QuitButton
@onready var flash_label: Label = $Rows/FlashLabel
@onready var snap_toggle: CheckButton = $Rows/SnapToggle
@onready var affine_toggle: CheckButton = $Rows/AffineToggle
@onready var shake_toggle: CheckButton = $Rows/ShakeToggle


func _ready() -> void:
	Game.change_state(Game.State.MENU)
	play_button.pressed.connect(_on_play)
	quit_button.pressed.connect(_on_quit)
	quit_button.visible = not OS.has_feature("web")
	flash_label.text = "FLASH BANKED: %d" % int(SaveManager.load_game()["flash"])
	snap_toggle.button_pressed = bool(Config.get_setting(&"ps1/vertex_snap"))
	affine_toggle.button_pressed = bool(Config.get_setting(&"ps1/affine_mapping"))
	shake_toggle.button_pressed = bool(Config.get_setting(&"camera/screenshake"))
	snap_toggle.toggled.connect(
		func(on: bool) -> void: Config.set_setting(&"ps1/vertex_snap", on)
	)
	affine_toggle.toggled.connect(
		func(on: bool) -> void: Config.set_setting(&"ps1/affine_mapping", on)
	)
	shake_toggle.toggled.connect(
		func(on: bool) -> void: Config.set_setting(&"camera/screenshake", on)
	)
	play_button.grab_focus()


func _on_play() -> void:
	Game.change_state(Game.State.DISTRICT)
	var err := get_tree().change_scene_to_file(ARENA_SCENE)
	if err != OK:
		push_error("Failed to load arena scene (error %d)" % err)


func _on_quit() -> void:
	get_tree().quit()
