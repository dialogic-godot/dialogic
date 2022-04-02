tool
extends "res://addons/dialogic/Editor/Events/Parts/EventPart.gd"

# has an resource.properties variable that stores the current data!!!

## node references
onready var file_picker = $HBox/FilePicker

onready var fade_duration_label = $HBox/FadeLabel
onready var fade_duration = $HBox/NumberBox

# used to connect the signals
func _ready():
	file_picker.connect("data_changed", self, "_on_FilePicker_data_changed")
	fade_duration.connect('value_changed', self, '_on_fade_duration_changed')



# called by the event block
func load_data(data:Dictionary):
	# First set the event_data
	.load_data(data)
	
	# Now update the ui nodes to display the data. 
	file_picker.load_data(data)
	if resource.properties['background']:
		fade_duration_label.visible = true
		fade_duration.visible = true
		emit_signal("request_close_body")
	else:
		fade_duration_label.visible = false
		fade_duration.visible = false
		emit_signal("request_close_body")

	fade_duration.value = resource.properties.get('fade_duration', 1)

# has to return the wanted preview, only useful for body parts
func get_preview():
	return ''

func _on_FilePicker_data_changed(data):
	resource.properties = data
	
	fade_duration.visible = !data['background'].empty()
	fade_duration_label.visible = !data['background'].empty()

	if !data['background'].empty():
		emit_signal("request_open_body")
	else:
		emit_signal("request_close_body")
		
	# informs the parent about the changes!
	data_changed()

#func _on_ClearButton_pressed():
#	resource.properties['background'] = ''
#
#	clear_button.disabled = true
#	name_label.text = 'No image (will clear previous background)'
#	image_button.hint_tooltip = 'No background selected'
#	fade_duration.visible = false
#	fade_duration_label.visible = false
#	fade_duration.value = 1
#
#	emit_signal("request_close_body")
#
#	# informs the parent about the changes!
#	data_changed()

func _on_fade_duration_changed(value: float):
	resource.properties['fade_duration'] = value
	# informs the parent about the changes!
	data_changed()
