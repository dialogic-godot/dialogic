tool
extends "res://addons/dialogic/Editor/Events/Parts/EventPart.gd"

# has an event_data variable that stores the current data!!!

## node references
onready var noskip_selector = $HBoxContainer/NoSkipCheckbox
onready var autoadvance_time = $HBoxContainer2/AutoAdvanceTime

# used to connect the signals
func _ready():
	autoadvance_time.connect("value_changed", self, "_on_SecondsSelector_value_changed")
	noskip_selector.connect("toggled", self, "_on_HideDialogBox_toggled")

# called by the event block
func load_data(data:Dictionary):
	# First set the event_data
	.load_data(data)
	
	autoadvance_time.value = event_data['wait_time']
	noskip_selector.pressed = event_data.get('block_input', true)


func _on_SecondsSelector_value_changed(value):
	event_data['wait_time'] = value
	data_changed()


func _on_HideDialogBox_toggled(checkbox_value):
	event_data['block_input'] = checkbox_value
	data_changed()

# has to return the wanted preview, only useful for body parts
func get_preview():
	return ''
