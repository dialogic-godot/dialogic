tool
extends Control

var editor_reference
var editorPopup


# This is the information of this event and it will get parsed and saved to the JSON file.
var event_data = {
	'close_dialog': '',
	'transition_duration': 1.0
}


func load_data(data):
	event_data = data
	if not event_data.has('transition_duration'):
		event_data['transition_duration'] = 1.0
	$PanelContainer/VBoxContainer/Header/SpinBox.value = event_data['transition_duration']

func _on_SpinBox_value_changed(value):
	event_data['transition_duration'] = value
