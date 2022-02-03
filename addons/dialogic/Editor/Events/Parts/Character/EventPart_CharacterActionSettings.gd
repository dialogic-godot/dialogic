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
onready var animation_repeat = $Animation/Repeat
onready var animation_wait_checkbox = $Animation/WaitForAnimation

# used to connect the signals
func _ready():
	animation_picker.connect("about_to_show", self, "_on_AnimationPicker_about_to_show")
	animation_picker.get_popup().connect("index_pressed", self, "_on_AnimationPicker_index_pressed")
	animation_length.connect("value_changed", self, "_on_AnimationLength_value_changed")
	z_index.connect("value_changed", self, "_on_ZIndex_value_changed")
	z_index_enable.connect("toggled", self, "_on_ZIndexEnable_toggled")
	mirrored_checkbox.connect('toggled', self, "_on_Mirrored_toggled")
	mirrored_checkbox_enable.connect('toggled', self, "_on_MirroredEnabled_toggled")
	animation_repeat.connect("value_changed", self, '_on_Repeat_value_changed')
	animation_wait_checkbox.connect('toggled', self, 'on_WaitForAnimation_toggled')
	enable_icon = get_icon("Edit", "EditorIcons")
	disable_icon = get_icon("Reload", "EditorIcons")


# called by the event block
func load_data(data:Dictionary):
	# First set the event_data
	.load_data(data)
	
	# Now update the ui nodes to display the data. 
	$Positioning.visible = event_data.get('type',0) != 1
	if data['type'] == 0:
		animation_picker.text = DialogicUtil.beautify_filename(event_data.get('animation', '[Default]'))
	elif data['type'] == 1:
		animation_picker.text = DialogicUtil.beautify_filename(event_data.get('animation', '[Default]'))
	else:
		animation_picker.text = DialogicUtil.beautify_filename(event_data.get('animation', '[No Animation]'))
		
	animation_picker.custom_icon = get_icon("Animation", "EditorIcons") if event_data['animation'] != "[No Animation]" else get_icon("GuiRadioUnchecked", "EditorIcons")
	if event_data['animation'] == "[Default]": animation_picker.custom_icon = get_icon("Favorites", "EditorIcons")
	animation_length.value = event_data.get('animation_length', 1)
	animation_length.visible = event_data.get('animation', '') != "[Default]"
	$Animation/Label2.visible = event_data.get('animation', '') != "[Default]"
	animation_repeat.value = event_data.get('animation_repeat', 1)
	animation_repeat.visible = int(data.get('type', 0)) == 2
	$Animation/Label3.visible = int(data.get('type', 0)) == 2
	animation_wait_checkbox.pressed = event_data.get('animation_wait', false)
	
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
	var animations = DialogicAnimaResources.get_available_animations()
	var idx = 0
	if event_data['type'] == 2:
		animation_picker.get_popup().add_icon_item(get_icon("GuiRadioUnchecked", "EditorIcons"), "[No Animation]")
		animation_picker.get_popup().set_item_metadata(idx, {'file': "[No Animation]"})
		idx += 1
	else:
		animation_picker.get_popup().add_icon_item(get_icon("Favorites", "EditorIcons"), "[Default]")
		animation_picker.get_popup().set_item_metadata(idx, {'file': "[Default]"})
		idx += 1
	for animation_name in animations:
		if (event_data['type'] == 0 and '_in' in animation_name) \
		or (event_data['type'] == 1 and '_out' in animation_name) \
		or (event_data['type'] == 2 and not '_in' in animation_name and not '_out' in animation_name):
			animation_picker.get_popup().add_icon_item(get_icon("Animation", "EditorIcons"), DialogicUtil.beautify_filename(animation_name))
			animation_picker.get_popup().set_item_metadata(idx, {'file': animation_name.get_file()})
			idx +=1
	


func _on_AnimationPicker_index_pressed(index):
	event_data['animation'] = animation_picker.get_popup().get_item_metadata(index)['file']
	
	animation_picker.custom_icon = get_icon("Animation", "EditorIcons") if event_data['animation'] != "[No Animation]" else get_icon("GuiRadioUnchecked", "EditorIcons")
	if event_data['animation'] == "[Default]": animation_picker.custom_icon = get_icon("Favorites", "EditorIcons")
	animation_picker.text = animation_picker.get_popup().get_item_text(index)
	
	animation_length.visible = event_data.get('animation', '') != "[Default]"
	$Animation/Label2.visible = event_data.get('animation', '') != "[Default]"
	
	# informs the parent about the changes!
	data_changed()

func _on_AnimationLength_value_changed(value):
	event_data['animation_length'] = value
	
	# informs the parent about the changes!
	data_changed()


func _on_Repeat_value_changed(value):
	event_data['animation_repeat'] = value
	
	# informs the parent about the changes!
	data_changed()

func on_WaitForAnimation_toggled(toggled):
	event_data['animation_wait'] = toggled
	
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
