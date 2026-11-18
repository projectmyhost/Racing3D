class_name HomeScreenUI
extends Control

const ProfileCardWidget = preload("res://scripts/ui/profile_card_widget.gd")
const TopNavBar = preload("res://scripts/ui/top_nav_bar.gd")
const CurrencyBar = preload("res://scripts/ui/currency_bar.gd")
const SettingsHexBtn = preload("res://scripts/ui/settings_hex_btn.gd")
const NotifPingWidget = preload("res://scripts/ui/notif_ping_widget.gd")
const EventCardUI = preload("res://scripts/ui/event_card_ui.gd")
const FriendsCardUI = preload("res://scripts/ui/friends_card_ui.gd")
const DailyMissionsUI = preload("res://scripts/ui/daily_missions_ui.gd")
const MailBtnUI = preload("res://scripts/ui/mail_btn_ui.gd")
const NewsBannerUI = preload("res://scripts/ui/news_banner_ui.gd")
const SeasonPassUI = preload("res://scripts/ui/season_pass_ui.gd")

## HomeScreen UI Controller conforming to DESIGN.md and user specifications.
## Implements 4-tab academic settings, multi-car fleet dealership, and motorsport HUD.

signal play_pressed
signal settings_pressed
signal garage_pressed
signal tuning_pressed
signal paint_shop_pressed
signal profile_pressed
signal back_pressed
signal paint_color_selected(color: Color)
signal car_equipped(car_id: String)

# HUD References
@onready var hud_root: Control = %HUD
@onready var profile_card: Control = %ProfileCard
@onready var avatar_rect: TextureRect = %AvatarRect
@onready var nickname_label: Label = %NicknameLabel
@onready var level_label: Label = %LevelLabel
@onready var xp_bar: ProgressBar = %XPBar
@onready var xp_label: Label = %XPLabel
@onready var currency_pill: Control = %CurrencyPill
@onready var coin_label: Label = %CoinLabel
@onready var gem_label: Label = %GemLabel
@onready var gear_btn: TextureButton = %SettingsGearBtn

# Nav Buttons
@onready var play_btn: Control = %PlayBtn
@onready var settings_btn: Control = %SettingsBtn
@onready var garage_btn: Control = %GarageBtn
@onready var tuning_btn: Control = %TuningBtn
@onready var paint_shop_btn: Control = %PaintShopBtn
@onready var profile_btn: Control = %ProfileBtn

# Pages / Modals
@onready var pages_layer: Control = %PagesLayer
@onready var settings_modal: Control = %SettingsModal
@onready var profile_modal: Control = %ProfileModal
@onready var topup_modal: Control = %TopupModal
@onready var garage_modal: Control = %GarageModal
@onready var tuning_modal: Control = %TuningModal
@onready var paint_shop_modal: Control = %PaintShopModal
@onready var play_modal: Control = %PlayModal
@onready var toast_panel: Panel = %ToastPanel
@onready var toast_label: Label = %ToastLabel

# Profile Modal Inputs
@onready var profile_name_edit: LineEdit = %ProfileNameEdit
@onready var profile_save_btn: Button = %ProfileSaveBtn
@onready var profile_cancel_btn: Button = %ProfileCancelBtn

# Settings Modal Controls
@onready var quality_option: OptionButton = %QualityOption
@onready var fps_option: OptionButton = %FpsOption
@onready var window_option: OptionButton = %WindowOption
@onready var master_slider: HSlider = %MasterSlider
@onready var engine_slider: HSlider = %EngineSlider
@onready var sfx_slider: HSlider = %SfxSlider
@onready var ambience_slider: HSlider = %AmbienceSlider
@onready var music_slider: HSlider = %MusicSlider

# Settings Tabs
@onready var tab_btn_display: Button = %TabBtnDisplay
@onready var tab_btn_audio: Button = %TabBtnAudio
@onready var tab_btn_assists: Button = %TabBtnAssists
@onready var tab_btn_project: Button = %TabBtnProject
@onready var tab_panel_display: Control = %TabPanelDisplay
@onready var tab_panel_audio: Control = %TabPanelAudio
@onready var tab_panel_assists: Control = %TabPanelAssists
@onready var tab_panel_project: Control = %TabPanelProject

# Garage Modal Controls
@onready var garage_car_list: VBoxContainer = %GarageCarList
@onready var garage_car_title: Label = %GarageCarTitle
@onready var garage_car_class: Label = %GarageCarClass
@onready var garage_car_desc: Label = %GarageCarDesc
@onready var garage_bar_top_speed: ProgressBar = %GarageBarTopSpeed
@onready var garage_bar_top_speed_val: Label = %GarageBarTopSpeedVal
@onready var garage_bar_accel: ProgressBar = %GarageBarAccel
@onready var garage_bar_accel_val: Label = %GarageBarAccelVal
@onready var garage_bar_power: ProgressBar = %GarageBarPower
@onready var garage_bar_power_val: Label = %GarageBarPowerVal
@onready var garage_bar_handling: ProgressBar = %GarageBarHandling
@onready var garage_bar_handling_val: Label = %GarageBarHandlingVal
@onready var garage_spec_details: Label = %GarageSpecDetails
@onready var garage_status_label: Label = %GarageStatusLabel
@onready var garage_action_btn: Button = %GarageActionBtn

var _nav_buttons: Array[Control] = []
var _current_focus_index: int = 0
var _active_modal: Control = null
var _profile_autoload: Node
var _toast_tween: Tween
var _profile_widget: ProfileCardWidget = null
var _currency_widget: CurrencyBar = null

# Active selected car in garage preview
var _garage_selected_car_id: String = "sedan"

