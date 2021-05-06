tool
extends "res://addons/dialogic/Editor/Events/Parts/EventPart.gd"

# has an event_data variable that stores the current data!!!

## node references
onready var input_field = $HBox/InputField
onready var definition_picker = $HBox/DefinitionPicker
onready var operation_picker = $HBox/OperationPicker

# used to connect the signals
func _ready():
	input_field.connect("text_changed", self, "_on_InputField_text_changed")
	definition_picker.connect("data_changed", self, "_on_DefintionPicker_data_changed")
	operation_picker.connect("data_changed", self, "_on_OperationPicker_data_changed")

# called by the event block
func load_data(data:Dictionary):
	# First set the event_data
	.load_data(data)
	
	# Now update the ui nodes to display the data. 
	input_field.text = event_data['set_value']
	definition_picker.load_data(data)
	operation_picker.load_data(data)

# has to return the wanted preview, only useful for body parts
func get_preview():
	return ''

func check_data():
	if event_data['operation'] != '=':
		if not event_data['set_value'].is_valid_float():
			emit_signal("set_warning", "The selected operator requiers a number!")
			return
	
	emit_signal("remove_warning")

func _on_InputField_text_changed(text):
	event_data['set_value'] = text
	
	operation_picker.load_data(event_data)
	definition_picker.load_data(event_data)
	
	check_data()
	
	# informs the parent about the changes!
	data_changed()

func _on_DefintionPicker_data_changed(data):
	event_data = data
	
	operation_picker.load_data(data)
	
	# informs the parent about the changes!
	data_changed()

func _on_OperationPicker_data_changed(data):
	event_data = data
	
	definition_picker.load_data(data)
	
	check_data()
	
	# informs the parent about the changes!
	data_changed()

