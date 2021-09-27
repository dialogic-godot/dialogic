tool
extends "res://addons/dialogic/Editor/Events/Parts/EventPart.gd"
 # has an event_data variable that stores the current data!!!

 ## node references
 # e.g. 
onready var input_field = $InputField

 # used to connect the signals
func _ready():
	# e.g. 
	input_field.connect("text_changed", self, "_on_InputField_text_changed")
	pass

 # called by the event block
func load_data(data:Dictionary):
	# First set the event_data
	.load_data(data)
	
	# Now update the ui nodes to display the data. 
	# e.g. 
	input_field.text = event_data['my_text_key']

 # has to return the wanted preview, only useful for body parts
func get_preview():
	return ''

 ## EXAMPLE CHANGE IN ONE OF THE NODES
func _on_InputField_text_changed(text):
	event_data['my_text_key'] = text
	
	# informs the parent about the changes!
	data_changed()
