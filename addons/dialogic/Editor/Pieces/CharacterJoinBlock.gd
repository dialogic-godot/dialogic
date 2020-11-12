tool
extends Control

var editor_reference

var current_color = Color('#ffffff')
var default_icon_color = Color("#65989898")

# This is the information of this event and it will get parsed and saved to the JSON file.
var event_data = {
	'action': 'join',
	'character': '',
	'position': {"0":false,"1":false,"2":false,"3":false,"4":false}
}


func _ready():
	for p in $PanelContainer/VBoxContainer/Header/PositionsContainer.get_children():
		p.connect('pressed', self, "position_button_pressed", [p.name])
	$PanelContainer/VBoxContainer/Header/VisibleToggle.disabled()
	$PanelContainer/VBoxContainer/Header/CharacterDropdown.get_popup().connect("index_pressed", self, '_on_character_selected')


func _on_MenuCharacter_about_to_show():
	var Dropdown = $PanelContainer/VBoxContainer/Header/CharacterDropdown
	Dropdown.get_popup().clear()
	var index = 0
	for c in editor_reference.get_character_list():
		Dropdown.get_popup().add_item(c['name'])
		Dropdown.get_popup().set_item_metadata(index, {'file': c['file'], 'color': c['color']})
		index += 1


func _on_character_selected(index):
	var text = $PanelContainer/VBoxContainer/Header/CharacterDropdown.get_popup().get_item_text(index)
	var metadata = $PanelContainer/VBoxContainer/Header/CharacterDropdown.get_popup().get_item_metadata(index)
	
	# Updating icon Color
	current_color = Color(metadata['color'])
	var c_c_ind = 0
	for p in $PanelContainer/VBoxContainer/Header/PositionsContainer.get_children():
		if event_data['position'][str(c_c_ind)]:
			p.set('self_modulate', Color(metadata['color']))
		else:
			p.set('self_modulate', default_icon_color)
		c_c_ind += 1
		
	$PanelContainer/VBoxContainer/Header/CharacterDropdown.text = text
	event_data['character'] = metadata['file']


func position_button_pressed(name):
	clear_all_positions()
	var selected_index = name.split('-')[1]
	var button = $PanelContainer/VBoxContainer/Header/PositionsContainer.get_node('position-' + selected_index)
	button.set('self_modulate', Color("#ffffff"))
	button.set('self_modulate', current_color)
	button.pressed = true
	event_data['position'][selected_index] = true
	print('here', selected_index)


func clear_all_positions():
	for i in range(5):
		event_data['position'][str(i)] = false
	for p in $PanelContainer/VBoxContainer/Header/PositionsContainer.get_children():
		p.set('self_modulate', default_icon_color)
		p.pressed = false


func check_active_position(active_color = Color("#ffffff")):
	var index = 0
	for p in $PanelContainer/VBoxContainer/Header/PositionsContainer.get_children():
		if event_data['position'][str(index)]:
			p.pressed = true
			p.set('self_modulate', active_color)
		index += 1


func load_data(data):
	event_data = data
	if data['character'] != '':
		var character_data = editor_reference.get_character_data(data['character'])
		if character_data.has('name'):
			$PanelContainer/VBoxContainer/Header/CharacterDropdown.text = character_data['name']
		if character_data.has('color'):
			current_color = Color('#' + character_data['color'])
			check_active_position(current_color)
			return
	check_active_position()
