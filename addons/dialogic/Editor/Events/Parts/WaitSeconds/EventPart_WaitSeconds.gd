tool
extends "res://addons/dialogic/Editor/Events/Parts/EventPart.gd"

# has an event_data variable that stores the current data!!!

## node references
onready var seconds_selector = $HBoxContainer/SecondsBox
onready var skippable_selector = $HBoxContainer/SkippableCheckbox

# used to connect the signals
func _ready():
	seconds_selector.connect("value_changed", self, "_on_SecondsSelector_value_changed")
	skippable_selector.connect("toggled", self, "_on_SkippableSelector_toggled")

# called by the event block
func load_data(data:Dictionary):
	# First set the event_data
	.load_data(data)
	
	# Now update the ui nodes to display the data. 
	seconds_selector.value = event_data['wait_seconds']
	skippable_selector.pressed = event_data.get('waiting_skippable', false)

func _on_SecondsSelector_value_changed(value):
	event_data['wait_seconds'] = value
	data_changed()

func _on_SkippableSelector_toggled(checkbox_value):
	event_data['waiting_skippable'] = checkbox_value
	data_changed()

# has to return the wanted preview, only useful for body parts
func get_preview():
	return ''
