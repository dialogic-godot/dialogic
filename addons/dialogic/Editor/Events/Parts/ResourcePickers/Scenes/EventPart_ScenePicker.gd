tool
extends "res://addons/dialogic/Editor/Events/Parts/EventPart.gd"

# has an event_data variable that stores the current data!!!

## node references
onready var name_label = $HBox/Name
onready var scene_button = $HBox/ScenePickerButton


# used to connect the signals
func _ready():
	scene_button.connect("pressed", self, "_on_ScenePickerButton_pressed")
	pass

# called by the event block
func load_data(data:Dictionary):
	# First set the event_data
	.load_data(data)
	
	# Now update the ui nodes to display the data. 
	if event_data['change_scene']:
		name_label.text = event_data['change_scene']
	else:
		name_label.text = "No scene selected (will do nothing)"

# has to return the wanted preview, only useful for body parts
func get_preview():
	return ''

func _on_ScenePickerButton_pressed():
	editor_reference.godot_dialog("*.tscn")
	editor_reference.godot_dialog_connect(self, "_on_file_selected")

func _on_file_selected(path, target):
	name_label.text = path
	event_data['change_scene'] = path
	
	data_changed()

	
