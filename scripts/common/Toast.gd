extends PanelContainer

@onready var message_label: Label = $MarginContainer/HBoxContainer/MessageLabel
@onready var icon_label: Label = $MarginContainer/HBoxContainer/IconLabel

var display_duration: float = 2.5

func _ready() -> void:
	modulate.a = 0.0
	position.y += 20.0
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "modulate:a", 1.0, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position:y", position.y - 20.0, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	await get_tree().create_timer(display_duration).timeout
	
	var fade_tween = create_tween().set_parallel(true)
	fade_tween.tween_property(self, "modulate:a", 0.0, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	fade_tween.tween_property(self, "position:y", position.y + 10.0, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	fade_tween.finished.connect(queue_free)

func setup(text: String, duration: float = 2.5, icon: String = "⚡") -> void:
	display_duration = duration
	if has_node("MarginContainer/HBoxContainer/MessageLabel"):
		$MarginContainer/HBoxContainer/MessageLabel.text = text
	if has_node("MarginContainer/HBoxContainer/IconLabel"):
		$MarginContainer/HBoxContainer/IconLabel.text = icon
