tool
extends Control

var editor_reference
var editorPopup


# This is the information of this event and it will get parsed and saved to the JSON file.
var event_data = {
	'close_dialog': ''
}


func _ready():
	pass

func load_data(data):
	event_data = data
