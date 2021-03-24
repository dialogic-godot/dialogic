tool
extends Control

var editor_reference
var editorPopup


# This is the information of this event and it will get parsed and saved to the JSON file.
var event_data = {
	'set_value': '',
	'definition': ''
}

onready var nodes = {
	'definition_picker': $PanelContainer/VBoxContainer/Header/DefinitionPicker,
}

func _ready():
	nodes['definition_picker'].get_popup().connect("index_pressed", self, '_on_definition_entry_selected')


func _on_definition_entry_selected(index):
	var metadata = nodes['definition_picker'].get_popup().get_item_metadata(index)
	event_data['definition'] = metadata['id']


func load_data(data):
	event_data = data
	$PanelContainer/VBoxContainer/Header/LineEdit.text = event_data['set_value']
	nodes['definition_picker'].load_definition(data['definition'])


func _on_LineEdit_text_changed(new_text):
	event_data['set_value'] = new_text
