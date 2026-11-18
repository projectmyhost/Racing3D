@tool
extends SceneTree

func _init():
	var angles = ["m35", "p35", "m60", "m15"]
	for a in angles:
		var path = "docs/validation/car_angle_" + a + ".png"
		var img = Image.load_from_file(path)
		if not img:
			continue
		var red_count = 0
		var min_x = 9999
		var max_x = 0
		var min_y = 9999
		var max_y = 0
		for y in range(400, 850):
			for x in range(600, 1800):
				var c = img.get_pixel(x, y)
				if c.r > 0.6 and c.g < 0.35 and c.b < 0.35:
					red_count += 1
					min_x = mini(min_x, x)
					max_x = maxi(max_x, x)
					min_y = mini(min_y, y)
					max_y = maxi(max_y, y)
		print("Angle ", a, " -> Red pixels: ", red_count, " bbox: [", min_x, ",", min_y, " to ", max_x, ",", max_y, "] width=", max_x - min_x, " height=", max_y - min_y)
	quit(0)

