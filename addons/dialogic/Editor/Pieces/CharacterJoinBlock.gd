tool
extends PanelContainer

var editor_reference
var available_positions = ['left', 'middle', 'right']

# This is the information of this event and it will get parsed and saved to the JSON file.
var event_data = {
	'action': 'join',
	'character': '',
	'position': {"0":false,"1":false,"2":false,"3":false,"4":false}
}

func _ready():
	for p in $VBoxContainer/Header/PositionsContainer.get_children():
		p.connect('pressed', self, "position_button_pressed", [p.name])
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

func position_button_pressed(name):
	clear_all_positions()
	var selected_index = name.split('-')[1]
	var button = $VBoxContainer/Header/PositionsContainer.get_node('position-' + selected_index)
	button.set('self_modulate', Color("#ffffff"))
	button.pressed = true
	event_data['position'][selected_index] = true
	print('here', selected_index)

func clear_all_positions():
	for i in range(5):
		event_data['position'][str(i)] = false
	for p in $VBoxContainer/Header/PositionsContainer.get_children():
		p.set('self_modulate', Color("#65989898"))
		p.pressed = false

func check_active_position():
	var index = 0
	for p in $VBoxContainer/Header/PositionsContainer.get_children():
		if event_data['position'][str(index)]:
			p.set('self_modulate', Color("#ffffff"))
			p.pressed = true
		index += 1

func load_data(data):
	if data['character'] != '':
		$VBoxContainer/Header/CharacterDropdown.text = editor_reference.get_character_name(data['character'])
	event_data = data
	check_active_position()
