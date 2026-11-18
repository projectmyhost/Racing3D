@tool
extends SceneTree

func _init():
	var img = Image.load_from_file("docs/validation/reference_1080p.png")
	if not img:
		quit(1)
		
	# 1. Event banner image: inside Limited Time Event card
	# Event card is approximately x: 1530 to 1888, y: 210 to 550
	# The inner banner graphic is between the gold header and the title NIGHT SPEEDRUN
	var event_rect = Rect2i(1536, 256, 344, 130)
	var event_crop = img.get_region(event_rect)
	event_crop.save_png("assets/ui/textures/event_night_speedrun.png")
	print("Saved event_night_speedrun.png")

	# 2. Season pass car thumbnail
	# Season pass card is at bottom right, approximately x: 1650 to 1800, y: 925 to 1010
	var season_car_rect = Rect2i(1650, 928, 145, 84)
	var season_car_crop = img.get_region(season_car_rect)
	season_car_crop.save_png("assets/ui/textures/season_pass_car.png")
	print("Saved season_pass_car.png")

	# 3. Friend avatar 1
	var f1_rect = Rect2i(1548, 638, 64, 64)
	var f1_crop = img.get_region(f1_rect)
	f1_crop.save_png("assets/ui/icons/avatar_friend_1.png")
	print("Saved avatar_friend_1.png")

	# 4. Friend avatar 2
	var f2_rect = Rect2i(1548, 718, 64, 64)
	var f2_crop = img.get_region(f2_rect)
	f2_crop.save_png("assets/ui/icons/avatar_friend_2.png")
	print("Saved avatar_friend_2.png")

	quit(0)

