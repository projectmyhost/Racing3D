extends Control

signal confirmed
signal cancelled

@onready var title_label: Label = %TitleLabel
@onready var message_label: Label = %MessageLabel
@onready var confirm_button: Button = %ConfirmButton
@onready var cancel_button: Button = %CancelButton
@onready var warning_label: Label = %WarningLabel

var is_dangerous: bool = false
var requires_double_confirm: bool = false
var _confirm_step: int = 0

func _ready() -> void:
	if has_node("/root/Navigation"):
		get_node("/root/Navigation").register_modal(self)

	cancel_button.pressed.connect(_on_cancel_pressed)
	confirm_button.pressed.connect(_on_confirm_pressed)
	
	# Default safe focus
	cancel_button.grab_focus()

func setup(title: String, message: String, confirm_text: String = "CONFIRM", cancel_text: String = "CANCEL", dangerous: bool = false, double_confirm: bool = false) -> void:
	title_label.text = title
	message_label.text = message
	confirm_button.text = confirm_text
	cancel_button.text = cancel_text
	is_dangerous = dangerous
	requires_double_confirm = double_confirm
	_confirm_step = 0
	warning_label.visible = false

	if is_dangerous:
		confirm_button.modulate = Color(0.9, 0.3, 0.3, 1.0)
	else:
		confirm_button.modulate = Color(1.0, 1.0, 1.0, 1.0)

	cancel_button.grab_focus()

func _on_confirm_pressed() -> void:
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_click_sfx()

	if requires_double_confirm and _confirm_step == 0:
		_confirm_step = 1
		warning_label.visible = true
		warning_label.text = "⚠️ WARNING: This cannot be undone! Click again to confirm."
		confirm_button.text = "YES, CONFIRM"
		confirm_button.modulate = Color(1.0, 0.2, 0.2, 1.0)
		cancel_button.grab_focus()
		return

	emit_signal("confirmed")
	close()

func _on_cancel_pressed() -> void:
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_click_sfx()
	emit_signal("cancelled")
	close()

func on_cancel_pressed() -> void:
	_on_cancel_pressed()

func close() -> void:
	if has_node("/root/Navigation"):
		get_node("/root/Navigation").unregister_modal(self)
	queue_free()
