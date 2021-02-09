tool
extends Control

var editor_reference
var editorPopup


# This is the information of this event and it will get parsed and saved to the JSON file.
var event_data = {
	'condition': '',
	'glossary': ''
}

onready var nodes = {
	'dropdown': $PanelContainer/VBoxContainer/Header/MenuButton,
}

func _ready():
	nodes['dropdown'].get_popup().connect("index_pressed", self, '_on_glossary_entry_selected')


func load_data(data):
	event_data = data
	if data['glossary'] != '':
		nodes['dropdown'].text = DialogicUtil.get_glossary_by_file(data['glossary'])['name']


func _on_glossary_entry_selected(index):
	var text = nodes['dropdown'].get_popup().get_item_text(index)
	var metadata = nodes['dropdown'].get_popup().get_item_metadata(index)

	nodes['dropdown'].text = text
	
	event_data['glossary'] = metadata['file']
	#update_preview()


func _on_MenuButton_about_to_show():
	var glossary = DialogicUtil.load_glossary()
	nodes['dropdown'].get_popup().clear()
	
	var index = 0
	for c in glossary:
		if glossary[c]['type'] > 1:
			nodes['dropdown'].get_popup().add_item(glossary[c]['name'] + ' (' + glossary_type_to_human(glossary[c]['type']) + ')')
			nodes['dropdown'].get_popup().set_item_metadata(index, {
				'file': glossary[c]['file'],
				'type': glossary[c]['type']
			})
			index += 1


static func glossary_type_to_human(value: int) -> String:
	var types = {
		0: 'None',
		1: 'Extra Information',
		2: 'Number',
		3: 'Text'
	}
	return types[value]
