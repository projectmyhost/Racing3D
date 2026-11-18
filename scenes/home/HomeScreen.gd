extends Control

# Preloaded dialog scenes
const FREE_CURRENCY_DIALOG = preload("res://scenes/home/FreeCurrencyDialog.tscn")
const DAILY_REWARDS_DIALOG = preload("res://scenes/rewards/DailyRewardsScreen.tscn")
const CONFIRM_DIALOG = preload("res://scenes/common/ConfirmDialog.tscn")

# Node references
# Header Left: Profile Card
@onready var profile_btn: Button = $HeaderLeft/ProfileCard/ProfileButton
@onready var avatar_rect: TextureRect = $HeaderLeft/ProfileCard/Margin/HBox/AvatarFrame/AvatarTexture
@onready var player_name_label: Label = $HeaderLeft/ProfileCard/Margin/HBox/InfoVBox/NameHBox/PlayerNameLabel
@onready var player_level_label: Label = $HeaderLeft/ProfileCard/Margin/HBox/InfoVBox/NameHBox/LevelBadge/LevelMargin/LevelLabel
@onready var xp_label: Label = $HeaderLeft/ProfileCard/Margin/HBox/InfoVBox/XPHBox/XPLabel
@onready var xp_bar: ProgressBar = $HeaderLeft/ProfileCard/Margin/HBox/InfoVBox/XPProgressBar

# Header Right: Currencies & Utility Buttons
@onready var coins_label: Label = $HeaderRight/HBox/CoinsPill/Margin/HBox/CoinsValueLabel
@onready var coins_plus_btn: Button = $HeaderRight/HBox/CoinsPill/Margin/HBox/CoinsPlusBtn
@onready var diamonds_label: Label = $HeaderRight/HBox/DiamondsPill/Margin/HBox/DiamondsValueLabel
@onready var diamonds_plus_btn: Button = $HeaderRight/HBox/DiamondsPill/Margin/HBox/DiamondsPlusBtn
@onready var inbox_btn: Button = $HeaderRight/HBox/InboxBtn
@onready var inbox_badge: PanelContainer = $HeaderRight/HBox/InboxBtn/Badge
@onready var inbox_badge_label: Label = $HeaderRight/HBox/InboxBtn/Badge/BadgeLabel
@onready var settings_btn: Button = $HeaderRight/HBox/SettingsBtn

# Left Side: Event Card
@onready var event_tag_label: Label = $LeftEventCard/Margin/VBox/HeaderHBox/EventTagPanel/TagMargin/EventTagLabel
@onready var event_title_label: Label = $LeftEventCard/Margin/VBox/HeaderHBox/EventTitleLabel
@onready var event_time_label: Label = $LeftEventCard/Margin/VBox/InfoHBox/TimeLabel
@onready var event_progress_bar: ProgressBar = $LeftEventCard/Margin/VBox/EventProgressBar
@onready var event_progress_label: Label = $LeftEventCard/Margin/VBox/ProgressHBox/ProgressLabel
@onready var event_go_race_btn: Button = $LeftEventCard/Margin/VBox/GoRaceBtn

# Center-Left: Hero 2D Car
@onready var hero_car_container: Control = $HeroCarContainer
@onready var car_sprite: TextureRect = $HeroCarContainer/CarVisual/CarSprite
@onready var decal_sprite: TextureRect = $HeroCarContainer/CarVisual/DecalSprite
@onready var car_visual: Control = $HeroCarContainer/CarVisual

# Right Side: CTA & Navigation
@onready var play_btn: Button = $RightCTA/PlayBtn
@onready var garage_btn: Button = $RightMenu/VBox/GarageBtn
@onready var shop_btn: Button = $RightMenu/VBox/ShopBtn
@onready var achievements_btn: Button = $RightMenu/VBox/AchievementsBtn
@onready var leaderboard_btn: Button = $RightMenu/VBox/LeaderboardBtn

# Bottom-Left: Daily Login
@onready var daily_login_btn: Button = $BottomLeftDaily/DailyCard/DailyLoginButton
@onready var daily_title_label: Label = $BottomLeftDaily/DailyCard/Margin/HBox/TextVBox/DailyTitle
@onready var daily_desc_label: Label = $BottomLeftDaily/DailyCard/Margin/HBox/TextVBox/DailyDesc

# Bottom-Right: Footer
@onready var news_btn: Button = $BottomRightFooter/HBox/NewsBtn
@onready var customize_btn: Button = $BottomRightFooter/HBox/CustomizeBtn
@onready var quit_btn: Button = $BottomRightFooter/HBox/QuitBtn

# Bobbing animation variables
var _idle_time: float = 0.0
var _car_base_pos_y: float = 0.0

# Paint colors palette mapping
const PAINT_COLORS: Dictionary = {
	"silver_red": Color(1.0, 1.0, 1.0, 1.0),
	"racing_yellow": Color(1.0, 0.85, 0.15, 1.0),
	"crimson_red": Color(0.95, 0.22, 0.22, 1.0),
	"royal_blue": Color(0.25, 0.55, 1.0, 1.0),
	"stealth_black": Color(0.35, 0.35, 0.38, 1.0),
	"emerald_green": Color(0.2, 0.85, 0.45, 1.0)
}

