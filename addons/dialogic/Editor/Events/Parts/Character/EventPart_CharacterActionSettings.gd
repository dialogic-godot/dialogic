tool
extends "res://addons/dialogic/Editor/Events/Parts/EventPart.gd"

# has an event_data variable that stores the current data!!!
var enable_icon = null
var disable_icon = null


## node references
onready var animation_picker = $Animation/AnimationPicker
onready var animation_length = $Animation/AnimationLength
onready var z_index_enable = $Positioning/EnableZIndex
onready var z_index = $Positioning/Z_Index
onready var mirrored_checkbox = $Positioning/Mirrored
onready var mirrored_checkbox_enable = $Positioning/EnableMirrored

# used to connect the signals
func _ready():
	animation_picker.connect("about_to_show", self, "_on_AnimationPicker_about_to_show")
	animation_picker.get_popup().connect("index_pressed", self, "_on_AnimationPicker_index_pressed")
	animation_length.connect("value_changed", self, "_on_AnimationLength_value_changed")
	z_index.connect("value_changed", self, "_on_ZIndex_value_changed")
	z_index_enable.connect("toggled", self, "_on_ZIndexEnable_toggled")
	mirrored_checkbox.connect('toggled', self, "_on_Mirrored_toggled")
	mirrored_checkbox_enable.connect('toggled', self, "_on_MirroredEnabled_toggled")
	animation_picker.custom_icon = get_icon("Animation", "EditorIcons")
	
	enable_icon = get_icon("Edit", "EditorIcons")
	disable_icon = get_icon("Reload", "EditorIcons")


# called by the event block
func load_data(data:Dictionary):
	# First set the event_data
	.load_data(data)
	
	# Now update the ui nodes to display the data. 
	$Positioning.visible = event_data.get('type',0) != 1
	if data['type'] != 2:
		animation_picker.text = DialogicUtil.get_animation_data(event_data.get('animation', 0))['name']
	else:
		animation_picker.text = DialogicUtil.get_animation_data(event_data.get('animation', 5))['name']
	animation_length.value = event_data.get('animation_length', 1)
	z_index.value = int(event_data.get('z_index', 0))
	mirrored_checkbox.pressed = event_data.get('mirror_portrait', false)
	
	# if the event is in UPDATE mode show the enablers
	z_index_enable.visible = int(data.get('type', 0)) == 2
	mirrored_checkbox_enable.visible = int(data.get('type', 0)) == 2
	
	z_index_enable.pressed = data.get('change_z_index', false) or int(data.get('type', 0)) != 2
	mirrored_checkbox_enable.pressed = data.get('change_mirror_portrait', false) or int(data.get('type', 0)) != 2
	
	z_index.visible = z_index_enable.pressed
	mirrored_checkbox.visible = mirrored_checkbox_enable.pressed
	
	z_index_enable.icon = enable_icon if not z_index_enable.pressed else disable_icon
	mirrored_checkbox_enable.icon = enable_icon if not mirrored_checkbox_enable.pressed else disable_icon


# has to return the wanted preview, only useful for body parts
func get_preview():
	return ''

func _on_AnimationPicker_about_to_show():
	animation_picker.get_popup().clear()
	var animation_data = DialogicUtil.animations()
	for key in animation_data.keys():
		if (animation_data[key]['type'] == 0 and event_data['type'] != 2) or \
			(animation_data[key]['type'] == 1 and event_data['type'] == 2):
			animation_picker.get_popup().add_icon_item(get_icon("Animation", "EditorIcons"), animation_data[key]['name'], key)
	


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

func _on_ZIndexEnable_toggled(toggled):
	if event_data['type'] != 2: return
	event_data['change_z_index'] = toggled
	
	z_index.visible = z_index_enable.pressed
	z_index_enable.icon = enable_icon if not z_index_enable.pressed else disable_icon
	
	# informs the parent about the changes!
	data_changed()

func _on_ZIndex_value_changed(value):
	event_data['z_index'] = value
	
	# informs the parent about the changes!
	data_changed()

func _on_MirroredEnabled_toggled(toggled):
	if event_data['type'] != 2: return
	event_data['change_mirror_portrait'] = toggled
	
	mirrored_checkbox.visible = mirrored_checkbox_enable.pressed
	mirrored_checkbox_enable.icon = enable_icon if not mirrored_checkbox_enable.pressed else disable_icon
	
	# informs the parent about the changes!
	data_changed()

func _on_Mirrored_toggled(toggled):
	event_data['mirror_portrait'] = toggled
	
	# informs the parent about the changes!
	data_changed()
