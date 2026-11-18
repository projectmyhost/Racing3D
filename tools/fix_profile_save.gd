@tool
extends SceneTree

func _init():
	var save_path = "user://player_profile.tres"
	var p: PlayerProfileData
	if ResourceLoader.exists(save_path):
		p = ResourceLoader.load(save_path) as PlayerProfileData
	if not p:
		p = load("res://data/player_profile.tres") as PlayerProfileData
	if p:
		p.nickname = "rawrrr"
		p.level = 0
		p.current_xp = 236
		p.max_xp = 250
		p.coins = 29503500
		p.gems = 31250
		p.equipped_car = "porsche_mission_x"
		ResourceSaver.save(p, save_path)
		print("Successfully calibrated user://player_profile.tres to rawrrr, level 0, 236/250 XP")
	quit(0)

