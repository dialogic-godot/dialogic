tool
extends Control

var editor_reference
onready var portrait_picker = $PanelContainer/VBoxContainer/Header/PortraitPicker

var current_color = Color('#ffffff')
var default_icon_color = Color("#65989898")

# This is the information of this event and it will get parsed and saved to the JSON file.
var event_data = {
	'action': 'join',
	'character': '',
	'portrait': '',
	'position': {"0":false,"1":false,"2":false,"3":false,"4":false}
}


func _ready():
	for p in $PanelContainer/VBoxContainer/Header/PositionsContainer.get_children():
		p.connect('pressed', self, "position_button_pressed", [p.name])
	$PanelContainer/VBoxContainer/Header/CharacterPicker.connect('character_selected', self , '_on_character_selected')
	portrait_picker.get_popup().connect("index_pressed", self, '_on_portrait_selected')
	portrait_picker.allow_dont_change = false


func _on_character_selected(data):
	# Updating icon Color
	current_color = Color(data['color'])
	var c_c_ind = 0
	for p in $PanelContainer/VBoxContainer/Header/PositionsContainer.get_children():
		if event_data['position'][str(c_c_ind)]:
			p.set('self_modulate', Color(data['color']))
		else:
			p.set('self_modulate', default_icon_color)
		c_c_ind += 1
	event_data['character'] = data['file']
	portrait_picker.set_character(event_data['character'], event_data['portrait'])
	portrait_picker.text = 'Default'


func _on_portrait_selected(index):
	var text = portrait_picker.get_popup().get_item_text(index)
	if portrait_picker.allow_dont_change:
		if text == "[Don't change]":
			text = ''
	event_data['portrait'] = text
	portrait_picker.set_character(event_data['character'], event_data['portrait'])


func position_button_pressed(name):
	clear_all_positions()
	var selected_index = name.split('-')[1]
	var button = $PanelContainer/VBoxContainer/Header/PositionsContainer.get_node('position-' + selected_index)
	button.set('self_modulate', Color("#ffffff"))
	button.set('self_modulate', current_color)
	button.pressed = true
	event_data['position'][selected_index] = true


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
		var character_data = DialogicResources.get_character_json(data['character'])
		$PanelContainer/VBoxContainer/Header/CharacterPicker.set_data(character_data['name'], Color(character_data['color']))
		portrait_picker.set_character(data['character'], data['portrait'])
		current_color = Color(character_data['color'])
		check_active_position(current_color)
		return
	check_active_position()
