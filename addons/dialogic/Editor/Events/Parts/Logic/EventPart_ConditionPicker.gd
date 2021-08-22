tool
extends "res://addons/dialogic/Editor/Events/Parts/EventPart.gd"

# has an event_data variable that stores the current data!!!

onready var enabled_view = $HBox/Values
onready var definition_picker = $HBox/Values/DefinitionPicker
onready var condition_type_picker = $HBox/Values/ConditionTypePicker
onready var value_input = $HBox/Values/Value

onready var optional_view = $HBox/HasCondition
onready var use_condition_check = $HBox/HasCondition/UseCondition

# used to connect the signals
func _ready():
	definition_picker.connect("data_changed", self, '_on_DefinitionPicker_data_changed')
	
	condition_type_picker.connect("data_changed", self, '_on_ConditionTypePicker_data_changed')
	
	value_input.connect("text_changed", self, "_on_Value_text_changed")

	use_condition_check.connect("toggled", self, "_on_UseCondition_toggled")
	

# called by the event block
func load_data(data:Dictionary):
	# First set the event_data
	.load_data(data)
	
	# Loading the data on the selectors
	definition_picker.load_data(data)
	condition_type_picker.load_data(data)
	value_input.text = data['value']
	
	if data['event_id'] == 'dialogic_011':
		optional_view.show()
		if data['definition'] == '': # Checking if definition is selected
			use_condition_check.pressed = false
			enabled_view.hide()
		else:
			use_condition_check.pressed = true
			enabled_view.show()
	else:
		optional_view.hide()
	
# has to return the wanted preview, only useful for body parts
func get_preview():
	return ''


func _on_UseCondition_toggled(checkbox_value):
	enabled_view.visible = checkbox_value
	if checkbox_value == false:
		event_data['definition'] = ''
		event_data['condition'] = ''
		event_data['value'] = ''
	
	data_changed()

func _on_DefinitionPicker_data_changed(data):
	event_data = data
	
	data_changed()

func _on_ConditionTypePicker_data_changed(data):
	event_data = data
	check_data()
	data_changed()
	
	# Focusing the value input
	value_input.call_deferred('grab_focus')

func _on_Value_text_changed(text):
	event_data['value'] = text
	check_data()
	
	data_changed()

func check_data():
	if event_data['condition'] != '==' and event_data['condition'] != '!=':
		if not event_data['value'].is_valid_float():
			emit_signal("set_warning", DTS.translate("The selected operator requires a number!"))
			return
	
	emit_signal("remove_warning")
