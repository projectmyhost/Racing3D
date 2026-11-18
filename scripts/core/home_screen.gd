class_name HomeScreen
extends Node3D

## Root scene controller for Sunset Street Racing Home Screen.

func _ready() -> void:
	var sun = get_node_or_null("SunLight") as DirectionalLight3D
	if sun:
		sun.light_energy = 0.55
		sun.light_specular = 0.05
		sun.shadow_bias = 0.03

	var ui = get_node_or_null("UILayer/HomeScreenUI")
	var car = get_node_or_null("ShowcaseCar")
	if ui and car:
		if ui.has_signal("paint_color_selected") and car.has_method("set_paint_color"):
			ui.paint_color_selected.connect(car.set_paint_color)
		if ui.has_signal("car_equipped") and car.has_method("load_car_model"):
			ui.car_equipped.connect(func(cid: String):
				car.load_car_model(cid)
			)
			
	# Initialize car model from player profile if available
	if has_node("/root/PlayerProfile") and car and car.has_method("load_car_model"):
		var prof = get_node("/root/PlayerProfile")
		var p = prof.get("data")
		if p and p.get("equipped_car"):
			var eq = p.get("equipped_car")
			car.load_car_model(eq)
			if p.get("custom_paint_color") and car.has_method("set_paint_color"):
				car.set_paint_color(p.get("custom_paint_color"))
		
	# Optional capture check or initialization
	if OS.has_feature("capture"):
		_schedule_capture()

func _schedule_capture() -> void:
	await get_tree().create_timer(1.8).timeout
	var vp = get_viewport()
	var img = vp.get_texture().get_image()
	if img and not img.is_empty():
		if img.get_size() != Vector2i(1920, 1080):
			img.resize(1920, 1080, Image.INTERPOLATE_LANCZOS)
		img.save_png("docs/validation/home_rb22_latest.png")
		print("SUCCESS: Saved validation screenshot to docs/validation/home_rb22_latest.png")
	get_tree().quit(0)
