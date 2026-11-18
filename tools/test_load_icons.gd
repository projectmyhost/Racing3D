@tool
extends SceneTree

func _init():
	var paths = [
		"res://assets/ui/icons/avatar_pilot_racing.png",
		"res://assets/ui/icons/avatar_friend_1.png",
		"res://assets/ui/icons/avatar_friend_2.png",
		"res://assets/ui/icons/ico_bell.png",
		"res://assets/ui/icons/ico_envelope.png",
		"res://assets/ui/icons/ico_coin.svg",
		"res://assets/ui/icons/ico_gem.svg",
		"res://assets/ui/icons/ico_settings_gear.svg"
	]
	for p in paths:
		var img = Image.load_from_file(p)
		print("%s: %s (size %s)" % [p.get_file(), "OK" if img else "FAIL", str(img.get_size()) if img else ""])
	quit(0)

