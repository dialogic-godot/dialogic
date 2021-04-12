tool
extends Control

var editor_reference
var character_selected = ''

# This is the information of this event and it will get parsed and saved to the JSON file.
var event_data = {
	'action': 'leaveall',
	'character': '[All]',
}


func _ready():
	$PanelContainer/VBoxContainer/Header/CharacterDropdown.get_popup().connect("index_pressed", self, '_on_character_selected')


func _on_CharacterDropdown_about_to_show():
	var Dropdown = $PanelContainer/VBoxContainer/Header/CharacterDropdown
	Dropdown.get_popup().clear()
	Dropdown.get_popup().add_item("[All]")
	var index = 1
	for c in DialogicUtil.get_sorted_character_list():
		Dropdown.get_popup().add_item(c['name'])
		Dropdown.get_popup().set_item_metadata(index, {'file': c['file'], 'color': c['color']})
		index += 1


func _on_character_selected(index):
	var text = $PanelContainer/VBoxContainer/Header/CharacterDropdown.get_popup().get_item_text(index)
	var metadata = $PanelContainer/VBoxContainer/Header/CharacterDropdown.get_popup().get_item_metadata(index)
	$PanelContainer/VBoxContainer/Header/CharacterDropdown.text = text
	event_data['character'] = metadata['file']


func load_data(data):
	event_data = data
	if data['character'] != '[All]':
		if data['character'] != '':
			var character_data = DialogicResources.get_character_json(data['character'])
			if character_data.has('name'):
				$PanelContainer/VBoxContainer/Header/CharacterDropdown.text = character_data['name']
