extends Node

signal scene_changed(new_scene_path: String)

const HOME_SCENE: String = "res://scenes/home/HomeScreen.tscn"

var scene_stack: Array[String] = []
var _active_modals: Array[Node] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if _active_modals.size() > 0:
			var top_modal = _active_modals.back()
			if is_instance_valid(top_modal):
				if top_modal.has_method("on_cancel_pressed"):
					top_modal.on_cancel_pressed()
				elif top_modal.has_method("close"):
					top_modal.close()
				elif top_modal.has_method("dismiss"):
					top_modal.dismiss()
				else:
					unregister_modal(top_modal)
					top_modal.queue_free()
			get_viewport().set_input_as_handled()
			return
		
		# If no modal open, check if we can pop scene
		if scene_stack.size() > 0:
			pop_scene()
			get_viewport().set_input_as_handled()

func register_modal(modal: Node) -> void:
	if not (_active_modals.has(modal)):
		_active_modals.append(modal)

func unregister_modal(modal: Node) -> void:
	_active_modals.erase(modal)

func has_active_modals() -> bool:
	# Clean invalid references
	_active_modals = _active_modals.filter(func(m): return is_instance_valid(m))
	return _active_modals.size() > 0

func change_scene(scene_path: String) -> void:
	_active_modals.clear()
	var err = get_tree().change_scene_to_file(scene_path)
	if err == OK:
		emit_signal("scene_changed", scene_path)
	else:
		push_warning("Failed to change scene to %s with error %d" % [scene_path, err])

func push_scene(scene_path: String) -> void:
	var current = get_tree().current_scene
	if current and current.scene_file_path != "":
		scene_stack.append(current.scene_file_path)
	change_scene(scene_path)

func pop_scene() -> void:
	if scene_stack.size() > 0:
		var prev = scene_stack.pop_back()
		change_scene(prev)
	else:
		go_home()

func go_home() -> void:
	scene_stack.clear()
	change_scene(HOME_SCENE)
