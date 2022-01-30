tool
extends "res://addons/dialogic/Editor/Events/Parts/EventPart.gd"

# has an event_data variable that stores the current data!!!
var default_icon_color = Color("#65989898")
var enable_icon
var disable_icon

## node references
onready var positions_container = $HBox/PositionsContainer
onready var enable_position = $HBox/EnablePosition
# used to connect the signals
func _ready():
	for p in positions_container.get_children():
		p.connect('pressed', self, "position_button_pressed", [p.name])
	enable_position.connect('toggled', self, 'on_EnablePosition_toggled')
	enable_icon = get_icon("Edit", "EditorIcons")
	disable_icon = get_icon("Reload", "EditorIcons")

# called by the event block
func load_data(data:Dictionary):
	# First set the event_data
	.load_data(data)
	
	if data.get('type', 0) == 0:
		$HBox/Label.text = 'at position'
	elif data.get('type', 0) == 2:
		if not data.get('change_position', false):
			$HBox/Label.text = '(same position)'
		else:
			$HBox/Label.text = 'to position'
	
	enable_position.pressed = data.get('change_position', false) or data.get('type', 0) != 2
	enable_position.visible = data.get('type', 0) == 2
	enable_position.icon = enable_icon if not enable_position.pressed else disable_icon
	positions_container.visible = enable_position.pressed
	
	# Now update the ui nodes to display the data. 
	check_active_position()

# has to return the wanted preview, only useful for body parts
func get_preview():
	return ''

func get_character_color():
	for ch in DialogicUtil.get_character_list():
		if ch['file'] == event_data['character']:
			return ch['color']
	return default_icon_color

func position_button_pressed(name):
	clear_all_positions()
	var selected_index = name.split('-')[1]
	var button = positions_container.get_node('position-' + selected_index)
	button.set('self_modulate', get_character_color())
	button.pressed = true
	
	event_data['position'][selected_index] = true
	
	data_changed()

func clear_all_positions():
	if not event_data.get('position', false):
		event_data['position'] = {}
	for i in range(5):
		event_data['position'][str(i)] = false
	for p in positions_container.get_children():
		p.set('self_modulate', default_icon_color)
		p.pressed = false


func check_active_position(active_color = Color("#ffffff")):
	if not event_data.get('position', false): return
	var index = 0
	for p in positions_container.get_children():
		if event_data['position'][str(index)]:
			p.pressed = true
			p.set('self_modulate', get_character_color())
		index += 1

func on_EnablePosition_toggled(toggled):
	if event_data['type'] != 2: return
	event_data['change_position'] = toggled
	
	positions_container.visible = enable_position.pressed
	enable_position.icon = enable_icon if not enable_position.pressed else disable_icon
	
	if !toggled:
		$HBox/Label.text = '(same position)'
	else:
		$HBox/Label.text = 'to position'
	
	# informs the parent about the changes!
	data_changed()
