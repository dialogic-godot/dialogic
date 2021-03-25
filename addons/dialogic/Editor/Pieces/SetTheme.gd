tool
extends Control

var editor_reference
var editorPopup


# This is the information of this event and it will get parsed and saved to the JSON file.
var event_data = {
	'set_theme': ''
}


func _ready():
	$PanelContainer/VBoxContainer/Header/MenuButton.get_popup().connect(
		"index_pressed", self, '_on_theme_selected')


func load_data(data):
	event_data = data
	if event_data['set_theme'] != '':
		for theme in DialogicUtil.get_theme_list():
			if theme['file'] == event_data['set_theme']:
				$PanelContainer/VBoxContainer/Header/MenuButton.text = theme['name']


func _on_MenuButton_about_to_show():
	var Dropdown = $PanelContainer/VBoxContainer/Header/MenuButton
	var theme_list = DialogicUtil.get_sorted_theme_list()
	var index = 0

	Dropdown.get_popup().clear()
	for theme in theme_list:
		Dropdown.get_popup().add_item(theme['name'])
		Dropdown.get_popup().set_item_metadata(index, {'file': theme['file']})
		index += 1


func _on_theme_selected(index):
	var text = $PanelContainer/VBoxContainer/Header/MenuButton.get_popup().get_item_text(index)
	var metadata = $PanelContainer/VBoxContainer/Header/MenuButton.get_popup().get_item_metadata(index)
	$PanelContainer/VBoxContainer/Header/MenuButton.text = text
	event_data['set_theme'] = metadata['file']
