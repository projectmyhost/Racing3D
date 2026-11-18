@tool
extends SceneTree

func _init():
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	root.size = Vector2i(1920, 1080)
	
	# Load and attach PlayerProfile autoload so homescreen has player state
	var prof_script = load("res://scripts/core/player_profile.gd")
	if prof_script:
		var prof_node = Node.new()
		prof_node.set_script(prof_script)
		prof_node.name = "PlayerProfile"
		root.add_child(prof_node)
	
	var scene = load("res://scenes/main/home_screen.tscn").instantiate()
	root.add_child(scene)
	
	# Wait several frames to let layout, model, and textures load completely
	for i in range(35):
		await process_frame
		
	var img = root.get_viewport().get_texture().get_image()
	if img.get_size() != Vector2i(1920, 1080):
		img.resize(1920, 1080, Image.INTERPOLATE_LANCZOS)
	img.save_png("docs/validation/current_homescreen.png")
	print("Homescreen screenshot saved (%dx%d) to docs/validation/current_homescreen.png" % [img.get_width(), img.get_height()])
	quit(0)

