@tool
extends SceneTree

var timer: float = 0.0
var step: int = 0
var current_node: Node = null

func _init():
	print("Starting SceneTree screenshot capture...")
	DirAccess.make_dir_recursive_absolute("res://docs/validation")
	
	# Load HomeScreen
	var hs_packed = load("res://scenes/main/home_screen.tscn") as PackedScene
	current_node = hs_packed.instantiate()
	get_root().add_child(current_node)
	process_frame.connect(_on_frame)

func _on_frame():
	var delta = 1.0 / 60.0
	timer += delta
	if step == 0 and timer >= 1.0:
		step = 1
		var vp = get_root().get_viewport()
		var img = vp.get_texture().get_image()
		img.save_png("docs/validation/homescreen_new_profile_card.png")
		print("Saved docs/validation/homescreen_new_profile_card.png")
		
		# Free homescreen and load race track
		current_node.queue_free()
		var rt_packed = load("res://scenes/race/RaceTrack3D.tscn") as PackedScene
		current_node = rt_packed.instantiate()
		get_root().add_child(current_node)
		timer = 0.0
		
	elif step == 1 and timer >= 1.0:
		step = 2
		var vp = get_root().get_viewport()
		var img = vp.get_texture().get_image()
		img.save_png("docs/validation/race_track_driving.png")
		print("Saved docs/validation/race_track_driving.png")
		
		# Trigger Victory finish
		var track = current_node as RaceTrack3D
		if track:
			track.total_race_time = 41.5
			track.best_lap_time = 13.8
			track._finish_race()
		timer = 0.0
		
	elif step == 2 and timer >= 0.5:
		var vp = get_root().get_viewport()
		var img = vp.get_texture().get_image()
		img.save_png("docs/validation/race_victory_stars_xp.png")
		print("Saved docs/validation/race_victory_stars_xp.png")
		print("ALL SCREENSHOTS CAPTURED SUCCESSFULLY!")
		quit(0)
