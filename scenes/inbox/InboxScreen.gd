extends Control

signal inbox_updated

@onready var title_label: Label = $MarginContainer/VBoxContainer/Header/HBox/TitleLabel
@onready var back_button: Button = $MarginContainer/VBoxContainer/Header/HBox/BackButton
@onready var mark_all_read_btn: Button = $MarginContainer/VBoxContainer/Header/HBox/MarkAllReadBtn

@onready var msg_list_container: VBoxContainer = $MarginContainer/VBoxContainer/BodyHBox/ListPanel/ScrollContainer/MessagesList
@onready var detail_panel: PanelContainer = $MarginContainer/VBoxContainer/BodyHBox/DetailPanel
@onready var detail_title: Label = $MarginContainer/VBoxContainer/BodyHBox/DetailPanel/VBox/DetailTitle
@onready var detail_sender: Label = $MarginContainer/VBoxContainer/BodyHBox/DetailPanel/VBox/MetaHBox/DetailSender
@onready var detail_date: Label = $MarginContainer/VBoxContainer/BodyHBox/DetailPanel/VBox/MetaHBox/DetailDate
@onready var detail_body: RichTextLabel = $MarginContainer/VBoxContainer/BodyHBox/DetailPanel/VBox/DetailBody
@onready var reward_container: HBoxContainer = $MarginContainer/VBoxContainer/BodyHBox/DetailPanel/VBox/RewardContainer
@onready var reward_desc: Label = $MarginContainer/VBoxContainer/BodyHBox/DetailPanel/VBox/RewardContainer/RewardDesc
@onready var claim_reward_btn: Button = $MarginContainer/VBoxContainer/BodyHBox/DetailPanel/VBox/RewardContainer/ClaimRewardBtn

var messages_data: Array[Dictionary] = [
	{
		"id": "welcome_gift",
		"title": "Welcome Gift to RACEZONE!",
		"sender": "Racezone HQ",
		"date": "Today",
		"body": "Welcome to RACEZONE! As a celebration of our 2D arcade launch, HQ is gifting you an exclusive starter kit containing [color=#FFB51B][b]1,000 Coins[/b][/color] and [color=#45D6FF][b]20 Diamonds[/b][/color].\n\nUse your coins in the Garage to unlock new racing machines or in the Shop to style your livery with custom paints, racing stripes, and sport wheels.\n\nSee you on the asphalt, racer!",
		"has_reward": true,
		"coins": 1000,
		"diamonds": 20,
		"is_read": false
	},
	{
		"id": "festival_event",
		"title": "Racing Festival is Now LIVE!",
		"sender": "Event Coordinator",
		"date": "Yesterday",
		"body": "The inaugural [b]Racing Festival[/b] has officially begun!\n\nTake to the Sunset Circuit, Harbor Run, and Neon Loop tracks to test your reflexes and clock your fastest lap times. Complete event challenges from the Home Event Card to advance your career and earn championship achievements.\n\nEvent duration: [color=#FFB51B]6 Days, 12 Hours remaining[/color]. Hit GO RACE on the home screen to jump straight into the action!",
		"has_reward": false,
		"is_read": false
	},
	{
		"id": "patch_notes_v10",
		"title": "Update 1.0 Release Patch Notes",
		"sender": "Lead Engineer",
		"date": "3 days ago",
		"body": "RACEZONE Version 1.0 is now live!\n\n[b]Key Features & Enhancements:[/b]\n• 100% offline responsive 2D arcade racing engine\n• Top-down racing physics with customizable steering sensitivity\n• Fully functional Garage with car purchase, stats, and selection\n• Full cosmetic customization: 6 body paints, 3 decals, 2 wheel styles\n• 7-day Daily Login rewards calendar\n• Free Coin & Diamond Centers for testing\n• High Contrast UI, Color Assist, and English / Indonesian localization.\n\nThank you for playing RACEZONE!",
		"has_reward": false,
		"is_read": false
	}
]

var selected_index: int = 0

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	mark_all_read_btn.pressed.connect(_on_mark_all_read)
	claim_reward_btn.pressed.connect(_on_claim_reward)

	_sync_read_and_claimed_state()
	_build_message_list()
	_select_message(0)

	if has_node("/root/Localization"):
		title_label.text = get_node("/root/Localization").get_string("INBOX")
		back_button.text = "← " + get_node("/root/Localization").get_string("BACK")

