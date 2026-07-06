extends CanvasLayer
## Pause menu: resume/restart/quit + the PS1 & screenshake toggles
## (accessibility hard rule). Runs while the tree is paused.

const TITLE_SCENE := "res://scenes/ui/title.tscn"

@onready var resume_button: Button = $Panel/Rows/ResumeButton
@onready var restart_button: Button = $Panel/Rows/RestartButton
@onready var title_button: Button = $Panel/Rows/TitleButton
@onready var snap_toggle: CheckButton = $Panel/Rows/SnapToggle
@onready var affine_toggle: CheckButton = $Panel/Rows/AffineToggle
@onready var shake_toggle: CheckButton = $Panel/Rows/ShakeToggle


func _ready() -> void:
	visible = false
	resume_button.pressed.connect(close)
	restart_button.pressed.connect(_on_restart)
	title_button.pressed.connect(_on_title)
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


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause"):
		toggle()
		get_viewport().set_input_as_handled()


func toggle() -> void:
	if visible:
		close()
	else:
		open()


func open() -> void:
	visible = true
	get_tree().paused = true


func close() -> void:
	visible = false
	get_tree().paused = false


func _on_restart() -> void:
	close()
	get_tree().reload_current_scene()


func _on_title() -> void:
	close()
	Game.change_state(Game.State.MENU)
	var err := get_tree().change_scene_to_file(TITLE_SCENE)
	if err != OK:
		push_error("Failed to load title scene (error %d)" % err)
