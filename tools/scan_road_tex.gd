@tool
extends SceneTree

func _init():
	var img = Image.load_from_file("res://assets/models/roads/Road1_B_dotted_white.png")
	if img:
		print("Scanning row Y=256 across X (0 to 511):")
		var prev_val = -1.0
		for x in range(0, 512, 8):
			var col = img.get_pixel(x, 256)
			var brightness = (col.r + col.g + col.b) / 3.0
			if abs(brightness - prev_val) > 0.05 or x % 64 == 0:
				print(" X=", x, " col=", col, " b=", brightness)
				prev_val = brightness
	quit(0)

