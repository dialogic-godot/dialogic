tool
extends "res://addons/dialogic/Editor/Events/Parts/EventPart.gd"

# has an event_data variable that stores the current data!!!

## node references
onready var image_button = $HBox/ImageButton
onready var clear_button = $HBox/ClearButton
onready var name_label = $HBox/Name

# used to connect the signals
func _ready():
	image_button.connect("pressed", self, "_on_ImageButton_pressed")
	clear_button.connect('pressed', self, "_on_ClearButton_pressed")
	pass

# called by the event block
func load_data(data:Dictionary):
	# First set the event_data
	.load_data(data)
	
	# Now update the ui nodes to display the data. 
	if event_data['background']:
		name_label.text = event_data['background'].get_file()
		image_button.hint_tooltip = event_data['background']
		emit_signal("request_close_body")
	else:
		name_label.text = 'No image (will clear previous background)'
		image_button.hint_tooltip = 'No background selected'
		emit_signal("request_close_body")
	
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
			
	emit_signal("request_open_body")
	# informs the parent about the changes!
	data_changed()

func _on_ClearButton_pressed():
	event_data['background'] = ''
	
	clear_button.disabled = true
	name_label.text = 'No image (will clear previous background)'
	image_button.hint_tooltip = 'No background selected'
	
	emit_signal("request_close_body")
	
	# informs the parent about the changes!
	data_changed()
