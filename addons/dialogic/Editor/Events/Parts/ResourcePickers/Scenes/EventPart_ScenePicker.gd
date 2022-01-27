tool
extends "res://addons/dialogic/Editor/Events/Parts/EventPart.gd"

# has an event_data variable that stores the current data!!!

## node references
onready var file_picker = $FilePicker

# used to connect the signals
func _ready():
	file_picker.connect("data_changed", self, "_on_ScenePicker_data_changed")

# called by the event block
func load_data(data:Dictionary):
	# First set the event_data
	.load_data(data)
	
	# Now update the ui nodes to display the data. 
	file_picker.load_data(data)

# has to return the wanted preview, only useful for body parts
func get_preview():
	return ''

func _on_ScenePicker_data_changed(data):
	event_data = data
	data_changed()

