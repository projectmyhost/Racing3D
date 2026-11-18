extends SceneTree

func _init() -> void:
	var scn = load("res://scenes/main/home_screen.tscn").instantiate()
	root.add_child(scn)
	
	create_timer(0.05).timeout.connect(func():
		var cam: Camera3D = scn.get_node("CameraRig/ShowcaseCamera")
		
		print("--- BILLBOARD HEIGHT ON SCREEN ---")
		for y_top in [5.5, 6.5, 7.5, 8.5]:
			for y_bot in [2.5, 3.5, 4.0]:
				if y_top > y_bot:
					var pt_top = cam.unproject_position(Vector3(3.5, y_top, 12.0))
					var pt_bot = cam.unproject_position(Vector3(3.5, y_bot, 12.0))
					print("y_bot=", y_bot, " y_top=", y_top, " -> Screen Y: bot=", int(pt_bot.y), " top=", int(pt_top.y), " height=", int(pt_bot.y - pt_top.y))
					
		quit(0)
	)
