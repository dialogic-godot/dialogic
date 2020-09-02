tool
extends PanelContainer

var editor_reference
var editorPopup
var available_positions = ['left', 'middle', 'right'] #TODO: I should use this or enum instead of hard coding the position options. 
var character_selected = ''

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
	
func _on_position_selected(option):
  set_character_position(option)

func load_character_position(name):
	print('Loading character joining in: ', name)
	var index_position = 0
	match name:
		'left':
			index_position = 0
		'middle':
			index_position = 1
		'right':
			index_position = 2
	set_character_position(index_position)

func set_character_position(index):
	match index:
		0:
			event_data['position'] = 'left'
			position_selector.text = 'Left'
		1:
			event_data['position'] = 'middle'
			position_selector.text = 'Middle'
		2:
			event_data['position'] = 'right'
			position_selector.text = 'Right'
	return event_data['position']
