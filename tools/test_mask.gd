@tool
extends SceneTree

func _init():
	var img = Image.load_from_file("assets/ui/textures/btn_play_ref.png")
	if not img: quit(1)
	
	img.convert(Image.FORMAT_RGBA8)
	var w = img.get_width()
	var h = img.get_height()
	
	# Parallelogram bounds
	# In btn_play_ref.png:
	# Top left starts around x=32 at y=16 (or y=20)
	# Let's inspect where the yellow border is
	print("Size:", w, "x", h)
	quit(0)

