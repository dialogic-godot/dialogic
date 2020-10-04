tool
extends PanelContainer

enum {ACTION_JOIN, ACTION_LEAVE, ACTION_LEAVE_ALL}
const ACTION_STRINGS = ['join', 'leave', 'leaveall']

var editor_reference
var editorPopup
var preview = ""
var available_positions = ['left', 'middle', 'right'] #TODO: I should use this or enum instead of hard coding the position options. 
var character_selected = ''

# This is the information of this event and it will get parsed and saved to the JSON file.
var event_data = {
	'action': '',
	'character': '',
	'position': ''
}

func _ready():
	var actionMenu = $VBoxContainer/Header/ActionSelector.get_popup()
	actionMenu.connect("id_pressed", self, "_on_option_selected")
	$VBoxContainer/HBoxContainer/JoinIn.visible = false
	$VBoxContainer/HBoxContainer/Leave.visible = false
	$VBoxContainer/HBoxContainer/LeaveAll.visible = false
	
	var positionMenu = $VBoxContainer/HBoxContainer/JoinIn/MenuPosition.get_popup()
	positionMenu.connect("id_pressed", self, "_on_position_selected")
	
	refresh()

func refresh():
	# Actions
	hide_panels()
	if event_data['action'] == 'join':
		$VBoxContainer/Header/ActionSelector.text = "[Join]"
		$VBoxContainer/HBoxContainer/JoinIn.visible = true
	if event_data['action'] == 'leave':
		$VBoxContainer/Header/ActionSelector.text = "[Leave]"
		$VBoxContainer/HBoxContainer/Leave.visible = true
	if event_data['action'] == 'leaveall':
		$VBoxContainer/Header/ActionSelector.text = "[Leave all]"
		$VBoxContainer/HBoxContainer/LeaveAll.visible = true
		preview = ''

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
			$VBoxContainer/HBoxContainer/JoinIn/MenuPosition.text = 'Left'
		1:
			event_data['position'] = 'middle'
			$VBoxContainer/HBoxContainer/JoinIn/MenuPosition.text = 'Middle'
		2:
			event_data['position'] = 'right'
			$VBoxContainer/HBoxContainer/JoinIn/MenuPosition.text = 'Right'
	preview = character_selected + ', ' + event_data['position']
	return event_data['position']

func _on_option_selected(option):
	event_data['action'] = ACTION_STRINGS[option]
	refresh()
	# TODO: check if the content is hidden and if this changes it should expand the module

func hide_panels():
	$VBoxContainer/HBoxContainer/JoinIn.visible = false
	$VBoxContainer/HBoxContainer/Leave.visible = false
	$VBoxContainer/HBoxContainer/LeaveAll.visible = false
