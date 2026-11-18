extends Control

@onready var title_label: Label = $MarginContainer/VBoxContainer/Header/HBox/TitleLabel
@onready var back_button: Button = $MarginContainer/VBoxContainer/Header/HBox/BackButton
@onready var news_list_container: VBoxContainer = $MarginContainer/VBoxContainer/BodyHBox/ListPanel/ScrollContainer/NewsList
@onready var detail_title: Label = $MarginContainer/VBoxContainer/BodyHBox/DetailPanel/VBox/DetailTitle
@onready var detail_category: Label = $MarginContainer/VBoxContainer/BodyHBox/DetailPanel/VBox/MetaHBox/DetailCategory
@onready var detail_date: Label = $MarginContainer/VBoxContainer/BodyHBox/DetailPanel/VBox/MetaHBox/DetailDate
@onready var detail_body: RichTextLabel = $MarginContainer/VBoxContainer/BodyHBox/DetailPanel/VBox/DetailBody

var articles: Array[Dictionary] = [
	{
		"id": "welcome_racezone",
		"title": "Welcome to Racezone Arcade!",
		"category": "COMMUNITY",
		"date": "Nov 12, 2026",
		"summary": "Racezone 2D arcade prototype is officially launched! Explore offline racing at its finest.",
		"body": "Welcome to [color=#FFB51B][b]RACEZONE[/b][/color]!\n\nEngineered from the ground up for instantaneous arcade racing thrills, Racezone delivers pure high-octane 2D racing mechanics without barriers, paywalls, or mandatory online logins.\n\n[b]What's Waiting For You:[/b]\n• [color=#FFB51B]Pure 2D Physics:[/color] Experience tight apex drifts, responsive acceleration, and dynamic collision feedback.\n• [color=#FFB51B]Authentic Car Roster:[/color] From the nimble Starter GT to the roaring Phantom Turbo, build your dream fleet.\n• [color=#FFB51B]Livery Customization:[/color] Personalize your racer with custom automotive body colors, racing decals, and sport lightweight rims.\n• [color=#FFB51B]Local Offline Records:[/color] Compete against local circuit records and sharpen your precision lap times.\n\nFire up your engine, tune your sensitivity in Settings, and hit the track!"
	},
	{
		"id": "sunset_circuit",
		"title": "Sunset Circuit Now Open For Competition",
		"category": "TRACK SPOTLIGHT",
		"date": "Nov 10, 2026",
		"summary": "The signature sunset pit-lane circuit is now available for all drivers.",
		"body": "The sun is sinking behind the city skyline, stadium floodlights are humming to life, and the asphalt is calling: [b]Sunset Circuit[/b] is officially open for all competitive classes!\n\n[b]Circuit Characteristics:[/b]\n• [b]Surface:[/b] Smooth high-grip asphalt with painted circuit kerbs\n• [b]Length:[/b] 2.4 km per lap (2 Laps standard competition)\n• [b]Key Technical Challenge:[/b] The sweeping double-apex chicane following the pit straight requires late braking and smooth weight transfer.\n\n[b]Driver Tip:[/b] Enter Turn 2 wide, clip the inner barrier softly, and get back on full throttle before corner exit to maintain peak speed along the coastal boulevard straight!"
	},
	{
		"id": "patch_10_handling",
		"title": "Update 1.0 — Handling & Physics Refinements",
		"category": "DEV LOG",
		"date": "Nov 08, 2026",
		"summary": "Refined 2D arcade physics, responsive drift mechanics, and accessibility options.",
		"body": "Update 1.0 focuses on the feel of the wheel, providing tighter handling responsiveness and extensive accessibility accommodations:\n\n[b]Patch Highlights:[/b]\n• [b]Steering Sensitivity Tuning:[/b] Sliders 1–10 in Settings now precisely modulate wheel turning angular velocities.\n• [b]Auto-Accelerate Mode:[/b] Added dedicated accessibility toggle for one-handed steering control.\n• [b]Visual Accessibility:[/b] High Contrast UI mode and Color Assist profiles (Protanopia & Deuteranopia friendly palettes) are fully supported.\n• [b]Bilingual Support:[/b] Full localization in English and Bahasa Indonesia across all HUD panels and dialogs.\n\nThank you for testing Racezone!"
	}
]

var selected_index: int = 0

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	_build_article_list()
	_select_article(0)

	if has_node("/root/Localization"):
		title_label.text = get_node("/root/Localization").get_string("NEWS")
		back_button.text = "← " + get_node("/root/Localization").get_string("BACK")

func _build_article_list() -> void:
	for c in news_list_container.get_children():
		c.queue_free()

	for i in range(articles.size()):
		var art = articles[i]
		var btn = Button.new()
		btn.set_script(preload("res://scripts/ui/RaceButton.gd"))
		btn.custom_minimum_size = Vector2(0, 78)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		btn.text = "[%s] %s\n%s • %s" % [art.category, art.title, art.date, art.summary]
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT

		var idx = i
		btn.pressed.connect(func(): _select_article(idx))
		news_list_container.add_child(btn)

func _select_article(idx: int) -> void:
	if idx < 0 or idx >= articles.size():
		return
	selected_index = idx
	var art = articles[idx]

	detail_title.text = art.title
	detail_category.text = "CATEGORY: " + art.category
	detail_date.text = "DATE: " + art.date
	detail_body.text = art.body

	# Mark article read in SaveManager
	if has_node("/root/SaveManager"):
		var sm = get_node("/root/SaveManager")
		var read_news = sm.current_data.progress.get("read_news", [])
		if not (art.id in read_news):
			read_news.append(art.id)
			sm.current_data.progress.read_news = read_news
			sm.save_data()

func _on_back_pressed() -> void:
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_click_sfx()
	if has_node("/root/Navigation"):
		get_node("/root/Navigation").pop_scene()
	else:
		get_tree().change_scene_to_file("res://scenes/home/HomeScreen.tscn")
