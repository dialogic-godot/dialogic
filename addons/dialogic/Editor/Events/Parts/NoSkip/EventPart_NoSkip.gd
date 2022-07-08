tool
extends "res://addons/dialogic/Editor/Events/Parts/EventPart.gd"

# has an event_data variable that stores the current data!!!

## node references
onready var noskip_selector = $HBoxContainer/NoSkipCheckbox

# used to connect the signals
func _ready():
	noskip_selector.connect("toggled", self, "_on_HideDialogBox_toggled")

# called by the event block
func load_data(data:Dictionary):
	# First set the event_data
	.load_data(data)
	
	# Now update the ui nodes to display the data. 
	noskip_selector.pressed = event_data.get('block_input', true)


func _on_HideDialogBox_toggled(checkbox_value):
	event_data['block_input'] = checkbox_value
	data_changed()

# has to return the wanted preview, only useful for body parts
func get_preview():
	return ''
