tool
extends "res://addons/dialogic/Editor/Events/Parts/EventPart.gd"

# has an event_data variable that stores the current data!!!

## node references
onready var audio_picker = $HBox/AudioPicker
onready var fade_length_input = $HBox/FadeLength

# used to connect the signals
func _ready():
	audio_picker.connect("data_changed", self, "_on_AudioPicker_data_changed")
	fade_length_input.connect("value_changed", self, "_on_FadeLength_value_changed")

# called by the event block
func load_data(data:Dictionary):
	# First set the event_data
	.load_data(data)
	
	# Now update the ui nodes to display the data. 
	audio_picker.editor_reference = editor_reference
	audio_picker.load_data(event_data)
	
	fade_length_input.value = event_data['fade_length']

# has to return the wanted preview, only useful for body parts
func get_preview():
	return audio_picker.get_preview()

func _on_AudioPicker_data_changed(data):
	event_data  = data
	
	# informs the parent about the changes!
	data_changed()

func _on_FadeLength_value_changed(value):
	event_data['fade_length'] = value
	audio_picker.load_data(event_data)
	
	# informs the parent about the changes!
	data_changed()
	
