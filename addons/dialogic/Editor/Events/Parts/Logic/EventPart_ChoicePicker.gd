tool
extends "res://addons/dialogic/Editor/Events/Parts/EventPart.gd"

# has an event_data variable that stores the current data!!!

## node references
onready var input_field = $HBox/ChoiceText

# used to connect the signals
func _ready():
	# e.g. 
	input_field.connect("text_changed", self, "_on_ChoiceText_text_changed")
	$ConditionPicker.optional = true

# called by the event block
func load_data(data:Dictionary):
	# First set the event_data
	.load_data(data)
	
	# Now update the ui nodes to display the data. 
	input_field.text = event_data['choice']
	
	# Loading the data on the selectors
	$ConditionPicker.set_definition(data['definition'])
	$ConditionPicker.set_condition(data['condition'])
	$ConditionPicker.Value.text = data['value']
	if data['definition'] != '': # Checking if definition is selected
		$ConditionPicker/HasCondition/CheckBox.pressed = true

# has to return the wanted preview, only useful for body parts
func get_preview():
	return ''


func _on_ChoiceText_text_changed(text):
	event_data['choice'] = text
	
	# informs the parent about the changes!
	data_changed()
