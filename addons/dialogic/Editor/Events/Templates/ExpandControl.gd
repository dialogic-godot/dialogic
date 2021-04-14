tool
extends HBoxContainer

onready var visible_toggle = $VisibleToggle
onready var preview = $MarginContainer/Preview

var enabled : bool

signal state_changed(expanded)

func _ready():
	set_enabled(false)
	visible_toggle.connect("toggled", self, "_on_VisibleToggle_toggled")


func set_enabled(enabled: bool):
	self.enabled = enabled
	if enabled:
		show()
	else:
		hide()


func set_expanded(expanded: bool):
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
