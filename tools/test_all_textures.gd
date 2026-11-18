@tool
extends SceneTree

func _init():
	var files = [
		"assets/ui/textures/profile_card_clean_alpha.png",
		"assets/ui/textures/top_nav_bar_clean.png",
		"assets/ui/textures/currency_pill_clean.png",
		"assets/ui/textures/gear_btn_clean.png",
		"assets/ui/textures/notif_ms_clean.png",
		"assets/ui/textures/event_card_ready.png",
		"assets/ui/textures/friends_card_ready.png",
		"assets/ui/textures/missions_card_ready.png",
		"assets/ui/textures/mail_card_ready.png",
		"assets/ui/textures/news_card_ready.png",
		"assets/ui/textures/season_card_ready.png"
	]
	for f in files:
		var img = Image.load_from_file(f)
		if not img or img.is_empty():
			print("ERROR loading:", f)
		else:
			print("OK:", f, img.get_size())
	quit(0)