const GARAGE_FLEET_DATA = {
	"sedan": {
		"id": "sedan",
		"name": "SEDAN PRIME",
		"class": "Executive Sport Sedan | 2.5L Turbo I4",
		"desc": "High-efficiency balanced executive platform with sport-tuned suspension and responsive rear-wheel drive handling.",
		"top_speed": "260 km/h",
		"ratio_speed": 0.72,
		"accel": "4.2 sec",
		"ratio_accel": 0.75,
		"power": "310 BHP",
		"ratio_power": 0.65,
		"handling": "88.0%",
		"ratio_handling": 0.88,
		"specs": "Engine: 2.5L Inline-4 Turbo | Drivetrain: RWD | Weight: 1,520 kg\n0-100 km/h: 4.2s | Brakes: Ventilated Discs | Gearbox: 6-Speed Manual",
		"price": "STARTER",
		"cost_coins": 0,
		"cost_gems": 0
	},
	"compact": {
		"id": "compact",
		"name": "URBAN COMPACT",
		"class": "Agile City Hatch | 1.6L Inline-4",
		"desc": "Ultra-nimble compact chassis engineered for tight city street racing and immediate cornering agility.",
		"top_speed": "235 km/h",
		"ratio_speed": 0.65,
		"accel": "5.1 sec",
		"ratio_accel": 0.68,
		"power": "210 BHP",
		"ratio_power": 0.55,
		"handling": "92.0%",
		"ratio_handling": 0.92,
		"specs": "Engine: 1.6L Naturally Aspirated | Drivetrain: FWD | Weight: 1,120 kg\n0-100 km/h: 5.1s | Suspension: MacPherson Strut | Turning Radius: 4.8m",
		"price": "5,000 COINS",
		"cost_coins": 5000,
		"cost_gems": 0
	},
	"hatchback": {
		"id": "hatchback",
		"name": "SPEED HATCHBACK",
		"class": "Hot Hatch | 2.0L Turbo FWD",
		"desc": "Track-focused performance hatchback featuring electronic limited-slip differential and aerodynamic roof spoiler.",
		"top_speed": "275 km/h",
		"ratio_speed": 0.76,
		"accel": "3.9 sec",
		"ratio_accel": 0.78,
		"power": "350 BHP",
		"ratio_power": 0.70,
		"handling": "91.5%",
		"ratio_handling": 0.915,
		"specs": "Engine: 2.0L Twin-Scroll Turbo | Drivetrain: FWD e-LSD | Weight: 1,360 kg\n0-100 km/h: 3.9s | Downforce: 45 kg at 200 km/h | Gearbox: 7-Speed Dual Clutch",
		"price": "12,000 COINS",
		"cost_coins": 12000,
		"cost_gems": 0
	},
	"coupe": {
		"id": "coupe",
		"name": "APEX COUPE",
		"class": "Sport Coupe | 3.0L Twin-Turbo RWD",
		"desc": "Classic rear-drive sports coupe with a low center of gravity, perfect 50:50 weight distribution, and high-revving turbo engine.",
		"top_speed": "295 km/h",
		"ratio_speed": 0.82,
		"accel": "3.5 sec",
		"ratio_accel": 0.82,
		"power": "420 BHP",
		"ratio_power": 0.78,
		"handling": "94.0%",
		"ratio_handling": 0.94,
		"specs": "Engine: 3.0L Twin-Turbo Inline-6 | Drivetrain: RWD LSD | Weight: 1,480 kg\n0-100 km/h: 3.5s | Weight Dist: 50/50 | Brakes: 4-Piston Monobloc",
		"price": "25,000 COINS",
		"cost_coins": 25000,
		"cost_gems": 0
	},
	"wagon": {
		"id": "wagon",
		"name": "TOURING WAGON",
		"class": "Grand Tourer Wagon | 3.5L V6 AWD",
		"desc": "Long-wheelbase high-speed highway touring vehicle equipped with active all-wheel drive stability control.",
		"top_speed": "285 km/h",
		"ratio_speed": 0.79,
		"accel": "4.0 sec",
		"ratio_accel": 0.76,
		"power": "390 BHP",
		"ratio_power": 0.74,
		"handling": "86.5%",
		"ratio_handling": 0.865,
		"specs": "Engine: 3.5L Naturally Aspirated V6 | Drivetrain: Permanent AWD | Weight: 1,680 kg\n0-100 km/h: 4.0s | Chassis: High-Rigidity Steel | Suspension: Adaptive Dampers",
		"price": "38,000 COINS",
		"cost_coins": 38000,
		"cost_gems": 0
	},
	"minivan": {
		"id": "minivan",
		"name": "TURBO MINIVAN",
		"class": "Sleeper Sport Van | 3.8L Twin-Turbo",
		"desc": "Custom tuned sleeper multi-purpose vehicle packing unexpected horsepower and wide track road presence.",
		"top_speed": "270 km/h",
		"ratio_speed": 0.75,
		"accel": "4.4 sec",
		"ratio_accel": 0.72,
		"power": "450 BHP",
		"ratio_power": 0.80,
		"handling": "83.0%",
		"ratio_handling": 0.83,
		"specs": "Engine: 3.8L Twin-Turbo V6 | Drivetrain: AWD | Weight: 1,890 kg\n0-100 km/h: 4.4s | Exhaust: Quad Titanium Tips | Boost: 1.4 Bar High Boost",
		"price": "45,000 COINS",
		"cost_coins": 45000,
		"cost_gems": 0
	},
	"suv": {
		"id": "suv",
		"name": "GRAND SUV",
		"class": "Luxury Performance SUV | 4.0L Twin-Turbo V8",
		"desc": "Imposing luxury sport utility machine with twin-turbocharged V8 muscle and adaptive air suspension.",
		"top_speed": "300 km/h",
		"ratio_speed": 0.83,
		"accel": "3.3 sec",
		"ratio_accel": 0.85,
		"power": "600 BHP",
		"ratio_power": 0.88,
		"handling": "85.0%",
		"ratio_handling": 0.85,
		"specs": "Engine: 4.0L Twin-Turbo V8 | Drivetrain: Performance AWD | Weight: 2,150 kg\n0-100 km/h: 3.3s | Suspension: 3-Chamber Adaptive Air | Wheels: 22-Inch Forged",
		"price": "60,000 COINS",
		"cost_coins": 60000,
		"cost_gems": 0
	},
	"pickup": {
		"id": "pickup",
		"name": "TITAN PICKUP",
		"class": "Heavy Duty Muscle Truck | 5.7L Supercharged V8",
		"desc": "Massive supercharged offroad power truck delivering relentless torque and reinforced steel boxed frame durability.",
		"top_speed": "265 km/h",
		"ratio_speed": 0.74,
		"accel": "4.1 sec",
		"ratio_accel": 0.74,
		"power": "650 BHP",
		"ratio_power": 0.90,
		"handling": "81.0%",
		"ratio_handling": 0.81,
		"specs": "Engine: 5.7L Supercharged HEMI V8 | Drivetrain: 4WD Selectable | Weight: 2,340 kg\n0-100 km/h: 4.1s | Shocks: 2.5-Inch Internal Bypass | Clearance: 280mm",
		"price": "75,000 COINS",
		"cost_coins": 75000,
		"cost_gems": 0
	},
	"offroad": {
		"id": "offroad",
		"name": "TRACKER 4X4",
		"class": "Extreme Trail 4x4 | Heavy Duty Crawler",
		"desc": "Purpose-built rock crawling and rally trail expedition vehicle with front and rear locking differentials.",
		"top_speed": "250 km/h",
		"ratio_speed": 0.69,
		"accel": "4.6 sec",
		"ratio_accel": 0.70,
		"power": "480 BHP",
		"ratio_power": 0.82,
		"handling": "84.0%",
		"ratio_handling": 0.84,
		"specs": "Engine: 4.2L High-Torque V6 | Drivetrain: Dual Locking 4x4 | Weight: 1,980 kg\nApproach Angle: 44 Deg | Winch: 12,000 lbs Synthetic | Tires: 33-Inch All-Terrain",
		"price": "95,000 COINS",
		"cost_coins": 95000,
		"cost_gems": 0
	},
	"sport": {
		"id": "sport",
		"name": "SUPER SPORT GT",
		"class": "Supercar Flagship | 5.2L Naturally Aspirated V10",
		"desc": "Ultra-lightweight aerodynamic flagship supercar delivering an exhilarating 9,000 RPM naturally aspirated scream and track-destroying performance.",
		"top_speed": "345 km/h",
		"ratio_speed": 0.96,
		"accel": "2.8 sec",
		"ratio_accel": 0.94,
		"power": "740 BHP",
		"ratio_power": 0.96,
		"handling": "97.5%",
		"ratio_handling": 0.975,
		"specs": "Engine: 5.2L Mid-Mounted V10 | Redline: 9,000 RPM | Weight: 1,380 kg Dry\n0-100 km/h: 2.8s | Aero: Active Dual Tunnel Diffuser | Brakes: Carbon Ceramic 380mm",
		"price": "150,000 COINS",
		"cost_coins": 150000,
		"cost_gems": 0
	},
	"mclaren": {
		"id": "mclaren",
		"name": "MCLAREN ARTURA SPIDER",
		"class": "Flagship Hybrid Supercar | 3.0L Twin-Turbo V6 Hybrid",
		"desc": "Ultimate high-performance British supercar engineered with carbon-fiber architecture, 690 BHP hybrid powertrain, and race-bred active aerodynamics.",
		"top_speed": "355 km/h",
		"ratio_speed": 1.0,
		"accel": "2.6 sec",
		"ratio_accel": 1.0,
		"power": "690 BHP",
		"ratio_power": 1.0,
		"handling": "99.0%",
		"ratio_handling": 0.99,
		"specs": "Engine: 3.0L 120-Deg Twin-Turbo V6 + E-Motor | Drivetrain: RWD E-Diff | Weight: 1,457 kg Dry\n0-100 km/h: 2.6s | Top Speed: 355 km/h | Brakes: Carbon Ceramic Matrix 390mm",
		"price": "350,000 COINS",
		"cost_coins": 350000,
		"cost_gems": 0
	},
	"kia_carnival": {
		"id": "kia_carnival",
		"name": "KIA CARNIVAL GT",
		"class": "Luxury Grand MPV | 3.5L Smartstream V6",
		"desc": "Executive VIP grand touring multi-purpose vehicle combining effortless high-speed highway cruising with advanced active safety architecture.",
		"top_speed": "245 km/h",
		"ratio_speed": 0.68,
		"accel": "5.3 sec",
		"ratio_accel": 0.66,
		"power": "290 BHP",
		"ratio_power": 0.62,
		"handling": "84.0%",
		"ratio_handling": 0.84,
		"specs": "Engine: 3.5L GDI V6 | Drivetrain: FWD | Weight: 2,080 kg\n0-100 km/h: 5.3s | Gearbox: 8-Speed Automatic | Wheelbase: 3,082 mm",
		"price": "42,000 COINS",
		"cost_coins": 42000,
		"cost_gems": 0
	},
	"kia_seltos": {
		"id": "kia_seltos",
		"name": "KIA SELTOS TURBO",
		"class": "Dynamic Compact SUV | 1.6L T-GDI AWD",
		"desc": "Agile turbocharged all-wheel-drive crossover engineered for rapid urban acceleration, confident bad-weather traction, and razor-sharp steering feedback.",
		"top_speed": "250 km/h",
		"ratio_speed": 0.70,
		"accel": "4.8 sec",
		"ratio_accel": 0.72,
		"power": "195 BHP",
		"ratio_power": 0.58,
		"handling": "89.0%",
		"ratio_handling": 0.89,
		"specs": "Engine: 1.6L Turbocharged Inline-4 | Drivetrain: Active AWD | Weight: 1,480 kg\n0-100 km/h: 4.8s | Transmission: 7-Speed Dual Clutch | Wheels: 18-Inch Diamond Cut",
		"price": "55,000 COINS",
		"cost_coins": 55000,
		"cost_gems": 0
	},
	"porsche_carrera_gt": {
		"id": "porsche_carrera_gt",
		"name": "PORSCHE CARRERA GT",
		"class": "Legendary V10 Supercar | 5.7L Mid-Mounted V10",
		"desc": "Pure analog motorsport perfection. Naturally aspirated 605 BHP racing V10, carbon-fiber monocoque chassis, manual beechwood shifter, and raw unassisted thrill.",
		"top_speed": "330 km/h",
		"ratio_speed": 0.93,
		"accel": "3.2 sec",
		"ratio_accel": 0.91,
		"power": "605 BHP",
		"ratio_power": 0.92,
		"handling": "97.0%",
		"ratio_handling": 0.97,
		"specs": "Engine: 5.7L 68-Deg V10 | Redline: 8,400 RPM | Drivetrain: RWD LSD | Weight: 1,380 kg Dry\n0-100 km/h: 3.2s | Clutch: Ceramic Composite (PCCC) | Monocoque: Full Carbon",
		"price": "400,000 COINS",
		"cost_coins": 400000,
		"cost_gems": 0
	},
	"porsche_mission_x": {
		"id": "porsche_mission_x",
		"name": "PORSCHE MISSION X",
		"class": "Next-Gen Hypercar Concept | 900V High-Downforce EV",
		"desc": "The ultimate hypercar beacon. 1:1 power-to-weight ratio, 1,500 BHP electric architecture, downforce values well in excess of current 911 GT3 RS, and extreme high-voltage fast charging.",
		"top_speed": "370 km/h",
		"ratio_speed": 1.0,
		"accel": "2.1 sec",
		"ratio_accel": 1.0,
		"power": "1500 BHP",
		"ratio_power": 1.0,
		"handling": "99.5%",
		"ratio_handling": 0.995,
		"specs": "Powertrain: Permanently Synchronous E-Motors | Voltage: 900V System | Weight: 1,520 kg\n0-100 km/h: 2.1s | Aero: Adaptive Ground Effect Tunnels | Power-to-Weight: 1 BHP / 1 kg",
		"price": "500,000 COINS",
		"cost_coins": 500000,
		"cost_gems": 0
	}
}

