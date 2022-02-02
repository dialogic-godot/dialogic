tool
extends "res://addons/dialogic/Editor/Events/Parts/EventPart.gd"

# has an event_data variable that stores the current data!!!

## node references 
onready var character_portrait_picker = $HBox/CharacterAndPortraitPicker
onready var position_picker = $HBox/PositionPicker
onready var mirror_button = $HBox/MirrorButton
onready var no_character_button = $NoCharacterContainer/NoCharacterButton
onready var no_character_container = $NoCharacterContainer

# used to connect the signals
func _ready():
	if DialogicUtil.get_character_list().size() > 0:
		character_portrait_picker.show()
		position_picker.show()
		mirror_button.show()
		no_character_container.hide()
	else:
		character_portrait_picker.hide()
		position_picker.hide()
		mirror_button.hide()
		no_character_container.show()
		var editor_reference = find_parent('EditorView')
		no_character_button.connect('pressed', editor_reference.get_node('MainPanel/MasterTreeContainer/MasterTree'), 'new_character')
	
	
	mirror_button.connect("toggled", self, "_on_MirrorButton_toggled")
	character_portrait_picker.connect('data_changed', self, '_on_CharacterPortraitPicker_data_changed')
	position_picker.connect('data_changed', self, '_on_PositionPicker_data_changed')
	
	# icons
	mirror_button.icon = get_icon("MirrorX", "EditorIcons")

# called by the event block
func load_data(data:Dictionary):
	# First set the event_data
	.load_data(data)
	
	# Now update the ui nodes to display the data. 
	character_portrait_picker.load_data(data)
	position_picker.load_data(data)
	mirror_button.pressed = data['mirror']

# has to return the wanted preview, only useful for body parts
func get_preview():
	return ''

func _on_MirrorButton_toggled(toggle):
	event_data['mirror'] = toggle
	
	character_portrait_picker.load_data(event_data)
	position_picker.load_data(event_data)

	# informs the parent about the changes!
	data_changed()

func _on_PositionPicker_data_changed(data):
	event_data = data
	
	character_portrait_picker.load_data(event_data)

	# informs the parent about the changes!
	data_changed()

func _on_CharacterPortraitPicker_data_changed(data):
	event_data = data

	# informs the parent about the changes!
	data_changed()
