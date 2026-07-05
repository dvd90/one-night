extends CanvasLayer
## Shows the touch layer only on devices that can actually use it.


func _ready() -> void:
	visible = DisplayServer.is_touchscreen_available()