func _get_profile() -> Node:
	if not _profile_autoload and has_node("/root/PlayerProfile"):
		_profile_autoload = get_node("/root/PlayerProfile")
	return _profile_autoload

func _ready() -> void:
	# Ensure UI containers allow mouse drags through to 3D orbit camera
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if hud_root:
		hud_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if toast_panel:
		toast_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if profile_card:
		profile_card.offset_left = 35.0
		profile_card.offset_top = 30.0
		profile_card.offset_right = 540.0
		profile_card.offset_bottom = 210.0
		var card_bg = profile_card.get_node_or_null("CardBG") as TextureRect
		if card_bg:
			var bg_img = Image.load_from_file("res://assets/ui/textures/profile_card_clean_alpha.png")
			if bg_img:
				card_bg.texture = ImageTexture.create_from_image(bg_img)
		for child in profile_card.get_children():
			if child != card_bg:
				child.visible = false

	var left_grad = get_node_or_null("LeftLegibilityGradient")
	if left_grad:
		left_grad.visible = false
	var bot_grad = get_node_or_null("BottomGradient")
	if bot_grad:
		bot_grad.visible = false

	_nav_buttons = [play_btn, settings_btn, garage_btn, tuning_btn, paint_shop_btn, profile_btn]
	_connect_hud_signals()
	_connect_modal_buttons()
	_connect_settings_tabs()
	_connect_garage_system()
	_bind_player_profile()
	_setup_reference_widgets()
	if avatar_rect and not avatar_rect.texture:
		var a_img = Image.load_from_file("res://assets/ui/icons/avatar_pilot_racing.png")
		if a_img:
			avatar_rect.texture = ImageTexture.create_from_image(a_img)
	
	var prof = _get_profile()
	if prof:
		prof.connect("profile_updated", _on_profile_updated)
		prof.connect("currency_changed", _on_currency_changed)
		
	_on_profile_updated()
	_close_all_modals()
	
	if play_btn:
		play_btn.grab_focus()

