tool
extends "res://addons/dialogic/Editor/Events/Parts/EventPart.gd"

# has an event_data variable that stores the current data!!!

## node references
onready var input_field = $HBox/ChoiceText
onready var condition_picker = $ConditionPicker

# used to connect the signals
func _ready():
	# e.g. 
	input_field.connect("text_changed", self, "_on_ChoiceText_text_changed")
	condition_picker.connect("data_changed", self, "_on_ConditionPicker_data_changed")
	condition_picker.connect("remove_warning", self, "emit_signal", ["remove_warning"])
	condition_picker.connect("set_warning", self, "set_warning")

# called by the event block
func load_data(data:Dictionary):
	# First set the event_data
	.load_data(data)
	
	# Now update the ui nodes to display the data. 
	input_field.text = event_data['choice']
	
	# Loading the data on the selectors
	condition_picker.load_data(event_data)
	

# has to return the wanted preview, only useful for body parts
func get_preview():
	return ''


func _on_ChoiceText_text_changed(text):
	event_data['choice'] = text
	
	# informs the parent about the changes!
	data_changed()

func _on_ConditionPicker_data_changed(data):
	event_data = data
	
	data_changed()

func set_warning(text):
	emit_signal("set_warning", text)
