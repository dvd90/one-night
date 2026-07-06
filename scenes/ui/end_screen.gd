extends CanvasLayer
## Victory / defeat overlay with retry and back-to-title.

const TITLE_SCENE := "res://scenes/ui/title.tscn"

@onready var heading: Label = $Panel/Rows/Heading
@onready var subtext: Label = $Panel/Rows/Subtext
@onready var retry_button: Button = $Panel/Rows/RetryButton
@onready var title_button: Button = $Panel/Rows/TitleButton


func _ready() -> void:
	visible = false
	retry_button.pressed.connect(_on_retry)
	title_button.pressed.connect(_on_title)


func show_victory(flash: int) -> void:
	heading.text = "DOCKS CLEARED"
	subtext.text = (
		"The Wharf Rats are done. +%d flash banked.\nFive districts to go. To be continued…"
		% flash
	)
	retry_button.text = "RUN IT BACK"
	visible = true


func show_defeat(flash: int) -> void:
	heading.text = "YOU'RE DOWN"
	subtext.text = "The night isn't over. +%d flash banked." % flash
	retry_button.text = "RETRY"
	visible = true


func _on_retry() -> void:
	get_tree().reload_current_scene()


func _on_title() -> void:
	Game.change_state(Game.State.MENU)
	var err := get_tree().change_scene_to_file(TITLE_SCENE)
	if err != OK:
		push_error("Failed to load title scene (error %d)" % err)