func _setup_reference_widgets() -> void:
	if not hud_root: return
	
	# Hide legacy placeholder panels in HUD
	if profile_card:
		profile_card.visible = false
	if currency_pill:
		currency_pill.visible = false
	if gear_btn:
		gear_btn.visible = false
		
	# Clean any old reference cropped nodes from HUD
	for old_name in ["TopNavBar", "CurBG", "NotifPill", "MSPingLabel", "LimitedTimeEventCard", 
			"OnlineFriendsCard", "DailyMissionsCard", "MailCard", "NewsBanner", "VersionLabel", "SeasonPassCard",
			"NativeEventCard", "NativeFriendsCard"]:
		var old_node = hud_root.get_node_or_null(old_name)
		if old_node:
			old_node.queue_free()
			
	var p: PlayerProfileData = null
	var prof = _get_profile()
	if prof and prof.get("data"):
		p = prof.get("data")
	elif ResourceLoader.exists("res://data/player_profile.tres"):
		p = load("res://data/player_profile.tres") as PlayerProfileData

	# 1. Native Procedural Profile Card
	_profile_widget = hud_root.get_node_or_null("NativeProfileCard") as ProfileCardWidget
	if not _profile_widget:
		_profile_widget = ProfileCardWidget.new()
		_profile_widget.name = "NativeProfileCard"
		hud_root.add_child(_profile_widget)
		_profile_widget.pressed.connect(func(): open_modal(profile_modal))
	_profile_widget.offset_left = 35.0
	_profile_widget.offset_top = 26.0
	_profile_widget.offset_right = 540.0
	_profile_widget.offset_bottom = 206.0
	if p:
		_profile_widget.nickname = p.nickname
		_profile_widget.level = p.level
		_profile_widget.current_xp = p.current_xp
		_profile_widget.max_xp = p.max_xp

	# 2. Native Procedural Top Navigation Bar
	var top_bar = hud_root.get_node_or_null("NativeTopNavBar") as TopNavBar
	if not top_bar:
		top_bar = TopNavBar.new()
		top_bar.name = "NativeTopNavBar"
		hud_root.add_child(top_bar)
		top_bar.tab_selected.connect(func(tab_name: String):
			if tab_name == "HOME":
				_close_all_modals()
			else:
				show_toast("Fitur " + tab_name + " akan segera hadir!")
		)
	top_bar.offset_left = 586.0
	top_bar.offset_top = 37.0
	top_bar.offset_right = 1321.0
	top_bar.offset_bottom = 86.0

	# 3. Native Procedural Currency Bar
	_currency_widget = hud_root.get_node_or_null("NativeCurrencyBar") as CurrencyBar
	if not _currency_widget:
		_currency_widget = CurrencyBar.new()
		_currency_widget.name = "NativeCurrencyBar"
		hud_root.add_child(_currency_widget)
		_currency_widget.store_pressed.connect(func(): show_toast("Toko koin dan diamond akan segera hadir!"))
	_currency_widget.offset_left = 1345.0
	_currency_widget.offset_top = 34.0
	_currency_widget.offset_right = 1801.0
	_currency_widget.offset_bottom = 86.0
	if p:
		_currency_widget.coins = p.coins
		_currency_widget.gems = p.gems

	# 4. Native Hexagonal Settings Button
	var hex_gear = hud_root.get_node_or_null("NativeHexGear") as SettingsHexBtn
	if not hex_gear:
		hex_gear = SettingsHexBtn.new()
		hex_gear.name = "NativeHexGear"
		hud_root.add_child(hex_gear)
		hex_gear.pressed.connect(func(): open_modal(settings_modal))
	hex_gear.offset_left = 1812.0
	hex_gear.offset_top = 22.0
	hex_gear.offset_right = 1886.0
	hex_gear.offset_bottom = 96.0

	# 5. Native Notifications Pill & Ping Widget
	var notif_ping = hud_root.get_node_or_null("NativeNotifPing") as NotifPingWidget
	if not notif_ping:
		notif_ping = NotifPingWidget.new()
		notif_ping.name = "NativeNotifPing"
		hud_root.add_child(notif_ping)
		notif_ping.pressed.connect(func(): show_toast("Tidak ada notifikasi baru."))
	notif_ping.offset_left = 1570.0
	notif_ping.offset_top = 98.0
	notif_ping.offset_right = 1885.0
	notif_ping.offset_bottom = 142.0

	# (NativeEventCard and NativeFriendsCard removed as requested)

	# 8. Native Daily Missions Card
	var dm_card = hud_root.get_node_or_null("NativeDailyMissions") as DailyMissionsUI
	if not dm_card:
		dm_card = DailyMissionsUI.new()
		dm_card.name = "NativeDailyMissions"
		hud_root.add_child(dm_card)
		dm_card.pressed.connect(func(): show_toast("Daily Missions: 3/5 Selesai!"))
	dm_card.offset_left = 40.0
	dm_card.offset_top = 946.0
	dm_card.offset_right = 365.0
	dm_card.offset_bottom = 1040.0

	# 9. Native Mail Button
	var ml_btn = hud_root.get_node_or_null("NativeMailBtn") as MailBtnUI
	if not ml_btn:
		ml_btn = MailBtnUI.new()
		ml_btn.name = "NativeMailBtn"
		hud_root.add_child(ml_btn)
		ml_btn.pressed.connect(func(): show_toast("Kotak Masuk: 2 pesan belum dibaca."))
	ml_btn.offset_left = 360.0
	ml_btn.offset_top = 930.0
	ml_btn.offset_right = 480.0
	ml_btn.offset_bottom = 1040.0

	# 10. Native News Banner
	var nw_banner = hud_root.get_node_or_null("NativeNewsBanner") as NewsBannerUI
	if not nw_banner:
		nw_banner = NewsBannerUI.new()
		nw_banner.name = "NativeNewsBanner"
		hud_root.add_child(nw_banner)
		nw_banner.pressed.connect(func(): show_toast("Patch 1.4 Live: New Tracks & Cars!"))
	nw_banner.offset_left = 605.0
	nw_banner.offset_top = 940.0
	nw_banner.offset_right = 1335.0
	nw_banner.offset_bottom = 1040.0

	# 11. Version Label
	var ver_lbl = hud_root.get_node_or_null("VersionLabel") as Label
	if not ver_lbl:
		ver_lbl = Label.new()
		ver_lbl.name = "VersionLabel"
		hud_root.add_child(ver_lbl)
	ver_lbl.text = "v1.04.8"
	ver_lbl.offset_left = 1430.0
	ver_lbl.offset_top = 998.0
	ver_lbl.offset_right = 1515.0
	ver_lbl.offset_bottom = 1025.0
	if ResourceLoader.exists("res://assets/ui/fonts/Rajdhani-SemiBold.ttf"):
		ver_lbl.add_theme_font_override("font", load("res://assets/ui/fonts/Rajdhani-SemiBold.ttf"))
	ver_lbl.add_theme_font_size_override("font_size", 18)
	ver_lbl.add_theme_color_override("font_color", Color(0.65, 0.72, 0.80, 0.90))

	# 12. Native Season Pass Card
	var sp_card = hud_root.get_node_or_null("NativeSeasonPass") as SeasonPassUI
	if not sp_card:
		sp_card = SeasonPassUI.new()
		sp_card.name = "NativeSeasonPass"
		hud_root.add_child(sp_card)
		sp_card.pressed.connect(func(): show_toast("Season Pass Lv. 15 unlock tersedia!"))
	sp_card.offset_left = 1515.0
	sp_card.offset_top = 930.0
	sp_card.offset_right = 1895.0
	sp_card.offset_bottom = 1042.0

