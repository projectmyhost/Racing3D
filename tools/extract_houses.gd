@tool
extends SceneTree

func _init():
	print("--- INSPECTING AND EXTRACTING HOUSE ASSETS ---")
	var zip_paths = [
		"C:/Users/Pongo/Downloads/OBJ-20261112T140248Z-1-001.zip",
		"C:/Users/Pongo/Downloads/FBX-20261112T140342Z-1-001.zip"
	]
	
	# Godot ProjectSettings has ProjectSettings.globalize_path("res://assets/models/buildings")
	var dest_dir = "res://assets/models/buildings"
	DirAccess.make_dir_recursive_absolute("res://assets/models/buildings")
	
	for zp in zip_paths:
		var reader = ZIPReader.new()
		var err = reader.open(zp)
		if err != OK:
			print("Could not open zip: ", zp, " err: ", err)
			continue
		print("Opened: ", zp)
		var files = reader.get_files()
		print("Total files in zip: ", files.size())
		for f in files:
			if f.ends_with("/"):
				DirAccess.make_dir_recursive_absolute(dest_dir + "/" + f)
				continue
			var data = reader.read_file(f)
			var out_path = dest_dir + "/" + f
			var parent = out_path.get_base_dir()
			DirAccess.make_dir_recursive_absolute(parent)
			var file_acc = FileAccess.open(out_path, FileAccess.WRITE)
			if file_acc:
				file_acc.store_buffer(data)
				file_acc.close()
				# print("Extracted: ", f)
		reader.close()
	print("SUCCESS: Extraction completed!")
	quit(0)

