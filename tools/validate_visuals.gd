extends SceneTree

var _capture_timer: float = 0.0
var _captured: bool = false

func _init():
	print("Starting Visual Validation Runner...")
	change_scene_to_file("res://scenes/main/home_screen.tscn")

func _process(delta: float) -> bool:
	_capture_timer += delta
	if _capture_timer >= 2.5 and not _captured:
		_captured = true
		_perform_capture()
		return true
	return false

func _perform_capture():
	print("Capturing 1920x1080 validation screenshot...")
	var vp = root.get_viewport()
	var img = vp.get_texture().get_image()
	if img == null or img.is_empty():
		print("ERROR: Viewport texture image is empty!")
		quit(1)
		return
		
	if img.get_size() != Vector2i(1920, 1080):
		img.resize(1920, 1080, Image.INTERPOLATE_LANCZOS)
		
	var timestamp = "20261111_2255"
	var out_capture_path = "docs/validation/home_" + timestamp + ".png"
	img.save_png(out_capture_path)
	print("Saved screenshot to ", out_capture_path)
	
	# Load reference image
	var ref_file = FileAccess.open("docs/reference/home_screen_reference.png", FileAccess.READ)
	if ref_file:
		var ref_bytes = ref_file.get_buffer(ref_file.get_length())
		var ref_img = Image.new()
		ref_img.load_png_from_buffer(ref_bytes)
		if ref_img.get_size() != Vector2i(1920, 1080):
			ref_img.resize(1920, 1080, Image.INTERPOLATE_LANCZOS)
			
		# Generate 50% overlay
		var overlay_img = Image.create(1920, 1080, false, Image.FORMAT_RGBA8)
		for y in range(1080):
			for x in range(1920):
				var c1 = img.get_pixel(x, y)
				var c2 = ref_img.get_pixel(x, y)
				overlay_img.set_pixel(x, y, c1.lerp(c2, 0.5))
		overlay_img.save_png("docs/validation/home_overlay_50.png")
		print("Saved docs/validation/home_overlay_50.png")
		
		# Generate side-by-side comparison (3840x1080)
		var comp_img = Image.create(3840, 1080, false, Image.FORMAT_RGBA8)
		comp_img.blit_rect(img, Rect2i(0, 0, 1920, 1080), Vector2i(0, 0))
		comp_img.blit_rect(ref_img, Rect2i(0, 0, 1920, 1080), Vector2i(1920, 0))
		comp_img.save_png("docs/validation/home_comparison.png")
		print("Saved docs/validation/home_comparison.png")
		
	print("Visual validation capture finished successfully!")
	quit(0)
