tool
extends "res://addons/dialogic/Editor/Events/Parts/EventPart.gd"

# has an event_data variable that stores the current data!!!

## node references
onready var seconds_selector = $SecondsSelector
onready var skippable_selector = $Skippable

# used to connect the signals
func _ready():
	seconds_selector.connect("data_changed", self, "data_changed")
	skippable_selector.connect("data_changed", self, "data_changed")

# called by the event block
func load_data(data:Dictionary):
	# First set the event_data
	.load_data(data)
	
	seconds_selector.load_data(data)
	skippable_selector.load_data(data)
