@tool
extends SceneTree

# Inspect project settings for physics and rendering

func _init() -> void:
	print("--- PROJECT SETTINGS AUDIT ---")
	print("physics/common/physics_ticks_per_second = ", ProjectSettings.get_setting("physics/common/physics_ticks_per_second"))
	print("physics/common/max_physics_steps_per_frame = ", ProjectSettings.get_setting("physics/common/max_physics_steps_per_frame"))
	print("physics/common/physics_interpolation = ", ProjectSettings.get_setting("physics/common/physics_interpolation"))
	print("physics/3d/physics_engine = ", ProjectSettings.get_setting("physics/3d/physics_engine"))
	print("physics/3d/default_gravity = ", ProjectSettings.get_setting("physics/3d/default_gravity"))
	print("physics/3d/default_gravity_vector = ", ProjectSettings.get_setting("physics/3d/default_gravity_vector"))
	print("rendering/renderer/rendering_method = ", ProjectSettings.get_setting("rendering/renderer/rendering_method"))
	quit(0)

