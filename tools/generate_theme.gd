@tool
extends SceneTree

func _init():
	print("Generating racing theme...")
	var theme = Theme.new()
	
	var font_bold = load("res://assets/ui/fonts/Rajdhani-Bold.ttf")
	var font_semi = load("res://assets/ui/fonts/Rajdhani-SemiBold.ttf")
	var font_reg = load("res://assets/ui/fonts/Rajdhani-Regular.ttf")
	
	if font_bold:
		theme.default_font = font_bold
		theme.default_font_size = 28
		
	# Label settings
	theme.set_color("font_color", "Label", Color(0.957, 0.957, 0.949, 1.0)) # #F4F4F2
	
	ResourceSaver.save(theme, "res://assets/ui/theme_racing.tres")
	print("Theme saved to res://assets/ui/theme_racing.tres")
	quit()
