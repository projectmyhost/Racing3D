@tool
extends SceneTree

func _init():
	var path = "C:/Users/Pongo/.gemini/antigravity/brain/1a795719-3155-4165-929d-bf2932498465/.user_uploaded/media_1794875373647_3122b9f2.jpg"
	var img = Image.load_from_file(path)
	if img:
		print("IMAGE LOADED: size=", img.get_size(), " format=", img.get_format())
	else:
		print("FAILED TO LOAD IMAGE")
	quit(0)

