tool
extends "res://addons/dialogic/Editor/Events/Parts/EventPart.gd"

## node references
onready var seconds_selector = $HBoxContainer/SecondsBox
onready var skippable_selector = $HBoxContainer/SkippableCheckbox
onready var hideBox_selector = $HBoxContainer/HideDialogBoxCheckbox

# used to connect the signals
func _ready():
	seconds_selector.connect("value_changed", self, "_on_SecondsSelector_value_changed")
	skippable_selector.connect("toggled", self, "_on_SkippableSelector_toggled")
	hideBox_selector.connect("toggled", self, "_on_HideDialogBox_toggled")

# called by the event block
func load_data(data:Dictionary):
	# First set the resource.properties
	.load_data(data)
	
	print('--: ', resource)
	
	# Now update the ui nodes to display the data. 
	seconds_selector.value = resource.properties['wait_seconds']
	skippable_selector.pressed = resource.properties.get('waiting_skippable', false)
	hideBox_selector.pressed = resource.properties.get('hide_dialogbox', true)
	if resource.properties['wait_seconds'] == 1:
		$HBoxContainer/Label2.text = "second"
	else:
		$HBoxContainer/Label2.text = "seconds"

func _on_SecondsSelector_value_changed(value):
	resource.properties['wait_seconds'] = value
	if value == 1:
		$HBoxContainer/Label2.text = "second"
	else:
		$HBoxContainer/Label2.text = "seconds"
	data_changed()

func _on_SkippableSelector_toggled(checkbox_value):
	resource.properties['waiting_skippable'] = checkbox_value
	data_changed()

func _on_HideDialogBox_toggled(checkbox_value):
	resource.properties['hide_dialogbox'] = checkbox_value
	data_changed()

# has to return the wanted preview, only useful for body parts
func get_preview():
	return ''
