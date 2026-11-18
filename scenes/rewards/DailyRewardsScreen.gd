extends Control

signal daily_reward_claimed

@onready var title_label: Label = $Dimmer/CenterContainer/Card/VBox/HeaderMargin/HBox/TitleLabel
@onready var back_btn: Button = $Dimmer/CenterContainer/Card/VBox/HeaderMargin/HBox/CloseBtn
@onready var days_container: HBoxContainer = $Dimmer/CenterContainer/Card/VBox/CalendarMargin/DaysHBox
@onready var streak_label: Label = $Dimmer/CenterContainer/Card/VBox/StreakMargin/StreakLabel
@onready var status_info_label: Label = $Dimmer/CenterContainer/Card/VBox/ActionMargin/VBox/StatusInfoLabel
@onready var claim_today_btn: Button = $Dimmer/CenterContainer/Card/VBox/ActionMargin/VBox/ClaimTodayBtn

const DAILY_REWARDS: Array[int] = [100, 150, 200, 250, 300, 400, 750]

var current_streak: int = 0
var last_claim_date: String = ""
var can_claim_today: bool = false
var today_day_index: int = 0 # 0 to 6

func _ready() -> void:
	if has_node("/root/Navigation"):
		get_node("/root/Navigation").register_modal(self)

	back_btn.pressed.connect(close)
	claim_today_btn.pressed.connect(_on_claim_today_pressed)

	_evaluate_login_state()
	_update_ui()

	if has_node("/root/Localization"):
		title_label.text = get_node("/root/Localization").get_string("DAILY_LOGIN")

func _get_today_str() -> String:
	return Time.get_date_string_from_system()

func _evaluate_login_state() -> void:
	if not has_node("/root/SaveManager"):
		return
	var sm = get_node("/root/SaveManager")
	var prog = sm.get_progress()

	current_streak = int(prog.get("daily_streak", 0))
	last_claim_date = str(prog.get("last_daily_claim", ""))

	var today_str = _get_today_str()

	if last_claim_date == today_str:
		can_claim_today = false
		today_day_index = posmod(current_streak - 1, 7)
	else:
		can_claim_today = true
		# Check if streak was broken (missed more than 1 day)
		if last_claim_date != "":
			var last_unix = _date_string_to_unix(last_claim_date)
			var now_unix = _date_string_to_unix(today_str)
			var day_diff = (now_unix - last_unix) / 86400
			if day_diff > 1:
				# Missed a day -> reset streak to 0
				current_streak = 0
		
		today_day_index = current_streak % 7

func _date_string_to_unix(date_str: String) -> int:
	var parts = date_str.split("-")
	if parts.size() == 3:
		var d = {
			"year": int(parts[0]),
			"month": int(parts[1]),
			"day": int(parts[2]),
			"hour": 0,
			"minute": 0,
			"second": 0
		}
		return Time.get_unix_time_from_datetime_dict(d)
	return 0

func _update_ui() -> void:
	streak_label.text = "🔥 Current Streak: %d Day%s" % [current_streak, ("s" if current_streak != 1 else "")]

	var day_cards = days_container.get_children()
	for i in range(day_cards.size()):
		var card = day_cards[i]
		var reward_val = DAILY_REWARDS[i]
		var val_label = card.get_node_or_null("VBox/AmountLabel")
		var icon_label = card.get_node_or_null("VBox/IconLabel")
		var status_label = card.get_node_or_null("VBox/StatusLabel")
		var day_num_label = card.get_node_or_null("VBox/DayLabel")

		if val_label:
			val_label.text = "+%d" % reward_val
		if day_num_label:
			day_num_label.text = "DAY %d" % (i + 1)

		if i < today_day_index or (i == today_day_index and not can_claim_today):
			# Already claimed
			card.modulate = Color(0.65, 0.65, 0.65, 0.9)
			if status_label:
				status_label.text = "CLAIMED ✓"
				status_label.modulate = Color(0.4, 0.9, 0.4, 1.0)
			if icon_label:
				icon_label.text = "✓"
		elif i == today_day_index and can_claim_today:
			# Ready to claim today
			card.modulate = Color(1.0, 1.0, 1.0, 1.0)
			if status_label:
				status_label.text = "READY!"
				status_label.modulate = Color(1.0, 0.85, 0.2, 1.0)
			if icon_label:
				icon_label.text = "🎁" if i < 6 else "🏆"
		else:
			# Upcoming / Locked
			card.modulate = Color(0.45, 0.45, 0.52, 0.8)
			if status_label:
				status_label.text = "LOCKED"
				status_label.modulate = Color(0.6, 0.6, 0.7, 1.0)
			if icon_label:
				icon_label.text = "🔒"

	if can_claim_today:
		var reward_val = DAILY_REWARDS[today_day_index]
		claim_today_btn.text = "CLAIM TODAY (+%d COINS)" % reward_val
		claim_today_btn.disabled = false
		claim_today_btn.is_primary = true
		status_info_label.text = "Your Day %d reward is ready to claim!" % (today_day_index + 1)
		status_info_label.modulate = Color(1.0, 0.85, 0.2, 1.0)
	else:
		claim_today_btn.text = "CLAIMED TODAY ✓"
		claim_today_btn.disabled = true
		claim_today_btn.is_primary = false
		status_info_label.text = "Come back tomorrow for Day %d reward!" % (((today_day_index + 1) % 7) + 1)
		status_info_label.modulate = Color(0.7, 0.7, 0.8, 1.0)

func _on_claim_today_pressed() -> void:
	if not can_claim_today:
		return

	var reward_coins = DAILY_REWARDS[today_day_index]
	current_streak += 1
	last_claim_date = _get_today_str()
	can_claim_today = false

	if has_node("/root/SaveManager"):
		var sm = get_node("/root/SaveManager")
		sm.add_coins(reward_coins)
		sm.current_data.progress.daily_streak = current_streak
		sm.current_data.progress.last_daily_claim = last_claim_date
		sm.save_data()

		if has_node("/root/ToastManager"):
			get_node("/root/ToastManager").show_success("+%d Coins claimed! Streak: %d days" % [reward_coins, current_streak])

	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_click_sfx()

	_update_ui()
	emit_signal("daily_reward_claimed")

func on_cancel_pressed() -> void:
	close()

func close() -> void:
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_click_sfx()
	if has_node("/root/Navigation"):
		get_node("/root/Navigation").unregister_modal(self)
	queue_free()