func _load_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path)
	var img = Image.load_from_file(path)
	if img and not img.is_empty():
		return ImageTexture.create_from_image(img)
	return null

func _connect_hud_signals() -> void:
	if play_btn:
		play_btn.pressed.connect(func(): open_modal(play_modal))
	if settings_btn:
		settings_btn.pressed.connect(func(): open_modal(settings_modal))
	if garage_btn:
		garage_btn.pressed.connect(func():
			_refresh_garage_ui()
			open_modal(garage_modal)
		)
	if tuning_btn:
		tuning_btn.pressed.connect(func(): open_modal(tuning_modal))
	if paint_shop_btn:
		paint_shop_btn.pressed.connect(func(): open_modal(paint_shop_modal))
	if profile_btn:
		profile_btn.pressed.connect(func(): open_modal(profile_modal))
		
	# Clicking profile card in HUD opens profile page
	if profile_card and profile_card.has_signal("gui_input"):
		profile_card.gui_input.connect(_on_profile_card_input)
		
	# Clicking currency pill in HUD opens topup store
	if currency_pill and currency_pill.has_signal("gui_input"):
		currency_pill.gui_input.connect(_on_currency_pill_input)
		
	if gear_btn:
		gear_btn.pressed.connect(func(): open_modal(settings_modal))

func _on_profile_card_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		open_modal(profile_modal)

func _on_currency_pill_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		open_modal(topup_modal)

func _find_all_buttons(node: Node) -> Array[Button]:
	var result: Array[Button] = []
	if not node:
		return result
	if node is Button:
		result.append(node)
	for child in node.get_children():
		result.append_array(_find_all_buttons(child))
	return result

static var _selected_fps_index: int = 1

func _connect_modal_buttons() -> void:
	# Profile Save / Cancel
	if profile_save_btn:
		profile_save_btn.pressed.connect(_on_profile_save_pressed)
	if profile_cancel_btn:
		profile_cancel_btn.pressed.connect(_on_profile_cancel_pressed)
		
	# Settings Quality & Display
	if quality_option:
		quality_option.item_selected.connect(_on_quality_selected)
	if fps_option:
		if _selected_fps_index >= 0 and _selected_fps_index < fps_option.item_count:
			fps_option.select(_selected_fps_index)
		fps_option.item_selected.connect(_on_fps_selected)
	if window_option:
		window_option.item_selected.connect(_on_window_mode_selected)
	if master_slider:
		master_slider.value_changed.connect(_on_master_volume_changed)

	# Settings Audio Sliders
	if music_slider:
		music_slider.value_changed.connect(func(val):
			var bus_idx = AudioServer.get_bus_index("Music")
			if bus_idx != -1: AudioServer.set_bus_volume_db(bus_idx, linear_to_db(val / 100.0))
		)
	if sfx_slider:
		sfx_slider.value_changed.connect(func(val):
			var bus_idx = AudioServer.get_bus_index("SFX")
			if bus_idx != -1: AudioServer.set_bus_volume_db(bus_idx, linear_to_db(val / 100.0))
		)
	if engine_slider:
		engine_slider.value_changed.connect(func(val):
			var bus_idx = AudioServer.get_bus_index("SFX")
			if bus_idx != -1: AudioServer.set_bus_volume_db(bus_idx, linear_to_db(val / 100.0))
		)

	# Wire all Close Buttons across all modals: [X] CLOSE
	if pages_layer:
		for b in _find_all_buttons(pages_layer):
			var txt = b.text.to_upper()
			if txt.contains("CLOSE") or txt.contains("[X]") or b.name.to_lower().contains("close"):
				if not b.pressed.is_connected(close_modal):
					b.pressed.connect(close_modal)

	# Play Modal Race Modes
	if play_modal:
		for b in _find_all_buttons(play_modal):
			if b.text.contains("GRAND PRIX"):
				b.pressed.connect(func():
					show_toast("[OK] Initializing Grand Prix 3D Circuit...")
					get_tree().change_scene_to_file("res://scenes/race/RaceTrack3D.tscn")
				)
			elif b.text.contains("TIME TRIAL"):
				b.pressed.connect(func():
					show_toast("[OK] Loading Ghost Telemetry for Time Trial...")
					get_tree().change_scene_to_file("res://scenes/race/RaceTrack3D.tscn")
				)
			elif b.text.contains("SPRINT RACE") or b.text.contains("STREET"):
				b.pressed.connect(func():
					show_toast("[OK] Starting Waterfront Street Sprint...")
					get_tree().change_scene_to_file("res://scenes/race/RaceTrack3D.tscn")
				)

	# Topup Modal Packages
	if topup_modal:
		for b in _find_all_buttons(topup_modal):
			if b.text.contains("+10K"):
				b.pressed.connect(func(): perform_topup(10000, 0, "STARTER PACK"))
			elif b.text.contains("+50K"):
				b.pressed.connect(func(): perform_topup(50000, 50, "RACER PACK"))
			elif b.text.contains("+250K"):
				b.pressed.connect(func(): perform_topup(250000, 250, "PRO MOTORSPORT"))
			elif b.text.contains("+100 GEMS"):
				b.pressed.connect(func(): perform_topup(0, 100, "GEM POUCH"))
			elif b.text.contains("+500 GEMS"):
				b.pressed.connect(func(): perform_topup(0, 500, "GEM CHEST"))
			elif b.text.contains("+1M"):
				b.pressed.connect(func(): perform_topup(1000000, 1000, "ULTIMATE VAULT"))

	# Tuning Modal Apply
	if tuning_modal:
		for b in _find_all_buttons(tuning_modal):
			if b.text.contains("APPLY"):
				b.pressed.connect(func():
					show_toast("[OK] Telemetry & Downforce Setup Saved!")
					close_modal()
				)

	# Paint Shop Modal Swatches
	if paint_shop_modal:
		for b in _find_all_buttons(paint_shop_modal):
			if b.text == "APPLY":
				var swatch_col: Color = Color(0.063, 0.094, 0.157, 1.0)
				var parent_node = b.get_parent()
				if parent_node:
					for child in parent_node.get_children():
						if child is ColorRect:
							swatch_col = child.color
							break
				b.pressed.connect(func(): select_paint_color(swatch_col))

