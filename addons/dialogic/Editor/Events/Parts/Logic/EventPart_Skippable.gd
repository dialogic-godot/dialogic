tool
extends "res://addons/dialogic/Editor/Events/Parts/EventPart.gd"

# has an event_data variable that stores the current data!!!

## node references
onready var skippable_checkbox = $HBoxContainer/SkippableCheckbox


# used to connect the signals
func _ready():
	skippable_checkbox.connect("toggled", self, "_on_SkippableCheckbox_toggled")


# called by the event block
func load_data(data:Dictionary):
	# First set the event_data
	.load_data(data)
	
	skippable_checkbox.pressed = event_data.get('waiting_skippable', false)

func _on_SkippableCheckbox_toggled(checkbox_value):
	event_data['waiting_skippable'] = checkbox_value
	data_changed()
