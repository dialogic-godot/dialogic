tool
extends PanelContainer

var editor_reference
var editorPopup
var character_selected = ''

# This is the information of this event and it will get parsed and saved to the JSON file.
var event_data = {
	'action': 'leaveall',
	'character': '',
}

func _ready():
	$VBoxContainer/Header/VisibleToggle.disabled()
