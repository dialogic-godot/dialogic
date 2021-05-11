tool
extends "res://addons/dialogic/Editor/Events/Parts/EventPart.gd"

# has an event_data variable that stores the current data!!!

## node references
onready var seconds_input = $HBox/SecondsBox

# used to connect the signals
func _ready():
	seconds_input.connect("value_changed", self, "_on_SecondsInput_value_changed")
	pass

# called by the event block
func load_data(data:Dictionary):
	# First set the event_data
	.load_data(data)
	
	# Now update the ui nodes to display the data. 
	seconds_input.value = event_data['wait_seconds']

# has to return the wanted preview, only useful for body parts
func get_preview():
	return ''

func _on_SecondsInput_value_changed(value):
	event_data['wait_seconds'] = value
	
	# informs the parent about the changes!
	data_changed()
