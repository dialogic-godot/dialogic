tool
extends HBoxContainer

export var text : String = ''
export var default : bool = false
export var settings_section : String = ''
export var settings_key : String = ''
var editor_reference

func _ready():
	editor_reference = find_parent('EditorView')
	# This node needs a Settings Editor parent to get the current loaded settings
	$CheckBox.text = editor_reference.dialogicTranslator.translate(text)
	var settings = DialogicResources.get_settings_config()
	$CheckBox.pressed = settings.get_value(settings_section, settings_key, default)
	$CheckBox.connect("toggled", self, "_on_toggled")

func _on_toggled(button_pressed):
	DialogicResources.set_settings_value(settings_section, settings_key, button_pressed)
