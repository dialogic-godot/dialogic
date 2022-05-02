tool
extends HBoxContainer

export var text : String = ''
export var default : String = ''
export var settings_section : String = ''
export var settings_key : String = ''


func _ready():
	# This node needs a Settings Editor parent to get the current loaded settings
	$Label.text = DTS.translate(text)
	var settings = DialogicResources.get_settings_config()
	$LineEdit.text = settings.get_value(settings_section, settings_key, default)


func _on_LineEdit_text_changed(new_text: String) -> void:
	DialogicResources.set_settings_value(settings_section, settings_key, new_text)
