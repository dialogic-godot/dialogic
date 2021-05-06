tool
extends "res://addons/dialogic/Editor/Events/Templates/EventTemplate.gd"

## This script is a template to be slightly changed for what you need 
## BEFORE EDITING THIS, MAKE SURE TO MAKE THE SCRIPT UNIQE!


# when the event is created, set the default data
func _init():
	# this is the default data of the event
	event_data = {
		'event_id':'dialogic_something'
	}

# called by the timeline before adding it to the tree
func load_data(data):
	# this sets the event_data
	.load_data(data)

# when it enters the tree, load the data.
# If there is any external data, it will be set already BEFORE the event is added to tree
func _ready():
	# if you have a header
	get_header().load_data(event_data)
	get_header().connect("data_changed", self, "_on_Header_data_changed")
	# if you have a body
	get_body().load_data(event_data)
	get_body().connect("data_changed", self, "_Body_data_changed")

# called when the data of the header is changed
func _on_Header_data_changed(new_event_data):
	event_data = new_event_data
	
	# update the body in case it has to
	if get_body():
		get_body().load_data(event_data)

# called when the data of the body is changed
func _on_Body_data_changed(new_event_data):
	event_data = new_event_data
	
	# update the header in case it has to
	if get_header():
		get_header().load_data(event_data)
