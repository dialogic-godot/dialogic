tool
extends Control

var editor_reference
var editorPopup


# This is the information of this event and it will get parsed and saved to the JSON file.
var event_data = {
	'change_timeline': ''
}


func _ready():
	$PanelContainer/VBoxContainer/Header/MenuButton.get_popup().connect("index_pressed", self, '_on_timeline_selected')


func load_data(data):
	event_data = data
	if event_data['change_timeline'] != '':
		for c in DialogicUtil.get_timeline_list():
			if c['file'] == event_data['change_timeline']:
				$PanelContainer/VBoxContainer/Header/MenuButton.text = c['name']


func _on_MenuButton_about_to_show():
	var Dropdown = $PanelContainer/VBoxContainer/Header/MenuButton
	Dropdown.get_popup().clear()
	var index = 0
	for c in DialogicUtil.get_timeline_list():
		if c['file'].replace('.json', '') == DialogicUtil.get_filename_from_path(editor_reference.working_dialog_file):
			Dropdown.get_popup().add_item('(Current) ' + c['name'])
		else:
			Dropdown.get_popup().add_item(c['name'])
		Dropdown.get_popup().set_item_metadata(index, {'file': c['file'], 'color': c['color']})
		index += 1


func _on_timeline_selected(index):
	var text = $PanelContainer/VBoxContainer/Header/MenuButton.get_popup().get_item_text(index)
	var metadata = $PanelContainer/VBoxContainer/Header/MenuButton.get_popup().get_item_metadata(index)
	$PanelContainer/VBoxContainer/Header/MenuButton.text = text
	event_data['change_timeline'] = metadata['file']
