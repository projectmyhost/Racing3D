@tool
extends SceneTree

func _init():
	var ref = Image.load_from_file("docs/validation/reference_1080p.png")
	if not ref: quit(1)
	ref.convert(Image.FORMAT_RGBA8)

	# 1. Top Nav Bar: y from 37 to 86 (h=49), x from 586 to 1321 (w=735)
	var tb = ref.get_region(Rect2i(586, 37, 735, 49))
	for y in range(tb.get_height()):
		var lx = 14.0 * (1.0 - float(y) / float(tb.get_height())) + 1.0
		var rx = float(tb.get_width()) - 14.0 * (float(y) / float(tb.get_height())) - 1.0
		for x in range(tb.get_width()):
			if x < lx or x > rx or y < 1 or y >= tb.get_height() - 1:
				tb.set_pixel(x, y, Color(0, 0, 0, 0))
	tb.save_png("assets/ui/textures/top_nav_bar_clean.png")

	# 2. Currency Pill: y from 34 to 86 (h=52), x from 1345 to 1801 (w=456)
	var cp = ref.get_region(Rect2i(1345, 34, 456, 52))
	for y in range(cp.get_height()):
		for x in range(cp.get_width()):
			if y < 1 or y >= cp.get_height() - 1:
				if x < 4 or x > cp.get_width() - 4:
					cp.set_pixel(x, y, Color(0, 0, 0, 0))
	cp.save_png("assets/ui/textures/currency_pill_clean.png")

	# 3. Notifications Pill: y from 98 to 142 (h=44), x from 1570 to 1785 (w=215)
	var notif = ref.get_region(Rect2i(1570, 98, 215, 44))
	for y in range(notif.get_height()):
		var lx = 10.0 * (1.0 - float(y) / float(notif.get_height())) + 1.0
		var rx = float(notif.get_width()) - 10.0 * (float(y) / float(notif.get_height())) - 1.0
		for x in range(notif.get_width()):
			if x < lx or x > rx or y < 1 or y >= notif.get_height() - 1:
				notif.set_pixel(x, y, Color(0, 0, 0, 0))
	notif.save_png("assets/ui/textures/notifications_clean.png")

	# 4. Event Card: y from 212 to 524 (h=312), x from 1530 to 1888 (w=358)
	var ev = ref.get_region(Rect2i(1530, 212, 358, 312))
	for y in range(ev.get_height()):
		for x in range(ev.get_width()):
			if x < 2 or x >= ev.get_width() - 2 or y < 2 or y >= ev.get_height() - 2:
				ev.set_pixel(x, y, Color(0, 0, 0, 0))
	ev.save_png("assets/ui/textures/event_card_ready.png")

	# 5. Friends Card: y from 570 to 868 (h=298), x from 1530 to 1890 (w=360)
	var fr = ref.get_region(Rect2i(1530, 570, 360, 298))
	for y in range(fr.get_height()):
		for x in range(fr.get_width()):
			if x < 2 or x >= fr.get_width() - 2 or y < 2 or y >= fr.get_height() - 2:
				fr.set_pixel(x, y, Color(0, 0, 0, 0))
	fr.save_png("assets/ui/textures/friends_card_ready.png")

	# 6. Season Pass Card: y from 930 to 1042 (h=112), x from 1515 to 1895 (w=380)
	var sp = ref.get_region(Rect2i(1515, 930, 380, 112))
	for y in range(sp.get_height()):
		var lx = 14.0 * (1.0 - float(y) / float(sp.get_height())) + 2.0
		var rx = float(sp.get_width()) - 14.0 * (float(y) / float(sp.get_height())) - 2.0
		for x in range(sp.get_width()):
			if x < lx or x > rx or y < 2 or y >= sp.get_height() - 2:
				sp.set_pixel(x, y, Color(0, 0, 0, 0))
	sp.save_png("assets/ui/textures/season_card_ready.png")

	# 7. Daily Missions: y from 946 to 1040 (h=94), x from 40 to 365 (w=325)
	var dm = ref.get_region(Rect2i(40, 946, 325, 94))
	for y in range(dm.get_height()):
		var lx = 14.0 * (1.0 - float(y) / float(dm.get_height())) + 2.0
		var rx = float(dm.get_width()) - 14.0 * (float(y) / float(dm.get_height())) - 2.0
		for x in range(dm.get_width()):
			if x < lx or x > rx or y < 2 or y >= dm.get_height() - 2:
				dm.set_pixel(x, y, Color(0, 0, 0, 0))
	dm.save_png("assets/ui/textures/missions_card_ready.png")

	# 8. Mail: y from 930 to 1040 (h=110), x from 360 to 480 (w=120)
	var ml = ref.get_region(Rect2i(360, 930, 120, 110))
	for y in range(ml.get_height()):
		var lx = 12.0 * (1.0 - float(y) / float(ml.get_height())) + 1.0
		var rx = float(ml.get_width()) - 12.0 * (float(y) / float(ml.get_height())) - 1.0
		for x in range(ml.get_width()):
			if x < lx or x > rx or y < 1 or y >= ml.get_height() - 1:
				ml.set_pixel(x, y, Color(0, 0, 0, 0))
	ml.save_png("assets/ui/textures/mail_card_ready.png")

	# 9. News: y from 940 to 1040 (h=100), x from 605 to 1335 (w=730)
	var nw = ref.get_region(Rect2i(605, 940, 730, 100))
	for y in range(nw.get_height()):
		var lx = 14.0 * (1.0 - float(y) / float(nw.get_height())) + 2.0
		var rx = float(nw.get_width()) - 14.0 * (float(y) / float(nw.get_height())) - 2.0
		for x in range(nw.get_width()):
			if x < lx or x > rx or y < 2 or y >= nw.get_height() - 2:
				nw.set_pixel(x, y, Color(0, 0, 0, 0))
	nw.save_png("assets/ui/textures/news_card_ready.png")

	print("Finished perfect_all_alphas")
	quit(0)