func _ready() -> void:
	_car_base_pos_y = car_visual.position.y

	_connect_signals()
	_update_all_ui()

func _process(delta: float) -> void:
	# Subtle 2D car floating/bobbing animation
	_idle_time += delta
	var offset_y = sin(_idle_time * 2.2) * 3.5
	car_visual.position.y = _car_base_pos_y + offset_y

func _connect_signals() -> void:
	# Profile click
	profile_btn.pressed.connect(_on_profile_pressed)

	# Currency plus buttons
	coins_plus_btn.pressed.connect(func(): _open_free_currency("coins"))
	diamonds_plus_btn.pressed.connect(func(): _open_free_currency("diamonds"))

	# Header buttons
	inbox_btn.pressed.connect(_on_inbox_pressed)
	settings_btn.pressed.connect(_on_settings_pressed)

	# Event card
	event_go_race_btn.pressed.connect(_on_play_pressed)

	# CTA & Right menu
	play_btn.pressed.connect(_on_play_pressed)
	garage_btn.pressed.connect(_on_garage_pressed)
	shop_btn.pressed.connect(_on_shop_pressed)
	achievements_btn.pressed.connect(_on_achievements_pressed)
	leaderboard_btn.pressed.connect(_on_leaderboard_pressed)

	# Daily Login
	daily_login_btn.pressed.connect(_on_daily_login_pressed)

	# Footer
	news_btn.pressed.connect(_on_news_pressed)
	customize_btn.pressed.connect(_on_customize_pressed)
	quit_btn.pressed.connect(_on_quit_pressed)

	# SaveManager signals
	if has_node("/root/SaveManager"):
		var sm = get_node("/root/SaveManager")
		sm.currency_changed.connect(_update_currency_counters)
		sm.profile_changed.connect(_update_profile_card)
		sm.car_selected.connect(_on_car_selected)
		sm.customization_changed.connect(_update_car_display)
		sm.progress_updated.connect(_on_progress_updated)

	# Localization signal
	if has_node("/root/Localization"):
		get_node("/root/Localization").language_changed.connect(_on_language_changed)

func _update_all_ui() -> void:
	_update_profile_card()
	_update_currency_counters()
	_update_inbox_badge()
	_update_event_card()
	_update_car_display()
	_update_daily_login_card()
	_update_localization()

func _update_profile_card() -> void:
	if not has_node("/root/SaveManager"):
		return
	var sm = get_node("/root/SaveManager")
	var p_name = sm.get_player_name()
	var p_level = sm.get_player_level()
	var p_xp = sm.get_player_xp()
	var avatar_id = sm.get_avatar_id()

	player_name_label.text = p_name
	player_level_label.text = "Lv. %d" % p_level
	xp_label.text = "%d / 1000" % p_xp
	xp_bar.max_value = 1000
	xp_bar.value = p_xp

	var avatar_path = "res://assets/art/avatars/%s.png" % avatar_id
	if ResourceLoader.exists(avatar_path):
		avatar_rect.texture = load(avatar_path)

func _update_currency_counters() -> void:
	if not has_node("/root/SaveManager"):
		return
	var sm = get_node("/root/SaveManager")
	coins_label.text = sm.format_currency(sm.get_coins())
	diamonds_label.text = sm.format_currency(sm.get_diamonds())

func _update_inbox_badge() -> void:
	if not has_node("/root/SaveManager"):
		return
	var sm = get_node("/root/SaveManager")
	var prog = sm.get_progress()
	var read_inbox = prog.get("read_inbox", [])
	var total_messages = 3
	var unread_count = total_messages - read_inbox.size()

	if unread_count > 0:
		inbox_badge.visible = true
		inbox_badge_label.text = str(unread_count)
	else:
		inbox_badge.visible = false

func _update_event_card() -> void:
	if not has_node("/root/SaveManager"):
		return
	var sm = get_node("/root/SaveManager")
	var prog = sm.get_progress()
	var races = int(prog.get("event_races_completed", 0))
	var target = 3

	event_progress_bar.max_value = target
	event_progress_bar.value = mini(races, target)
	event_progress_label.text = "%d / %d Races completed" % [mini(races, target), target]

func _update_car_display() -> void:
	if not has_node("/root/SaveManager"):
		return
	var sm = get_node("/root/SaveManager")
	var car_id = sm.get_selected_car()
	var custom = sm.get_customization()

	# Load Car Sprite
	var car_tex_path = "res://assets/art/cars/car_%s.png" % car_id
	if ResourceLoader.exists(car_tex_path):
		car_sprite.texture = load(car_tex_path)

	# Apply Paint Color Tint
	var paint_id = str(custom.get("paint_id", "silver_red"))
	if PAINT_COLORS.has(paint_id):
		car_sprite.modulate = PAINT_COLORS[paint_id]
	else:
		car_sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)

	# Apply Decal
	var decal_id = str(custom.get("decal_id", "stripe_01"))
	var decal_filename = "decal_stripes.png"
	if "flame" in decal_id:
		decal_filename = "decal_flame.png"
	elif "check" in decal_id:
		decal_filename = "decal_checkered.png"

	var decal_path = "res://assets/art/cars/%s" % decal_filename
	if ResourceLoader.exists(decal_path) and decal_id != "none":
		decal_sprite.texture = load(decal_path)
		decal_sprite.visible = true
	else:
		decal_sprite.visible = false

