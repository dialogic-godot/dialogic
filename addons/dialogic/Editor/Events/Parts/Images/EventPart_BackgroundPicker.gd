tool
extends "res://addons/dialogic/Editor/Events/Parts/EventPart.gd"

# has an event_data variable that stores the current data!!!

## node references
onready var image_button = $HBox/ImageButton
onready var clear_button = $HBox/ClearButton
onready var name_label = $HBox/Name
onready var fade_duration_label = $HBox/FadeLabel
onready var fade_duration = $HBox/NumberBox

# used to connect the signals
func _ready():
	image_button.connect("pressed", self, "_on_ImageButton_pressed")
	clear_button.connect('pressed', self, "_on_ClearButton_pressed")
	fade_duration.connect('value_changed', self, '_on_fade_duration_changed')
	pass

# called by the event block
func load_data(data:Dictionary):
	# First set the event_data
	.load_data(data)
	
	# Now update the ui nodes to display the data. 
	if event_data['background']:
		name_label.text = event_data['background'].get_file()
		image_button.hint_tooltip = event_data['background']
		fade_duration_label.visible = true
		fade_duration.visible = true
		emit_signal("request_close_body")
	else:
		name_label.text = 'No image (will clear previous background)'
		image_button.hint_tooltip = 'No background selected'
		fade_duration_label.visible = false
		fade_duration.visible = false
		emit_signal("request_close_body")
	
	fade_duration.value = event_data.get('fade_duration', 1)
	
	clear_button.disabled = not bool(event_data['background'])
	

# has to return the wanted preview, only useful for body parts
func get_preview():
	return ''

func _on_ImageButton_pressed():
	editor_reference.godot_dialog("*.png, *.jpg, *.jpeg, *.tga, *.svg, *.svgz, *.bmp, *.webp, *.tscn")
	editor_reference.godot_dialog_connect(self, "_on_file_selected")

func _on_file_selected(path, target):
	event_data['background'] = path
	
	clear_button.disabled = false
	name_label.text = event_data['background'].get_file()
	image_button.hint_tooltip = event_data['background']
	fade_duration.visible = true
	fade_duration_label.visible = true
	
	emit_signal("request_open_body")
	# informs the parent about the changes!
	data_changed()

func _on_ClearButton_pressed():
	event_data['background'] = ''
	
	clear_button.disabled = true
	name_label.text = 'No image (will clear previous background)'
	image_button.hint_tooltip = 'No background selected'
	fade_duration.visible = false
	fade_duration_label.visible = false
	fade_duration.value = 1
	
	emit_signal("request_close_body")
	
	# informs the parent about the changes!
	data_changed()

func _on_fade_duration_changed(value: float):
	event_data['fade_duration'] = value
	# informs the parent about the changes!
	data_changed()
