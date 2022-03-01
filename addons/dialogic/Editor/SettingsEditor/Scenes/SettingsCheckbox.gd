tool
extends HBoxContainer

export var text : String = ''
export var default : bool = false
export var settings_section : String = ''
export var settings_key : String = ''

func _ready():
	# This node needs a Settings Editor parent to get the current loaded settings
	$CheckBox.text = DTS.translate(text)
	var settings = DialogicResources.get_settings_config()
	$CheckBox.pressed = settings.get_value(settings_section, settings_key, default)
	$CheckBox.connect("toggled", self, "_on_toggled")

func _on_toggled(button_pressed):
	DialogicResources.set_settings_value(settings_section, settings_key, button_pressed)
