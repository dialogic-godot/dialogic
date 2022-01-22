tool
extends "res://addons/dialogic/Editor/Events/Parts/EventPart.gd"

# has an event_data variable that stores the current data!!!

## node references
onready var animation_picker = $HBoxContainer/AnimationPicker
onready var animation_length = $HBoxContainer/AnimationLength
onready var z_index = $HBoxContainer1/Z_Index

# used to connect the signals
func _ready():
	animation_picker.connect("about_to_show", self, "_on_AnimationPicker_about_to_show")
	animation_picker.get_popup().connect("index_pressed", self, "_on_AnimationPicker_index_pressed")
	animation_length.connect("value_changed", self, "_on_AnimationLength_value_changed")
	z_index.connect("value_changed", self, "_on_ZIndex_value_changed")
	
	animation_picker.custom_icon = get_icon("Animation", "EditorIcons")

# called by the event block
func load_data(data:Dictionary):
	# First set the event_data
	.load_data(data)
	
	# Now update the ui nodes to display the data. 
	animation_picker.text = DialogicUtil.get_animation_data(event_data.get('animation', 0))['name']
	animation_length.value = event_data.get('animation_length', 1)
	z_index.value = event_data.get('z_index', 0)

# has to return the wanted preview, only useful for body parts
func get_preview():
	return ''

func _on_AnimationPicker_about_to_show():
	animation_picker.get_popup().clear()
	var animations = DialogicUtil.get_animation_names()
	for element in animations.keys():
		animation_picker.get_popup().add_icon_item(get_icon("Animation", "EditorIcons"), element, animations[element])


func _on_AnimationPicker_index_pressed(index):
	event_data['animation'] = animation_picker.get_popup().get_item_id(index)
	
	var data = DialogicUtil.get_animation_data(event_data['animation'])
	if animation_picker.text != data['name']:
		animation_picker.text = data['name']
		animation_length.value = data['default_length']
	
	# informs the parent about the changes!
	data_changed()

func _on_AnimationLength_value_changed(value):
	event_data['animation_length'] = value
	
	# informs the parent about the changes!
	data_changed()

func _on_ZIndex_value_changed(value):
	event_data['z_index'] = value
	
	# informs the parent about the changes!
	data_changed()
