tool
extends Control

var editor_reference
var editorPopup


# This is the information of this event and it will get parsed and saved to the JSON file.
var event_data = {
	'condition': '',
	'glossary': '',
	'value': ''
}

onready var nodes = {
	'glossary_picker': $PanelContainer/VBoxContainer/Header/GlossaryPicker,
}

func _ready():
	nodes['glossary_picker'].get_popup().connect("index_pressed", self, '_on_glossary_entry_selected')
	$PanelContainer/VBoxContainer/Header/CustomLineEdit.connect("text_changed", self, '_on_text_changed')


func _on_text_changed(new_text):
	event_data['value'] = new_text


func load_data(data):
	event_data = data
	$PanelContainer/VBoxContainer/Header/CustomLineEdit.text = event_data['value']
	if data['glossary'] != '':
		nodes['glossary_picker'].text = DialogicUtil.get_glossary_by_file(data['glossary'])['name']


func _on_glossary_entry_selected(index):
	var metadata = nodes['glossary_picker'].get_popup().get_item_metadata(index)
	event_data['glossary'] = metadata['file']
