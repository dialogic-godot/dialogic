tool
extends "res://addons/dialogic/Editor/Events/Parts/EventPart.gd"

# has an resource.properties variable that stores the current data!!!

## node references
onready var number_box = $HBox/NumberBox

# used to connect the signals
func _ready():
	number_box.connect("value_changed", self, "_on_NumberBox_value_changed")

# called by the event block
func load_data(data:Dictionary):
	# First set the resource.properties
	.load_data(data)
	
	# Now update the ui nodes to display the data. 
	number_box.value = resource.properties['transition_duration']

# has to return the wanted preview, only useful for body parts
func get_preview():
	return ''

func _on_NumberBox_value_changed(value):
	resource.properties['transition_duration'] = value
	
	# informs the parent about the changes!
	data_changed()
