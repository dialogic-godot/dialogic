tool
extends "res://addons/dialogic/Editor/Events/Parts/EventPart.gd"

# has an event_data variable that stores the current data!!!

## node references
onready var text_field = $EventId

# used to connect the signals
func _ready():
	pass

# called by the event block
func load_data(data:Dictionary):
	# First set the event_data
	.load_data(data)
	
	# Now update the ui nodes to display the data. 
	text_field.text = event_data['event_id']

# has to return the wanted preview, only useful for body parts
func get_preview():
	return ''
