extends SceneTree

func _init() -> void:
	var path = "res://assets/models/cars/car_sedan.tscn"
	var f = FileAccess.open(path, FileAccess.READ)
	if not f:
		print("Could not open file: ", path)
		quit()
		return
	var text = f.get_as_text()
	f.close()
	
	var re_body = RegEx.new()
	re_body.compile('(\\[sub_resource type="StandardMaterial3D" id="[^"]+"\\]\\nresource_name = "Body_5"\\n)(albedo_texture = ExtResource\\("[^"]+"\\))[^\\n]*[\\s\\S]*?(?=\\n\\[sub_resource)')
	var body_repl = '$1$2\\nmetallic = 0.65\\nroughness = 0.14\\nclearcoat_enabled = true\\nclearcoat = 1.0\\nclearcoat_roughness = 0.05\\nspecular = 0.85\\nmetadata/_gltf_primary_texture_coord = 0'
	text = re_body.sub(text, body_repl)
	
	var re_glass = RegEx.new()
	re_glass.compile('(\\[sub_resource type="StandardMaterial3D" id="[^"]+"\\]\\nresource_name = "Glass_5"\\n)[\\s\\S]*?(?=\\n\\[sub_resource)')
	var glass_repl = '$1transparency = 1\\ncull_mode = 0\\nalbedo_color = Color(0.1, 0.14, 0.2, 0.25)\\nmetallic = 0.15\\nroughness = 0.03\\nspecular = 0.95\\nclearcoat_enabled = true\\nclearcoat = 1.0\\nclearcoat_roughness = 0.03'
	text = re_glass.sub(text, glass_repl)
	
	var re_wheel = RegEx.new()
	re_wheel.compile('(\\[sub_resource type="StandardMaterial3D" id="[^"]+"\\]\\nresource_name = "Wheel_4"\\n)(albedo_texture = ExtResource\\("[^"]+"\\))[^\\n]*[\\s\\S]*?(?=\\n\\[sub_resource)')
	var wheel_repl = '$1$2\\nmetallic = 0.45\\nroughness = 0.35\\nspecular = 0.75\\nmetadata/_gltf_primary_texture_coord = 0'
	text = re_wheel.sub(text, wheel_repl)
	
	var re_optics = RegEx.new()
	re_optics.compile('(\\[sub_resource type="StandardMaterial3D" id="[^"]+"\\]\\nresource_name = "Optics_5"\\n)(albedo_texture = ExtResource\\("[^"]+"\\))[^\\n]*[\\s\\S]*?(?=\\n\\[sub_resource)')
	var optics_repl = '$1$2\\nroughness = 0.05\\nmetallic = 0.2\\nspecular = 0.9\\nemission_enabled = true\\nemission = Color(1, 1, 1, 1)\\nemission_energy_multiplier = 0.4\\nmetadata/_gltf_primary_texture_coord = 0'
	text = re_optics.sub(text, optics_repl)
	
	var out_f = FileAccess.open(path, FileAccess.WRITE)
	out_f.store_string(text)
	out_f.close()
	print("Cleanly updated car_sedan.tscn")
	quit()

