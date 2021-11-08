tool
extends "res://addons/dialogic/Editor/Events/Parts/EventPart.gd"

# has an event_data variable that stores the current data!!!

onready var definition_picker = $HBox/DefinitionPicker
onready var condition_type_picker = $HBox/ConditionTypePicker
onready var value_input = $HBox/Value

# used to connect the signals
func _ready():
	definition_picker.connect("data_changed", self, '_on_DefinitionPicker_data_changed')
	
	condition_type_picker.connect("data_changed", self, '_on_ConditionTypePicker_data_changed')
	
	value_input.connect("text_changed", self, "_on_Value_text_changed")



# called by the event block
func load_data(data:Dictionary):
	# First set the event_data
	.load_data(data)
	
	# Loading the data on the selectors
	definition_picker.load_data(data)
	condition_type_picker.load_data(data)
	value_input.text = data['value']
	
	
# has to return the wanted preview, only useful for body parts
func get_preview():
	return ''


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
	if event_data['condition'] != '==' and event_data['condition'] != '!=' and event_data['condition'] != '':
		if not event_data['value'].is_valid_float():
			emit_signal("set_warning", DTS.translate("The selected operator requires a number!"))
			return
	
	emit_signal("remove_warning")
