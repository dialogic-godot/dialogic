tool
extends HBoxContainer

onready var visible_toggle = $VisibleToggle
onready var preview = $MarginContainer/Preview

var enabled : bool
var expanded: bool

var max_preview_characters = 50

signal state_changed(expanded)

func _ready():
	$MarginContainer/Preview.set("custom_colors/font_color", get_color("disabled_font_color", "Editor"))
	set_enabled(false)
	visible_toggle.connect("toggled", self, "_on_VisibleToggle_toggled")


func set_preview(text: String):
	if len(text) > 50:
		text = text.substr(0, 50)
		text += "..."
	preview.text = text


func set_enabled(enabled: bool):
	self.enabled = enabled
	set_expanded(enabled)
	if enabled:
		show()
	else:
		hide()


func set_expanded(expanded: bool):
	if not enabled:
		return 
	self.expanded = expanded
	visible_toggle.pressed = expanded
	if expanded:
		preview.hide()
	else:
		preview.show()
	visible_toggle.release_focus()
	emit_signal("state_changed", expanded)


func _on_VisibleToggle_toggled(button_pressed: bool):
	if enabled:
		set_expanded(button_pressed)
