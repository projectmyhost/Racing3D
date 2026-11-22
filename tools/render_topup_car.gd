extends SceneTree

## One-shot 3D studio render tool: renders our in-game McLaren Artura Spider
## painted glossy metallic crimson red onto a transparent RGBA PNG for the
## TOP UP NOW! promotional banner. 100% original in-engine render (zero cropping).

func _initialize() -> void:
	call_deferred("_run_render")

func _run_render() -> void:
	var host := Node.new()
	root.add_child(host)

	var vp := SubViewport.new()
	vp.size = Vector2i(760, 440)
	vp.transparent_bg = true
	vp.msaa_3d = Viewport.MSAA_8X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.own_world_3d = true
	host.add_child(vp)

	# WorldEnvironment with transparent clear color + warm sunset sky reflections
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.18, 0.24, 0.42)
	sky_mat.sky_horizon_color = Color(0.98, 0.72, 0.44)
	sky_mat.ground_bottom_color = Color(0.08, 0.07, 0.08)
	sky_mat.ground_horizon_color = Color(0.32, 0.24, 0.20)
	sky_mat.sun_angle_max = 0.0
	sky_mat.sun_curve = 0.05
	sky.sky_material = sky_mat
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.55
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.04
	env.glow_enabled = false
	we.environment = env
	vp.add_child(we)

	# Studio lights for rich deep crimson metallic clearcoat highlights
	var key := DirectionalLight3D.new()
	key.light_color = Color(1.0, 0.90, 0.76)
	key.light_energy = 2.45
	key.rotation_degrees = Vector3(-26.0, -34.0, 0.0)
	key.shadow_enabled = true
	vp.add_child(key)

	var rim := DirectionalLight3D.new()
	rim.light_color = Color(1.0, 0.76, 0.45)
	rim.light_energy = 1.95
	rim.rotation_degrees = Vector3(-14.0, 148.0, 0.0)
	vp.add_child(rim)

	var fill := DirectionalLight3D.new()
	fill.light_color = Color(0.80, 0.88, 1.0)
	fill.light_energy = 0.45
	fill.rotation_degrees = Vector3(-42.0, 65.0, 0.0)
	vp.add_child(fill)

	# Load ShowcaseCar -> McLaren painted deep glossy metallic crimson red
	var car_scene: PackedScene = load("res://scenes/vehicles/showcase_car.tscn")
	var car := car_scene.instantiate()
	vp.add_child(car)
	car.load_car_model("mclaren")
	car.set_paint_color(Color(0.54, 0.025, 0.045, 1.0))

	# Hide ground contact shadow quad so transparent PNG edge stays clean
	for child in car.get_children():
		if child.name.to_lower().contains("shadow"):
			child.visible = false
	for node in car.find_children("*Shadow*", "", true, false):
		if node is Node3D:
			node.visible = false

	if "steer_angle" in car:
		car.steer_angle = -0.22

	var cam := Camera3D.new()
	cam.fov = 26.0
	cam.near = 0.1
	cam.far = 100.0
	vp.add_child(cam)
	cam.make_current()

	RenderingServer.set_default_clear_color(Color(0.0, 0.0, 0.0, 0.0))

	for i in range(8):
		await process_frame

	var bounds := _compute_aabb(car)
	var center := bounds.get_center()
	var radius := bounds.size.length() * 0.5
	print("CAR_AABB center=", center, " size=", bounds.size)

	# Front-left 3/4 view matching the red supercar in TOP UP NOW! banner
	# ShowcaseCar faces +Z or -Z? Let's check: HeadlightSpotL is at z = -2.18, RearTaillightGlow at z = +2.38!
	# So front of car is -Z! Camera at (-X, +Y, -Z) sees the front-right corner (car pointing down-left on screen).
	# Wait: if car front is -Z, looking from (-X, +Y, -Z) toward (0,0,0):
	#   forward vec of cam is (+X, -Y, +Z) -> right of cam is cross(fwd, UP) = (-Z, 0, +X) -> -Z (front) points LEFT-DOWN!
	#   Wait: let's check vector cross product:
	#   fwd = (+0.72, 0, +0.88), UP = (0, 1, 0)
	#   right = fwd x UP = (0*0 - 0.88*1, 0, 0.72*1 - 0) = (-0.88, 0, +0.72)
	#   The nose is at (0, 0, -2.2): dot(nose, right) = -2.2 * 0.72 = -1.58 (LEFT side of screen!)
	#   And the right side of the car (+X) has dot((+1,0,0), right) = -0.88 (left) while (-X) side is visible on RIGHT!
	#   YES!! That matches the reference photo where the red car faces DOWN-LEFT and shows its front + driver-left side stretching toward the upper-right!!
	var cam_dir := Vector3(-0.71, 0.245, -0.89).normalized()
	var dist := radius * 2.42
	cam.position = center + cam_dir * dist
	cam.look_at(center + Vector3(0.0, -0.03 * bounds.size.y, 0.0), Vector3.UP)

	for i in range(10):
		await process_frame

	var img := vp.get_texture().get_image()
	if img and not img.is_empty():
		var cropped := _trim_transparent(img, 12)
		DirAccess.make_dir_recursive_absolute("res://assets/ui/textures")
		var out_path := "res://assets/ui/textures/topup_banner_car.png"
		var err := cropped.save_png(out_path)
		print("SAVED_CAR err=", err, " size=", cropped.get_size(), " path=", out_path)
	else:
		push_error("Failed to capture viewport image")

	quit(0)

func _compute_aabb(root_node: Node3D) -> AABB:
	var combined := AABB()
	var has_any := false
	for node in root_node.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		if not mi or not mi.visible or not mi.mesh:
			continue
		if mi.name.to_lower().contains("shadow"):
			continue
		var a := mi.global_transform * mi.mesh.get_aabb()
		if not has_any:
			combined = a
			has_any = true
		else:
			combined = combined.merge(a)
	return combined if has_any else AABB(Vector3(-1, 0, -2), Vector3(2, 1.2, 4))

func _trim_transparent(src: Image, pad: int) -> Image:
	var w := src.get_width()
	var h := src.get_height()
	var min_x := w
	var min_y := h
	var max_x := 0
	var max_y := 0
	for y in range(h):
		for x in range(w):
			if src.get_pixel(x, y).a > 0.02:
				if x < min_x: min_x = x
				if y < min_y: min_y = y
				if x > max_x: max_x = x
				if y > max_y: max_y = y
	if max_x <= min_x or max_y <= min_y:
		return src
	min_x = max(0, min_x - pad)
	min_y = max(0, min_y - pad)
	max_x = min(w - 1, max_x + pad)
	max_y = min(h - 1, max_y + pad)
	return src.get_region(Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1))
