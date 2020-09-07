tool
extends PanelContainer

var editor_reference
var available_positions = ['left', 'middle', 'right']

onready var position_selector = $VBoxContainer/Header/MenuPosition

# This is the information of this event and it will get parsed and saved to the JSON file.
var event_data = {
	'action': 'join',
	'character': '',
	'position': ''
}

func _ready():
	var positionMenu = position_selector.get_popup()
	positionMenu.connect("id_pressed", self, "_on_position_selected")
	$VBoxContainer/Header/VisibleToggle.disabled()
	$VBoxContainer/Header/CharacterDropdown.get_popup().connect("index_pressed", self, '_on_character_selected')


func _on_MenuCharacter_about_to_show():
	var Dropdown = $VBoxContainer/Header/CharacterDropdown
	Dropdown.get_popup().clear()
	var index = 0
	for c in editor_reference.get_character_list():
		Dropdown.get_popup().add_item(c['name'])
		Dropdown.get_popup().set_item_metadata(index, {'file': c['file'], 'color': Color('#ffffff')})
		index += 1

func _on_character_selected(index):
	var text = $VBoxContainer/Header/CharacterDropdown.get_popup().get_item_text(index)
	var metadata = $VBoxContainer/Header/CharacterDropdown.get_popup().get_item_metadata(index)
	$VBoxContainer/Header/CharacterDropdown.text = text
	event_data['character'] = metadata['file']

func _on_position_selected(index):
	var selected = position_selector.get_popup().get_item_text(index)
	$VBoxContainer/Header/MenuPosition.text = selected
	event_data['position'] = selected.to_lower()

func load_data(data):
	if data['position'] != '':
		$VBoxContainer/Header/MenuPosition.text = data['position'].capitalize()
	if data['character'] != '':
		$VBoxContainer/Header/CharacterDropdown.text = editor_reference.get_character_name(data['character'])
	event_data = data