func _update_daily_login_card() -> void:
	if not has_node("/root/SaveManager"):
		return
	var sm = get_node("/root/SaveManager")
	var prog = sm.get_progress()
	var last_claim = str(prog.get("last_daily_claim", ""))
	var today_str = Time.get_date_string_from_system()

	if last_claim == today_str:
		daily_desc_label.text = "Claimed today ✓"
		daily_desc_label.modulate = Color(0.5, 0.9, 0.5, 1.0)
	else:
		daily_desc_label.text = "Claim your reward!"
		daily_desc_label.modulate = Color(1.0, 0.85, 0.2, 1.0)

func _update_localization() -> void:
	if not has_node("/root/Localization"):
		return
	var loc = get_node("/root/Localization")
	play_btn.text = loc.get_string("PLAY")
	garage_btn.text = "🏎   " + loc.get_string("GARAGE")
	shop_btn.text = "🛒   " + loc.get_string("SHOP")
	achievements_btn.text = "🏆   " + loc.get_string("ACHIEVEMENTS")
	leaderboard_btn.text = "📊   " + loc.get_string("LEADERBOARD")
	news_btn.text = "📰  " + loc.get_string("NEWS")
	customize_btn.text = "🎨  " + loc.get_string("CUSTOMIZE")
	quit_btn.text = "⏻  " + loc.get_string("QUIT")
	event_title_label.text = loc.get_string("EVENT_FESTIVAL")
	event_go_race_btn.text = loc.get_string("GO_RACE") + " 🏁"

func _on_language_changed(_new_lang: String) -> void:
	_update_localization()

func _on_progress_updated() -> void:
	_update_event_card()
	_update_daily_login_card()
	_update_inbox_badge()

func _on_car_selected(_car_id: String) -> void:
	_update_car_display()

# Navigation handlers
func _on_profile_pressed() -> void:
	_navigate_to("res://scenes/profile/ProfileScreen.tscn")

func _open_free_currency(mode: String) -> void:
	var dlg = FREE_CURRENCY_DIALOG.instantiate()
	add_child(dlg)
	dlg.set_mode(mode)

func _on_inbox_pressed() -> void:
	_navigate_to("res://scenes/inbox/InboxScreen.tscn")

func _on_settings_pressed() -> void:
	_navigate_to("res://scenes/settings/SettingsScreen.tscn")

func _on_play_pressed() -> void:
	_navigate_to("res://scenes/race/RaceSetupScreen.tscn")

func _on_garage_pressed() -> void:
	_navigate_to("res://scenes/garage/GarageScreen.tscn")

func _on_shop_pressed() -> void:
	_navigate_to("res://scenes/shop/ShopScreen.tscn")

func _on_achievements_pressed() -> void:
	_navigate_to("res://scenes/achievements/AchievementsScreen.tscn")

func _on_leaderboard_pressed() -> void:
	_navigate_to("res://scenes/leaderboard/LeaderboardScreen.tscn")

func _on_daily_login_pressed() -> void:
	var dlg = DAILY_REWARDS_DIALOG.instantiate()
	add_child(dlg)
	dlg.daily_reward_claimed.connect(_update_daily_login_card)

func _on_news_pressed() -> void:
	_navigate_to("res://scenes/news/NewsScreen.tscn")

func _on_customize_pressed() -> void:
	_navigate_to("res://scenes/customize/CustomizeScreen.tscn")

func _on_quit_pressed() -> void:
	var confirm_dlg = CONFIRM_DIALOG.instantiate()
	add_child(confirm_dlg)
	
	var title = "Exit Racezone?"
	var msg = "Are you sure you want to exit to desktop?"
	var confirm_txt = "EXIT GAME"
	var cancel_txt = "KEEP RACING"

	if has_node("/root/Localization"):
		var loc = get_node("/root/Localization")
		title = loc.get_string("QUIT_CONFIRM_TITLE")
		msg = loc.get_string("QUIT_CONFIRM_MSG")
		confirm_txt = loc.get_string("EXIT_GAME")
		cancel_txt = loc.get_string("KEEP_RACING")

	confirm_dlg.setup(title, msg, confirm_txt, cancel_txt, false, false)
	confirm_dlg.confirmed.connect(_do_quit)

func _do_quit() -> void:
	if has_node("/root/SaveManager"):
		get_node("/root/SaveManager").save_data()
	get_tree().quit()

func _navigate_to(path: String) -> void:
	if ResourceLoader.exists(path):
		if has_node("/root/Navigation"):
			get_node("/root/Navigation").push_scene(path)
		else:
			get_tree().change_scene_to_file(path)
	else:
		if has_node("/root/ToastManager"):
			get_node("/root/ToastManager").show_toast("Opening " + path.get_file().get_basename())
