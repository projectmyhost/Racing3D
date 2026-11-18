@tool
extends SceneTree
func _init():
	var f = Image.load_from_file("res://assets/models/cars/previews/fenyr.png")
	var c = Image.load_from_file("res://assets/models/cars/previews/coupe.png")
	var g = Image.load_from_file("res://assets/models/cars/previews/ghini.png")
	print("Fenyr: ", f.get_size() if f else "null")
	print("Coupe: ", c.get_size() if c else "null")
	print("Ghini: ", g.get_size() if g else "null")
	quit(0)

