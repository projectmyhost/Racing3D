@tool
extends SceneTree

func _init():
	var img = Image.load_from_file("docs/validation/reference_1080p.png")
	if not img: quit(1)
	
	# Event night speedrun clean
	var event_rect = Rect2i(1536, 240, 344, 120)
	var event_crop = img.get_region(event_rect)
	event_crop.save_png("assets/ui/textures/event_night_speedrun.png")

	# Season pass car clean
	var season_car_rect = Rect2i(1656, 928, 136, 78)
	var season_car_crop = img.get_region(season_car_rect)
	season_car_crop.save_png("assets/ui/textures/season_pass_car.png")

	# Amateur tier badge
	var tier_rect = Rect2i(150, 160, 220, 50)
	var tier_crop = img.get_region(tier_rect)
	tier_crop.save_png("assets/ui/textures/tier_badge_ref.png")

	# Checkered flag pattern from play button
	var play_flag_rect = Rect2i(435, 305, 120, 90)
	var play_flag_crop = img.get_region(play_flag_rect)
	play_flag_crop.save_png("assets/ui/textures/play_flag_checkers.png")

	# Entire top bar tabs
	var top_tabs_rect = Rect2i(580, 36, 740, 52)
	var top_tabs_crop = img.get_region(top_tabs_rect)
	top_tabs_crop.save_png("assets/ui/textures/top_tabs_ref.png")

	# Entire Limited Time Event card ref
	var event_card_rect = Rect2i(1530, 205, 355, 305)
	var event_card_crop = img.get_region(event_card_rect)
	event_card_crop.save_png("assets/ui/textures/event_card_ref.png")

	# Entire Online Friends card ref
	var friends_card_rect = Rect2i(1530, 530, 355, 260)
	var friends_card_crop = img.get_region(friends_card_rect)
	friends_card_crop.save_png("assets/ui/textures/friends_card_ref.png")

	# Entire Season Pass card ref
	var season_card_rect = Rect2i(1520, 850, 370, 105)
	var season_card_crop = img.get_region(season_card_rect)
	season_card_crop.save_png("assets/ui/textures/season_card_ref.png")

	# Entire Daily Missions & Mail ref
	var missions_rect = Rect2i(45, 865, 450, 95)
	var missions_crop = img.get_region(missions_rect)
	missions_crop.save_png("assets/ui/textures/missions_mail_ref.png")

	# News & updates ref
	var news_rect = Rect2i(610, 870, 710, 80)
	var news_crop = img.get_region(news_rect)
	news_crop.save_png("assets/ui/textures/news_ref.png")

	print("Extracted all reference cards")
	quit(0)

