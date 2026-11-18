@tool
extends SceneTree

func _init():
	var img = Image.load_from_file("docs/validation/reference_1080p.png")
	if not img: quit(1)
	
	# Notifications button: x: 1556, y: 100, w: 220, h: 44
	var notif = img.get_region(Rect2i(1556, 100, 220, 44))
	notif.save_png("assets/ui/textures/notifications_clean.png")

	# MS label: x: 1786, y: 118, w: 80, h: 32
	var ms = img.get_region(Rect2i(1786, 118, 80, 32))
	ms.save_png("assets/ui/textures/ms_clean.png")

	print("Saved notif and ms clean")
	quit(0)

