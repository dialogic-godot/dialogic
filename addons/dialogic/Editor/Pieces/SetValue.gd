tool
extends Control

var editor_reference
var editorPopup


# This is the information of this event and it will get parsed and saved to the JSON file.
var event_data = {
	'set_value': '',
	'glossary': ''
}

onready var nodes = {
	'glossary_picker': $PanelContainer/VBoxContainer/Header/GlossaryPicker,
}

func _ready():
	nodes['glossary_picker'].get_popup().connect("index_pressed", self, '_on_glossary_entry_selected')


func _on_glossary_entry_selected(index):
	var metadata = nodes['glossary_picker'].get_popup().get_item_metadata(index)
	event_data['glossary'] = metadata['file']


func load_data(data):
	event_data = data
	$PanelContainer/VBoxContainer/Header/LineEdit.text = event_data['set_value']
	if data['glossary'] != '':
		nodes['glossary_picker'].text = DialogicUtil.get_glossary_by_file(data['glossary'])['name']


func _on_LineEdit_text_changed(new_text):
	event_data['set_value'] = new_text
