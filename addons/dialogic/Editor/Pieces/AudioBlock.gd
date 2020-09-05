tool
extends PanelContainer

var editor_reference
var editorPopup

# This is the information of this event and it will get parsed and saved to the JSON file.
var event_data = {
	'audio': 'play',
	'file': ''
}

func _ready():
	$VBoxContainer/Header/VisibleToggle.disabled()
