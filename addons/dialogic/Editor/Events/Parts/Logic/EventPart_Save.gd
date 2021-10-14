tool
extends "res://addons/dialogic/Editor/Events/Parts/EventPart.gd"

# has an event_data variable that stores the current data!!!

## node references
onready var default_slot = $DefaultSlot
onready var custom_slot = $CustomSlot

# used to connect the signals
func _ready():
	default_slot.connect("toggled", self, "_on_DefaultSlot_toggled")
	custom_slot.connect("text_changed", self, '_on_CustomSlot_text_changed')


# called by the event block
func load_data(data:Dictionary):
	# First set the event_data
	.load_data(data)
	
	# Now update the ui nodes to display the data. 
	default_slot.pressed = event_data.get('use_default_slot', true)
	custom_slot.text = event_data.get('custom_slot', '')
	
	custom_slot.visible = not default_slot.pressed
	$Label.visible = not default_slot.pressed


func _on_DefaultSlot_toggled(pressed):
	event_data['use_default_slot'] = pressed
	
	custom_slot.visible = not pressed
	$Label.visible = not pressed
	
	# informs the parent about the changes!
	data_changed()

func _on_CustomSlot_text_changed(text):
	event_data['custom_slot'] = text
	
	# informs the parent about the changes!
	data_changed()
