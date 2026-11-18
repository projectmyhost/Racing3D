@tool
extends SceneTree

func _init():
	var img = Image.load_from_file("docs/validation/reference_1080p.png")
	if not img: quit(1)
	
	# Event Card: y from 212 to 524, x from 1530 to 1888
	var ev = img.get_region(Rect2i(1530, 212, 358, 312))
	ev.save_png("assets/ui/textures/event_card_exact.png")

	# Friends Card: y from 542 to 798, x from 1530 to 1888
	var fr = img.get_region(Rect2i(1530, 542, 358, 256))
	fr.save_png("assets/ui/textures/friends_card_exact.png")

	# Season Pass Card: y from 918 to 1010, x from 1520 to 1895
	var sp = img.get_region(Rect2i(1520, 918, 375, 92))
	sp.save_png("assets/ui/textures/season_card_exact.png")

	# Daily missions: y from 938 to 1010, x from 45 to 355
	var dm = img.get_region(Rect2i(45, 938, 310, 72))
	dm.save_png("assets/ui/textures/missions_card_exact.png")

	# Mail: y from 932 to 1012, x from 360 to 475
	var ml = img.get_region(Rect2i(360, 932, 115, 80))
	ml.save_png("assets/ui/textures/mail_card_exact.png")

	# News: y from 926 to 1008, x from 605 to 1325
	var nw = img.get_region(Rect2i(605, 926, 720, 82))
	nw.save_png("assets/ui/textures/news_card_exact.png")

	print("Saved exact cards")
	quit(0)