# =============================================================================
# SETTINGS TABS SWITCHING
# =============================================================================
func _connect_settings_tabs() -> void:
	if tab_btn_display:
		tab_btn_display.pressed.connect(func(): _switch_settings_tab(0))
	if tab_btn_audio:
		tab_btn_audio.pressed.connect(func(): _switch_settings_tab(1))
	if tab_btn_assists:
		tab_btn_assists.pressed.connect(func(): _switch_settings_tab(2))
	if tab_btn_project:
		tab_btn_project.pressed.connect(func(): _switch_settings_tab(3))

func _switch_settings_tab(tab_index: int) -> void:
	if tab_panel_display: tab_panel_display.visible = (tab_index == 0)
	if tab_panel_audio: tab_panel_audio.visible = (tab_index == 1)
	if tab_panel_assists: tab_panel_assists.visible = (tab_index == 2)
	if tab_panel_project: tab_panel_project.visible = (tab_index == 3)

# =============================================================================
# GARAGE DEALERSHIP & FLEET SYSTEM
# =============================================================================
func _connect_garage_system() -> void:
	if not garage_modal: return
	
	if garage_car_list:
		for child in garage_car_list.get_children():
			child.queue_free()
			
		var font_bold = load("res://assets/ui/fonts/Rajdhani-Bold.ttf")
		var font_semi = load("res://assets/ui/fonts/Rajdhani-SemiBold.ttf")
		
		for car_id in GARAGE_FLEET_DATA.keys():
			var car_info = GARAGE_FLEET_DATA[car_id]
			var btn = Button.new()
			btn.name = "CarSelect_" + car_id
			btn.custom_minimum_size = Vector2(360, 84)
			btn.flat = true
			
			var s_norm = StyleBoxFlat.new()
			s_norm.bg_color = Color(0.04, 0.08, 0.16, 0.85)
			s_norm.border_width_left = 4
			s_norm.border_color = Color(0.2, 0.5, 0.9, 0.6)
			s_norm.corner_radius_top_left = 6
			s_norm.corner_radius_top_right = 6
			s_norm.corner_radius_bottom_right = 6
			s_norm.corner_radius_bottom_left = 6
			btn.add_theme_stylebox_override("normal", s_norm)
			
			var s_hov = s_norm.duplicate()
			s_hov.bg_color = Color(0.08, 0.16, 0.32, 0.95)
			s_hov.border_color = Color(0.3, 0.7, 1.0, 1.0)
			s_hov.border_width_left = 6
			btn.add_theme_stylebox_override("hover", s_hov)
			
			var s_press = s_norm.duplicate()
			s_press.bg_color = Color(0.12, 0.24, 0.48, 0.95)
			btn.add_theme_stylebox_override("pressed", s_press)
			
			var name_lbl = Label.new()
			name_lbl.name = "NameLabel"
			name_lbl.text = car_info["name"]
			name_lbl.position = Vector2(16, 8)
			if font_bold: name_lbl.add_theme_font_override("font", font_bold)
			name_lbl.add_theme_font_size_override("font_size", 18)
			name_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 1))
			btn.add_child(name_lbl)
			
			var class_lbl = Label.new()
			class_lbl.name = "ClassLabel"
			class_lbl.text = car_info["class"]
			class_lbl.position = Vector2(16, 32)
			if font_semi: class_lbl.add_theme_font_override("font", font_semi)
			class_lbl.add_theme_font_size_override("font_size", 12)
			class_lbl.add_theme_color_override("font_color", Color(0.65, 0.72, 0.85, 0.8))
			btn.add_child(class_lbl)
			
			var ptag = Label.new()
			ptag.name = "PriceTag"
			ptag.text = car_info["price"]
			ptag.position = Vector2(16, 54)
			if font_bold: ptag.add_theme_font_override("font", font_bold)
			ptag.add_theme_font_size_override("font_size", 13)
			ptag.add_theme_color_override("font_color", Color(1.0, 0.788, 0.157, 1.0))
			btn.add_child(ptag)
			
			var target_id = car_id
			btn.pressed.connect(func():
				_garage_selected_car_id = target_id
				var showcase = _get_showcase_car()
				if showcase and showcase.has_method("load_car_model"):
					showcase.load_car_model(target_id)
				_refresh_garage_ui()
			)
			garage_car_list.add_child(btn)
			
	if garage_action_btn:
		garage_action_btn.pressed.connect(_on_garage_action_pressed)

func _refresh_garage_ui() -> void:
	var prof = _get_profile()
	var p: PlayerProfileData = prof.get("data") if prof else null
	if not p and ResourceLoader.exists("res://data/player_profile.tres"):
		p = load("res://data/player_profile.tres") as PlayerProfileData
	
	var equipped = p.equipped_car if p else "sedan"
	var unlocked = p.unlocked_cars if p else ["sedan"]
	
	# Update left list badges
	for car_id in GARAGE_FLEET_DATA.keys():
		var btn = garage_modal.find_child("CarSelect_" + car_id, true, false) as Button
		if btn:
			var ptag = btn.find_child("PriceTag", true, false) as Label
			if ptag:
				if car_id == equipped:
					ptag.text = "[EQUIPPED]"
					ptag.add_theme_color_override("font_color", Color(0.3, 0.9, 0.5, 1.0))
				elif unlocked.has(car_id):
					ptag.text = "[OWNED]"
					ptag.add_theme_color_override("font_color", Color(0.35, 0.75, 1.0, 1.0))
				else:
					var cd = GARAGE_FLEET_DATA[car_id]
					ptag.text = cd.get("price", "LOCKED")
					ptag.add_theme_color_override("font_color", Color(1.0, 0.788, 0.157, 1.0))
					
	# Update right panel details for _garage_selected_car_id
	if not GARAGE_FLEET_DATA.has(_garage_selected_car_id):
		_garage_selected_car_id = "sedan"
	var car = GARAGE_FLEET_DATA[_garage_selected_car_id]
	
	if garage_car_title: garage_car_title.text = car["name"]
	if garage_car_class: garage_car_class.text = car["class"]
	if garage_car_desc: garage_car_desc.text = car["desc"]
	if garage_bar_top_speed: garage_bar_top_speed.value = car["ratio_speed"]
	if garage_bar_top_speed_val: garage_bar_top_speed_val.text = car["top_speed"]
	if garage_bar_accel: garage_bar_accel.value = car["ratio_accel"]
	if garage_bar_accel_val: garage_bar_accel_val.text = car["accel"]
	if garage_bar_power: garage_bar_power.value = car["ratio_power"]
	if garage_bar_power_val: garage_bar_power_val.text = car["power"]
	if garage_bar_handling: garage_bar_handling.value = car["ratio_handling"]
	if garage_bar_handling_val: garage_bar_handling_val.text = car["handling"]
	if garage_spec_details: garage_spec_details.text = car["specs"]
	
	# Status & Action Button State
	if _garage_selected_car_id == equipped:
		if garage_status_label:
			garage_status_label.text = "STATUS: [CURRENTLY EQUIPPED FOR RACE]"
			garage_status_label.add_theme_color_override("font_color", Color(0.3, 0.9, 0.5, 1.0))
		if garage_action_btn:
			garage_action_btn.text = "[EQUIPPED]"
			garage_action_btn.disabled = true
	elif unlocked.has(_garage_selected_car_id):
		if garage_status_label:
			garage_status_label.text = "STATUS: [OWNED | READY TO EQUIP]"
			garage_status_label.add_theme_color_override("font_color", Color(0.35, 0.75, 1.0, 1.0))
		if garage_action_btn:
			garage_action_btn.text = "[EQUIP THIS VEHICLE]"
			garage_action_btn.disabled = false
	else:
		if garage_status_label:
			garage_status_label.text = "STATUS: [LOCKED | REQUIRES PURCHASE]"
			garage_status_label.add_theme_color_override("font_color", Color(1.0, 0.788, 0.157, 1.0))
		if garage_action_btn:
			if car["cost_coins"] > 0:
				garage_action_btn.text = "[PURCHASE - %s COINS]" % _format_number(car["cost_coins"])
			else:
				garage_action_btn.text = "[PURCHASE - %d GEMS]" % car["cost_gems"]
			garage_action_btn.disabled = false

