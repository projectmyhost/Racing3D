extends Control

signal closed

@onready var title_label: Label = $Dimmer/CenterContainer/Card/VBoxContainer/HeaderMargin/HBoxContainer/TitleLabel
@onready var subtitle_label: Label = $Dimmer/CenterContainer/Card/VBoxContainer/HeaderMargin/HBoxContainer/SubtitleLabel
@onready var disclaimer_label: Label = $Dimmer/CenterContainer/Card/VBoxContainer/DisclaimerMargin/DisclaimerLabel
@onready var current_balance_label: Label = $Dimmer/CenterContainer/Card/VBoxContainer/BalanceMargin/HBoxContainer/BalanceValueLabel
@onready var balance_icon: Label = $Dimmer/CenterContainer/Card/VBoxContainer/BalanceMargin/HBoxContainer/BalanceIcon
@onready var coins_tab_btn: Button = $Dimmer/CenterContainer/Card/VBoxContainer/TabsContainer/CoinsTabBtn
@onready var diamonds_tab_btn: Button = $Dimmer/CenterContainer/Card/VBoxContainer/TabsContainer/DiamondsTabBtn

@onready var coins_grid: GridContainer = $Dimmer/CenterContainer/Card/VBoxContainer/ContentMargin/CoinsGrid
@onready var diamonds_grid: GridContainer = $Dimmer/CenterContainer/Card/VBoxContainer/ContentMargin/DiamondsGrid

@onready var close_btn: Button = $Dimmer/CenterContainer/Card/VBoxContainer/HeaderMargin/HBoxContainer/CloseBtn

# Buttons for Coins
@onready var btn_coin_250: Button = $Dimmer/CenterContainer/Card/VBoxContainer/ContentMargin/CoinsGrid/Card250/VBox/ClaimBtn
@onready var btn_coin_1000: Button = $Dimmer/CenterContainer/Card/VBoxContainer/ContentMargin/CoinsGrid/Card1000/VBox/ClaimBtn
@onready var btn_coin_5000: Button = $Dimmer/CenterContainer/Card/VBoxContainer/ContentMargin/CoinsGrid/Card5000/VBox/ClaimBtn

# Buttons for Diamonds
@onready var btn_dia_10: Button = $Dimmer/CenterContainer/Card/VBoxContainer/ContentMargin/DiamondsGrid/Card10/VBox/ClaimBtn
@onready var btn_dia_25: Button = $Dimmer/CenterContainer/Card/VBoxContainer/ContentMargin/DiamondsGrid/Card25/VBox/ClaimBtn
@onready var btn_dia_50: Button = $Dimmer/CenterContainer/Card/VBoxContainer/ContentMargin/DiamondsGrid/Card50/VBox/ClaimBtn

var current_mode: String = "coins" # "coins" or "diamonds"
var _is_processing: bool = false

func _ready() -> void:
	if has_node("/root/Navigation"):
		get_node("/root/Navigation").register_modal(self)

	close_btn.pressed.connect(close)
	coins_tab_btn.pressed.connect(func(): set_mode("coins"))
	diamonds_tab_btn.pressed.connect(func(): set_mode("diamonds"))

	btn_coin_250.pressed.connect(func(): _claim_coins(250))
	btn_coin_1000.pressed.connect(func(): _claim_coins(1000))
	btn_coin_5000.pressed.connect(func(): _claim_coins(5000))

	btn_dia_10.pressed.connect(func(): _claim_diamonds(10))
	btn_dia_25.pressed.connect(func(): _claim_diamonds(25))
	btn_dia_50.pressed.connect(func(): _claim_diamonds(50))

	if has_node("/root/SaveManager"):
		get_node("/root/SaveManager").currency_changed.connect(_update_balance_display)

	set_mode(current_mode)
	_update_balance_display()

func set_mode(mode: String) -> void:
	current_mode = mode
	if current_mode == "coins":
		title_label.text = "FREE COIN CENTER"
		if has_node("/root/Localization"):
			title_label.text = get_node("/root/Localization").get_string("FREE_COINS")
		disclaimer_label.text = "Offline demo — all coin packs are completely free to claim."
		balance_icon.text = "🪙"
		coins_grid.visible = true
		diamonds_grid.visible = false
		coins_tab_btn.modulate = Color(1.0, 0.8, 0.2, 1.0)
		diamonds_tab_btn.modulate = Color(0.7, 0.7, 0.7, 1.0)
	else:
		title_label.text = "FREE DIAMOND CENTER"
		if has_node("/root/Localization"):
			title_label.text = get_node("/root/Localization").get_string("FREE_DIAMONDS")
		disclaimer_label.text = "Offline demo — no real money or external payment needed."
		balance_icon.text = "💎"
		coins_grid.visible = false
		diamonds_grid.visible = true
		coins_tab_btn.modulate = Color(0.7, 0.7, 0.7, 1.0)
		diamonds_tab_btn.modulate = Color(0.2, 0.8, 1.0, 1.0)
	
	_update_balance_display()

func _update_balance_display() -> void:
	if not has_node("/root/SaveManager"):
		return
	var sm = get_node("/root/SaveManager")
	if current_mode == "coins":
		current_balance_label.text = "Current Coins: " + sm.format_currency(sm.get_coins())
	else:
		current_balance_label.text = "Current Diamonds: " + sm.format_currency(sm.get_diamonds())

func _claim_coins(amount: int) -> void:
	if _is_processing:
		return
	_is_processing = true

	if has_node("/root/SaveManager"):
		var sm = get_node("/root/SaveManager")
		sm.add_coins(amount)
		if has_node("/root/ToastManager"):
			get_node("/root/ToastManager").show_success("+%s Coins added to balance!" % sm.format_currency(amount))
	
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_click_sfx()

	_update_balance_display()
	await get_tree().create_timer(0.15).timeout
	_is_processing = false

func _claim_diamonds(amount: int) -> void:
	if _is_processing:
		return
	_is_processing = true

	if has_node("/root/SaveManager"):
		var sm = get_node("/root/SaveManager")
		sm.add_diamonds(amount)
		if has_node("/root/ToastManager"):
			get_node("/root/ToastManager").show_success("+%s Diamonds added to balance!" % sm.format_currency(amount))

	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_click_sfx()

	_update_balance_display()
	await get_tree().create_timer(0.15).timeout
	_is_processing = false

func on_cancel_pressed() -> void:
	close()

func close() -> void:
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_click_sfx()
	if has_node("/root/Navigation"):
		get_node("/root/Navigation").unregister_modal(self)
	emit_signal("closed")
	queue_free()
