tool
extends "res://addons/dialogic/Editor/Events/Parts/EventPart.gd"

# has an event_data variable that stores the current data!!!

## node references
onready var input_field = $HBox/ChoiceText
onready var condition_picker = $ConditionPicker

#multilang support variables
onready var c_lang := "INTERNAL" #current language
#end of multilang support variables

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
	_load_event_text()
	
	# Loading the data on the selectors
	condition_picker.load_data(event_data)

func _load_event_text():
	if(c_lang == "INTERNAL"):
		input_field.text = event_data['choice']
		input_field.hint_tooltip = ""
	else:
		input_field.text = event_data.get('choice_'+c_lang)
		input_field.hint_tooltip = event_data['choice']

#part of the multilang support.
#Called from the editorview's toolbar via timeline editor and eventblock
func on_language_changed(language):
	c_lang = language
	_load_event_text()


# has to return the wanted preview, only useful for body parts
func get_preview():
	return ''


func _on_ChoiceText_text_changed(text):
	if(c_lang == "INTERNAL"):
		event_data['choice'] = text
	else:
		event_data['choice_'+c_lang] = text
	# informs the parent about the changes!
	data_changed()

func _on_ConditionPicker_data_changed(data):
	event_data = data
	
	data_changed()

func set_warning(text):
	emit_signal("set_warning", text)