func _on_garage_action_pressed() -> void:
	var prof = _get_profile()
	if not prof: return
	var p: PlayerProfileData = prof.data
	if not p: return
	
	var car = GARAGE_FLEET_DATA.get(_garage_selected_car_id)
	if not car: return
	
	if p.equipped_car == _garage_selected_car_id:
		return
	elif p.unlocked_cars.has(_garage_selected_car_id):
		prof.equip_car(_garage_selected_car_id)
		if has_node("/root/SaveManager"):
			var sm = get_node("/root/SaveManager")
			if sm.has_method("select_car"):
				sm.select_car(_garage_selected_car_id)
		var showcase = _get_showcase_car()
		if showcase and showcase.has_method("load_car_model"):
			showcase.load_car_model(_garage_selected_car_id)
		car_equipped.emit(_garage_selected_car_id)
		show_toast("[OK] Equipped " + car["name"] + " for race!")
		_refresh_garage_ui()
	else:
		var cost_c = car["cost_coins"]
		var cost_g = car["cost_gems"]
		if p.coins >= cost_c and p.gems >= cost_g:
			var success = prof.buy_car(_garage_selected_car_id, cost_c, cost_g)
			if success:
				if has_node("/root/SaveManager"):
					var sm = get_node("/root/SaveManager")
					if sm.has_method("unlock_car"):
						sm.unlock_car(_garage_selected_car_id)
					if sm.has_method("select_car"):
						sm.select_car(_garage_selected_car_id)
				var showcase = _get_showcase_car()
				if showcase and showcase.has_method("load_car_model"):
					showcase.load_car_model(_garage_selected_car_id)
				car_equipped.emit(_garage_selected_car_id)
				show_toast("[OK] Purchased and equipped " + car["name"] + "!")
				_refresh_garage_ui()
		else:
			var missing = ""
			if p.coins < cost_c: missing = str(cost_c - p.coins) + " Coins"
			if p.gems < cost_g:
				if not missing.is_empty(): missing += " and "
				missing += str(cost_g - p.gems) + " Gems"
			show_toast("[!] Insufficient funds! Need " + missing + ". Visit Top-Up.")

# =============================================================================
# PROFILE & HUD BINDINGS
# =============================================================================
func _bind_player_profile() -> void:
	var prof = _get_profile()
	var p: PlayerProfileData = prof.get("data") if prof else null
	if not p and ResourceLoader.exists("res://data/player_profile.tres"):
		p = load("res://data/player_profile.tres") as PlayerProfileData
	if not p:
		if avatar_rect and ResourceLoader.exists("res://assets/ui/icons/avatar_pilot_racing.png"):
			avatar_rect.texture = load("res://assets/ui/icons/avatar_pilot_racing.png")
		return
		
	var font_bold = load("res://assets/ui/fonts/Rajdhani-Bold.ttf")
	var font_semi = load("res://assets/ui/fonts/Rajdhani-SemiBold.ttf")

	if nickname_label:
		nickname_label.text = p.nickname
		if font_bold: nickname_label.add_theme_font_override("font", font_bold)
		nickname_label.add_theme_font_size_override("font_size", 32)
		nickname_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
		nickname_label.add_theme_color_override("font_outline_color", Color(0.04, 0.08, 0.22, 1.0))
		nickname_label.add_theme_constant_override("outline_size", 4)
	if level_label:
		level_label.text = "Lv. " + str(p.level)
		if font_bold: level_label.add_theme_font_override("font", font_bold)
		level_label.add_theme_font_size_override("font_size", 26)
		level_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
		level_label.add_theme_color_override("font_outline_color", Color(0.12, 0.16, 0.32, 1.0))
		level_label.add_theme_constant_override("outline_size", 4)
	if coin_label:
		coin_label.text = _format_number(p.coins)
	if gem_label:
		gem_label.text = _format_number(p.gems)
	if xp_bar:
		xp_bar.max_value = p.max_xp
		xp_bar.value = 0.0
		var tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(xp_bar, "value", float(p.current_xp), 0.6)
	if xp_label:
		xp_label.text = "%s / %s XP" % [_format_number(p.current_xp), _format_number(p.max_xp)]
		if font_bold: xp_label.add_theme_font_override("font", font_bold)
		xp_label.add_theme_font_size_override("font_size", 14)
		xp_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
		
	if _profile_widget:
		_profile_widget.nickname = p.nickname
		_profile_widget.level = p.level
		_profile_widget.current_xp = p.current_xp
		_profile_widget.max_xp = p.max_xp
		_profile_widget.queue_redraw()
	if _currency_widget:
		_currency_widget.coins = p.coins
		_currency_widget.gems = p.gems
		_currency_widget.queue_redraw()
		xp_label.add_theme_color_override("font_outline_color", Color(0.04, 0.08, 0.22, 1.0))
		xp_label.add_theme_constant_override("outline_size", 2)
	if avatar_rect:
		if ResourceLoader.exists(p.avatar_path):
			avatar_rect.texture = load(p.avatar_path)
		elif ResourceLoader.exists("res://assets/ui/icons/avatar_pilot_racing.png"):
			avatar_rect.texture = load("res://assets/ui/icons/avatar_pilot_racing.png")
		
	if profile_name_edit:
		profile_name_edit.text = p.nickname

func _on_profile_updated() -> void:
	_bind_player_profile()
	if avatar_rect and not avatar_rect.texture:
		var a_img = Image.load_from_file("res://assets/ui/icons/avatar_pilot_racing.png")
		if a_img:
			avatar_rect.texture = ImageTexture.create_from_image(a_img)

