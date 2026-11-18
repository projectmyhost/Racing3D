@tool
extends SceneTree

func _init():
	var path = "C:/Users/Pongo/.gemini/antigravity/brain/1a795719-3155-4165-929d-bf2932498465/.user_uploaded/media_1794875373647_3122b9f2.jpg"
	var img = Image.load_from_file(path)
	if img:
		img.resize(1920, 1080, Image.INTERPOLATE_LANCZOS)
		img.save_png("docs/validation/reference_1080p.png")
		print("Saved docs/validation/reference_1080p.png at 1920x1080")
	quit(0)

