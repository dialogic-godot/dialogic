tool
extends Control

var editor_reference
var editorPopup


# This is the information of this event and it will get parsed and saved to the JSON file.
var event_data = {
	'definition': '',
	'operation': '=',
	'set_value': '',
}

onready var nodes = {
	'definition_picker': $PanelContainer/VBoxContainer/Header/DefinitionPicker,
	'operation_picker': $PanelContainer/VBoxContainer/Header/OperationPicker,
}

func _ready():
	nodes['definition_picker'].get_popup().connect("index_pressed", self, '_on_definition_entry_selected')
	nodes['operation_picker'].get_popup().connect("index_pressed", self, '_on_operation_entry_selected')


func _on_definition_entry_selected(index):
	var metadata = nodes['definition_picker'].get_popup().get_item_metadata(index)
	event_data['definition'] = metadata['id']

func _on_operation_entry_selected(index):
	var metadata = nodes['operation_picker'].get_popup().get_item_metadata(index)
	event_data['operation'] = metadata['operation']


func load_data(data):
	event_data = data
	$PanelContainer/VBoxContainer/Header/LineEdit.text = event_data['set_value']
	nodes['definition_picker'].load_definition(data['definition'])
	var operation = ''
	if 'operation' in data:
		operation = data['operation']
	nodes['operation_picker'].load_condition(operation)


func _on_LineEdit_text_changed(new_text):
	event_data['set_value'] = new_text
