tool
extends "res://addons/dialogic/Editor/Events/Parts/EventPart.gd"

## has an event_data variable that stores the current data!!!

var join_icon = load("res://addons/dialogic/Images/Event Icons/character-join.svg")
var leave_icon = load("res://addons/dialogic/Images/Event Icons/character-leave.svg")
var update_icon = load("res://addons/dialogic/Images/Event Icons/character.svg")

## node references
onready var action_picker = $ActionTypePicker
onready var character_portrait_picker = $CharacterAndPortraitPicker
onready var position_picker = $PositionPicker

# used to connect the signals
func _ready():
	action_picker.connect("about_to_show", self, "_on_ActionTypePicker_about_to_show")
	action_picker.get_popup().connect('index_pressed', self, "_on_ActionTypePicker_index_pressed")
	character_portrait_picker.connect('data_changed', self, "_on_CharacterAndPortraitPicker_data_changed")
	position_picker.connect('data_changed', self, "_on_PositionPicker_data_changed")
	
	

# called by the event block
func load_data(data:Dictionary):
	# First set the event_data
	.load_data(data)
	
	# Now update the ui nodes to display the data. 
	match int(data.get('type', 0)):
		0:
			action_picker.text = 'Join'
			action_picker.custom_icon = join_icon
		1:
			action_picker.text = 'Leave'
			action_picker.custom_icon = leave_icon
		2:
			action_picker.text = 'Update'
			action_picker.custom_icon = update_icon
	
	position_picker.visible = data.get('type',0) != 1 and data.get('character', '') != ''
	position_picker.load_data(data)
	character_portrait_picker.load_data(data)

# has to return the wanted preview, only useful for body parts
func get_preview():
	return ''

func _on_ActionTypePicker_about_to_show():
	action_picker.get_popup().clear()
	
	action_picker.get_popup().add_icon_item(join_icon, "Join")
	action_picker.get_popup().add_icon_item(leave_icon, "Leave")
	action_picker.get_popup().add_icon_item(update_icon, "Update")


func _on_ActionTypePicker_index_pressed(index):
	if index != event_data['type']:
		if index == 0:
			event_data['portrait'] = 'Default'
			event_data['animation'] = '[Default]'
		elif index == 1:
			event_data['animation'] = '[Default]'
		elif index == 2:
			event_data['portrait'] = "(Don't change)"
	event_data['type'] = index
	
	load_data(event_data)

	# informs the parent about the changes!
	data_changed()

func _on_CharacterAndPortraitPicker_data_changed(data):
	event_data = data
	
	load_data(event_data)
	
	data_changed()
	
func _on_PositionPicker_data_changed(data):
	event_data = data
	
	data_changed()
	
