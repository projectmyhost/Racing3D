extends SceneTree

func _init() -> void:
	var path = "res://assets/models/cars/car_sedan.tscn"
	var f = FileAccess.open(path, FileAccess.READ)
	var text = f.get_as_text()
	f.close()
	
	# Replace literal \n with actual newlines
	text = text.replace("\\n", "\n")
	
	var out_f = FileAccess.open(path, FileAccess.WRITE)
	out_f.store_string(text)
	out_f.close()
	print("Converted escaped newlines to real newlines in car_sedan.tscn")
	quit()

