@tool
extends SceneTree

func _init():
	var img = Image.load_from_file("docs/validation/reference_1080p.png")
	if not img: quit(1)
	
	# Season Pass Card: y from 915 to 1035 (h=120), x from 1515 to 1895 (w=380)
	var sp = img.get_region(Rect2i(1515, 915, 380, 120))
	sp.save_png("assets/ui/textures/season_card_full.png")

	# Daily Missions Card: y from 936 to 1018 (h=82), x from 45 to 365 (w=320)
	var dm = img.get_region(Rect2i(45, 936, 320, 82))
	dm.save_png("assets/ui/textures/missions_card_full.png")

	# Mail: y from 926 to 1020 (h=94), x from 358 to 480 (w=122)
	var ml = img.get_region(Rect2i(358, 926, 122, 94))
	ml.save_png("assets/ui/textures/mail_card_full.png")

	# News Banner: y from 920 to 1015 (h=95), x from 605 to 1335 (w=730)
	var nw = img.get_region(Rect2i(605, 920, 730, 95))
	nw.save_png("assets/ui/textures/news_card_full.png")

	# Version Label: y from 995 to 1028, x from 1425 to 1515
	var ver = img.get_region(Rect2i(1425, 995, 90, 33))
	ver.save_png("assets/ui/textures/ver_label_full.png")

	print("Saved full bottom elements")
	quit(0)

