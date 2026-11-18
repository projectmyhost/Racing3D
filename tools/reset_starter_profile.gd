@tool
extends SceneTree

func _init():
	var p = PlayerProfileData.new()
	p.nickname = "DiazRaditya"
	p.level = 0
	p.current_xp = 0
	p.max_xp = 250
	p.coins = 250000
	p.gems = 500
	p.equipped_car = "sedan"
	var cars: Array[String] = ["sedan"]
	p.unlocked_cars = cars
	
	DirAccess.make_dir_recursive_absolute("user://")
	ResourceSaver.save(p, "user://player_profile.tres")
	ResourceSaver.save(p, "res://data/player_profile.tres")
	print("Profile reset to starter: DiazRaditya, Lv. 0, 0/250 XP, sedan, 250k coins")
	quit(0)
