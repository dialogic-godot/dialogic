extends ConfirmationDialog

onready var text_node:LineEdit = $MarginContainer/LineEdit
onready var _ok_button:Button = get_ok()

func _ready() -> void:
	_ok_button.disabled = true
	text_node.grab_focus()
	text_node.grab_click_focus()


func _process(_delta: float) -> void:
	if not text_node.text:
		_ok_button.disabled = true
	else:
		_ok_button.disabled = false


func _on_LineEdit_text_entered(_new_text: String) -> void:
	if text_node.text:
		hide()
		emit_signal("confirmed")


func _on_visibility_changed() -> void:
	set_process(visible)
	if visible:
		text_node.text = ""
