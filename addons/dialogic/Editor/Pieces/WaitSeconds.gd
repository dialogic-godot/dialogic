tool
extends Control

var editor_reference

# This is the information of this event and it will get parsed and saved to the JSON file.
var event_data = {
	'wait_seconds': 0
}


func load_data(data):
	event_data = data
	$PanelContainer/VBoxContainer/Header/SpinBox.value = event_data['wait_seconds']


func _on_SpinBox_value_changed(value):
	event_data['wait_seconds'] = value