func _sync_read_and_claimed_state() -> void:
	if not has_node("/root/SaveManager"):
		return
	var sm = get_node("/root/SaveManager")
	var prog = sm.get_progress()
	var read_list = prog.get("read_inbox", [])
	var claimed_gift = prog.get("claimed_welcome_gift", false)

	for msg in messages_data:
		if msg.id in read_list:
			msg.is_read = true
		if msg.id == "welcome_gift" and claimed_gift:
			msg.is_claimed = true

func _build_message_list() -> void:
	for c in msg_list_container.get_children():
		c.queue_free()

	for i in range(messages_data.size()):
		var msg = messages_data[i]
		var btn = Button.new()
		btn.set_script(preload("res://scripts/ui/RaceButton.gd"))
		btn.custom_minimum_size = Vector2(0, 68)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var unread_indicator = "● " if not msg.is_read else "  "
		var reward_tag = " [🎁 GIFT]" if (msg.has_reward and not msg.get("is_claimed", false)) else ""
		btn.text = "%s%s%s\n  %s • %s" % [unread_indicator, msg.title, reward_tag, msg.sender, msg.date]
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT

		if not msg.is_read:
			btn.modulate = Color(1.0, 0.95, 0.7, 1.0)
		else:
			btn.modulate = Color(0.85, 0.85, 0.85, 1.0)

		var idx = i
		btn.pressed.connect(func(): _select_message(idx))
		msg_list_container.add_child(btn)

func _select_message(idx: int) -> void:
	if idx < 0 or idx >= messages_data.size():
		return
	selected_index = idx
	var msg = messages_data[idx]

	# Mark as read
	if not msg.is_read:
		msg.is_read = true
		_save_read_state()
		_build_message_list()

	detail_title.text = msg.title
	detail_sender.text = "From: " + msg.sender
	detail_date.text = "Date: " + msg.date
	detail_body.text = msg.body

	if msg.has_reward:
		reward_container.visible = true
		var claimed = msg.get("is_claimed", false)
		if claimed:
			claim_reward_btn.text = "CLAIMED ✓"
			claim_reward_btn.disabled = true
			claim_reward_btn.modulate = Color(0.5, 0.5, 0.5, 1.0)
			reward_desc.text = "Reward already claimed (+1,000 Coins, +20 Diamonds)"
		else:
			claim_reward_btn.text = "CLAIM REWARD"
			claim_reward_btn.disabled = false
			claim_reward_btn.modulate = Color(1.0, 1.0, 1.0, 1.0)
			reward_desc.text = "Bonus Attachment: 1,000 Coins + 20 Diamonds"
	else:
		reward_container.visible = false

func _on_claim_reward() -> void:
	var msg = messages_data[selected_index]
	if not msg.has_reward or msg.get("is_claimed", false):
		return

	msg.is_claimed = true
	if has_node("/root/SaveManager"):
		var sm = get_node("/root/SaveManager")
		sm.add_coins(msg.coins)
		sm.add_diamonds(msg.diamonds)
		sm.current_data.progress.claimed_welcome_gift = true
		sm.save_data()

		if has_node("/root/ToastManager"):
			get_node("/root/ToastManager").show_success("Claimed: +1,000 Coins & +20 Diamonds!")

	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_click_sfx()

	claim_reward_btn.text = "CLAIMED ✓"
	claim_reward_btn.disabled = true
	claim_reward_btn.modulate = Color(0.5, 0.5, 0.5, 1.0)
	reward_desc.text = "Reward claimed (+1,000 Coins, +20 Diamonds)"
	_build_message_list()
	emit_signal("inbox_updated")

func _on_mark_all_read() -> void:
	for msg in messages_data:
		msg.is_read = true
	_save_read_state()
	_build_message_list()
	if has_node("/root/ToastManager"):
		get_node("/root/ToastManager").show_toast("All messages marked as read.")
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_click_sfx()
	emit_signal("inbox_updated")

func _save_read_state() -> void:
	if not has_node("/root/SaveManager"):
		return
	var sm = get_node("/root/SaveManager")
	var read_list: Array = []
	for msg in messages_data:
		if msg.is_read:
			read_list.append(msg.id)
	sm.current_data.progress["read_inbox"] = read_list
	sm.save_data()
	emit_signal("inbox_updated")

func _on_back_pressed() -> void:
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_click_sfx()
	if has_node("/root/Navigation"):
		get_node("/root/Navigation").pop_scene()
	else:
		get_tree().change_scene_to_file("res://scenes/home/HomeScreen.tscn")
