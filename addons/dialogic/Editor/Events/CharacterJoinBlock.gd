tool
extends Control

var editor_reference
onready var character_picker = $PanelContainer/VBoxContainer/Header/CharacterAndPortraitPicker
onready var mirror_toggle = $PanelContainer/VBoxContainer/Header/MirrorButton
var current_color = Color('#ffffff')
var default_icon_color = Color("#65989898")

# This is the information of this event and it will get parsed and saved to the JSON file.
var event_data = {
	'action': 'join',
	'character': '',
	'portrait': '',
	'position': {"0":false,"1":false,"2":false,"3":false,"4":false},
	'mirror':false
}


func _ready():
	for p in $PanelContainer/VBoxContainer/Header/PositionsContainer.get_children():
		p.connect('pressed', self, "position_button_pressed", [p.name])
	character_picker.connect("character_changed", self, '_on_character_change')
	character_picker.set_allow_portrait_dont_change(false)
	mirror_toggle.icon = get_icon("MirrorX", "EditorIcons")


func _on_character_change(character: Dictionary, portrait: String):
	# Updating icon Color
	if character.keys().size() > 0:
		current_color = Color(character['color'])
		var c_c_ind = 0
		for p in $PanelContainer/VBoxContainer/Header/PositionsContainer.get_children():
			if event_data['position'][str(c_c_ind)]:
				p.set('self_modulate', Color(character['color']))
			else:
				p.set('self_modulate', default_icon_color)
			c_c_ind += 1
		event_data['character'] = character['file']
		event_data['portrait'] = portrait
	else:
		event_data['character'] = ''
		event_data['portrait'] = ''
		clear_all_positions()


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
		character_picker.set_data(data['character'], data['portrait'])
		current_color = character_picker.get_selected_character()['color']
		check_active_position(current_color)
	else:
		check_active_position()
	
	if data.has('mirror'):
		mirror_toggle.pressed = data['mirror']
	else:
		mirror_toggle.pressed = false

func _on_MirrorButton_toggled(button_pressed):
	event_data['mirror'] = button_pressed
