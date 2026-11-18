extends Node

var _canvas_layer: CanvasLayer
var _toast_scene: PackedScene = preload("res://scenes/common/Toast.tscn")
var _current_toast: Node = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_canvas_layer = CanvasLayer.new()
	_canvas_layer.layer = 100
	add_child(_canvas_layer)

func show_toast(message: String, duration: float = 2.5, icon: String = "[!]") -> void:
	if is_instance_valid(_current_toast):
		_current_toast.queue_free()
		_current_toast = null

	var toast_instance = _toast_scene.instantiate()
	_canvas_layer.add_child(toast_instance)
	_current_toast = toast_instance
	
	if toast_instance.has_method("setup"):
		toast_instance.setup(message, duration, icon)

func show_success(message: String, duration: float = 2.5) -> void:
	show_toast(message, duration, "[OK]")

func show_warning(message: String, duration: float = 2.5) -> void:
	show_toast(message, duration, "[WARN]")

func show_error(message: String, duration: float = 2.5) -> void:
	show_toast(message, duration, "[X]")
