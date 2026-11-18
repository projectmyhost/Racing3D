@tool
extends SceneTree

func _init():
	var packed = load("res://scenes/race/RaceTrack3D.tscn") as PackedScene
	if not packed:
		print("FAIL: cannot load RaceTrack3D.tscn")
		quit(1)
		return
	var inst = packed.instantiate()
	get_root().add_child(inst)
	print("SUCCESS: RaceTrack3D instantiated!")
	var car = inst.get_node_or_null("RaceCar3D")
	print("Car exists: ", car != null)
	var colliders = inst.get_node_or_null("TrackColliders")
	print("TrackColliders exists: ", colliders != null)
	var finish_panel = inst.get_node_or_null("%FinishPanel")
	print("FinishPanel exists: ", finish_panel != null)
	var stars = inst.get_node_or_null("%FinishStars")
	print("FinishStars exists: ", stars != null)
	var rank = inst.get_node_or_null("%FinishRank")
	print("FinishRank exists: ", rank != null)
	var rewards = inst.get_node_or_null("%FinishRewards")
	print("FinishRewards exists: ", rewards != null)
	var play_again = inst.get_node_or_null("%PlayAgainBtn")
	print("PlayAgainBtn exists: ", play_again != null)
	var home_btn = inst.get_node_or_null("%FinishHomeBtn")
	print("FinishHomeBtn exists: ", home_btn != null)
	quit(0)