func _on_currency_changed(coins: int, gems: int) -> void:
	if coin_label:
		coin_label.text = _format_number(coins)
	if gem_label:
		gem_label.text = _format_number(gems)
	if _currency_widget:
		_currency_widget.coins = coins
		_currency_widget.gems = gems
		_currency_widget.queue_redraw()

## Modal Management
func open_modal(modal: Control) -> void:
	if not modal: return
	_close_all_modals()
	if pages_layer:
		pages_layer.visible = true
	_active_modal = modal
	modal.visible = true
	modal.modulate.a = 0.0
	var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(modal, "modulate:a", 1.0, 0.2)
	
	# If profile modal, fill current nickname in input
	if modal == profile_modal and profile_name_edit:
		var prof = _get_profile()
		if prof and prof.data:
			profile_name_edit.text = prof.data.nickname
	elif modal == garage_modal:
		var prof = _get_profile()
		if prof and prof.data:
			_garage_selected_car_id = prof.data.equipped_car
		_refresh_garage_ui()

func close_modal() -> void:
	if _active_modal == garage_modal:
		var prof = _get_profile()
		var eq = prof.data.equipped_car if prof and prof.data else "sedan"
		var showcase = _get_showcase_car()
		if showcase and showcase.has_method("load_car_model"):
			showcase.load_car_model(eq)
	if pages_layer:
		pages_layer.visible = false
	if _active_modal:
		var target = _active_modal
		_active_modal = null
		target.visible = false
	if play_btn:
		play_btn.grab_focus()

func _get_showcase_car() -> Node3D:
	if get_tree() and get_tree().current_scene:
		var car = get_tree().current_scene.get_node_or_null("ShowcaseCar") as Node3D
		if car: return car
	var parent_node = get_parent()
	while parent_node:
		var car = parent_node.get_node_or_null("ShowcaseCar") as Node3D
		if car: return car
		parent_node = parent_node.get_parent()
	if get_tree() and get_tree().root:
		return get_tree().root.find_child("ShowcaseCar", true, false) as Node3D
	return null

func _close_all_modals() -> void:
	if pages_layer:
		pages_layer.visible = false
	var modals = [settings_modal, profile_modal, topup_modal, garage_modal, tuning_modal, paint_shop_modal, play_modal]
	for m in modals:
		if m:
			m.visible = false
			m.modulate.a = 1.0
	_active_modal = null

## Profile Actions
func _on_profile_save_pressed() -> void:
	var new_name = profile_name_edit.text.strip_edges()
	if new_name.is_empty():
		show_toast("[!] Nickname cannot be empty!")
		return
	var prof = _get_profile()
	if prof and prof.data:
		prof.data.nickname = new_name
		prof.save_profile()
		prof.profile_updated.emit()
	show_toast("[OK] Pilot callsign updated to " + new_name + "!")
	close_modal()

func _on_profile_cancel_pressed() -> void:
	var prof = _get_profile()
	if prof and prof.data and profile_name_edit:
		profile_name_edit.text = prof.data.nickname
	close_modal()

## Topup Purchases (Offline Demo)
func perform_topup(coin_amount: int, gem_amount: int, package_name: String) -> void:
	var prof = _get_profile()
	if prof:
		prof.add_currency(coin_amount, gem_amount)
	var msg = "+" + _format_number(coin_amount) + " Coins" if coin_amount > 0 else ""
	if gem_amount > 0:
		if not msg.is_empty(): msg += " & "
		msg += "+" + str(gem_amount) + " Gems"
	show_toast("[OK] Top-up credited: " + msg)

## Paint Shop Color Swatch
func select_paint_color(color: Color) -> void:
	paint_color_selected.emit(color)
	var prof = _get_profile()
	if prof and prof.data:
		prof.data.custom_paint_color = color
		prof.save_profile()
	var car = _get_showcase_car()
	if car and car.has_method("set_paint_color"):
		car.set_paint_color(color)
	show_toast("[OK] Custom livery paint coat applied!")

func apply_paint_color(color: Color) -> void:
	select_paint_color(color)

## Settings Actions
func _on_quality_selected(index: int) -> void:
	if has_node("/root/QualitySettings"):
		var qs = get_node("/root/QualitySettings")
		qs.set_tier_by_index(index)
	show_toast("[OK] Graphics profile set to " + quality_option.get_item_text(index))

func _on_fps_selected(index: int) -> void:
	_selected_fps_index = index
	Engine.physics_jitter_fix = 0.0
	var screen_hz: float = DisplayServer.screen_get_refresh_rate()
	match index:
		0:
			# 30 FPS: disable VSync so software limiter paces cleanly at 33.33ms without double-vblank judder
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
			Engine.max_fps = 30
		1:
			# 60 FPS: use native VSync only on 60Hz displays; on 120/144Hz+ disable VSync to prevent uneven frame pacing
			if screen_hz > 0.0 and absf(screen_hz - 60.0) <= 2.0:
				DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
				Engine.max_fps = 0
			else:
				DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
				Engine.max_fps = 60
		2:
			# 120 FPS: use native VSync only on 120Hz displays; on 60/144Hz+ disable VSync to eliminate 3:2 pulldown stutter
			if screen_hz > 0.0 and absf(screen_hz - 120.0) <= 2.0:
				DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
				Engine.max_fps = 0
			else:
				DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
				Engine.max_fps = 120
		3:
			# Unlimited FPS
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
			Engine.max_fps = 0
	show_toast("[OK] Frame Rate Target locked to " + fps_option.get_item_text(index))

func _on_window_mode_selected(index: int) -> void:
	match index:
		0: DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		1: DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		2: DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)

func _on_master_volume_changed(val: float) -> void:
	var bus_idx = AudioServer.get_bus_index("Master")
	if bus_idx != -1:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(val / 100.0))

## Toast Notification System
func show_toast(text: String) -> void:
	if not toast_panel or not toast_label: return
	toast_label.text = text
	toast_panel.visible = true
	toast_panel.modulate.a = 0.0
	
	if _toast_tween and _toast_tween.is_valid():
		_toast_tween.kill()
		
	_toast_tween = create_tween()
	_toast_tween.tween_property(toast_panel, "modulate:a", 1.0, 0.2)
	_toast_tween.tween_interval(2.2)
	_toast_tween.tween_property(toast_panel, "modulate:a", 0.0, 0.3)
	_toast_tween.tween_callback(func(): toast_panel.visible = false)

func _format_number(val: int) -> String:
	var s = str(abs(val))
	var res = ""
	var count = 0
	for i in range(s.length() - 1, -1, -1):
		res = s[i] + res
		count += 1
		if count % 3 == 0 and i > 0:
			res = "," + res
	return ("-" if val < 0 else "") + res

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if _active_modal:
			close_modal()
			get_viewport().set_input_as_handled()
		else:
			back_pressed.emit()
	elif not _active_modal:
		if event.is_action_pressed("ui_down"):
			_move_focus(1)
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_up"):
			_move_focus(-1)
			get_viewport().set_input_as_handled()

func _move_focus(dir: int) -> void:
	_current_focus_index = posmod(_current_focus_index + dir, _nav_buttons.size())
	var target = _nav_buttons[_current_focus_index]
	if target:
		target.grab_focus()
