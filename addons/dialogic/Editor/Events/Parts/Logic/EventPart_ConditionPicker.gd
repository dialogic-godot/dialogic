tool
extends "res://addons/dialogic/Editor/Events/Parts/EventPart.gd"

# has an event_data variable that stores the current data!!!

export (bool) var allow_disable_condition := false

## node references
onready var definition_picker = $HBox/DefinitionPicker
onready var condition_type_picker = $HBox/ConditionTypePicker
onready var use_condition_button = $HBox/UseConditionButton
onready var input_field = $HBox/LineEdit


# used to connect the signals
func _ready():
	definition_picker.connect("data_changed", self, "_on_DefinitionPicker_data_changed")
	condition_type_picker.connect("data_changed", self, "_on_ConditionPicker_data_changed")
	use_condition_button.connect("toggled", self, "_on_UseConditonButton_toggled")
	input_field.connect("text_changed", self, "_on_InputField_text_changed")
	use_condition_button.visible = allow_disable_condition
	use_condition_button.pressed = !allow_disable_condition


# called by the event block
func load_data(data:Dictionary):
	# First set the event_data
	.load_data(data)
	
	# Now update the ui nodes to display the data. 
	input_field.text = event_data['value']
	definition_picker.load_data(event_data)
	condition_type_picker.load_data(event_data)
	use_condition_button.pressed = false
	if data.has('definition'):
		if data['definition'] != '':
			use_condition_button.pressed = true
	
	if data['event_id'] == 'dialogic_012': # If Condition event
		condition_type_picker.visible = true
		definition_picker.visible = true
		input_field.visible = true


# has to return the wanted preview, only useful for body parts
func get_preview():
	return ''


func _on_DefinitionPicker_data_changed(data):
	event_data = data
	
	# update the data in the other EventParts
	condition_type_picker.load_data(data)
	
	# informs the parent about the changes!
	data_changed()


func _on_ConditionPicker_data_changed(data):
	event_data = data
	
	# update the data in the other EventParts
	definition_picker.load_data(data)
	
	# informs the parent about the changes!
	data_changed()


func _on_InputField_text_changed(text):
	event_data['value'] = text
	
	# informs the parent about the changes!
	data_changed()


func _on_UseConditonButton_toggled(toggled):
	definition_picker.visible = toggled
	condition_type_picker.visible = toggled
	input_field.visible = toggled
	if not toggled and event_data:
		event_data['condition'] = ''
		event_data['definition'] = ''
		event_data['value'] = ''

