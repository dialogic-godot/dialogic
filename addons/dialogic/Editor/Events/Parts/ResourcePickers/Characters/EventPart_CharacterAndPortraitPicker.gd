tool
extends "res://addons/dialogic/Editor/Events/Parts/EventPart.gd"

# has an event_data variable that stores the current data!!!
export (bool) var allow_portrait_dont_change := true

## node references
onready var character_picker = $HBox/CharacterPicker
onready var portrait_picker = $HBox/PortraitPicker

# used to connect the signals
func _ready():
	character_picker.connect("data_changed", self, "_on_CharacterPicker_data_changed")
	portrait_picker.connect("data_changed", self, "_on_PortraitPicker_data_changed")
	portrait_picker.allow_dont_change = allow_portrait_dont_change

# called by the event block
func load_data(data:Dictionary):
	# First set the event_data
	.load_data(data)
	
	# Now update the ui nodes to display the data. 
	portrait_picker.load_data(data)
	character_picker.load_data(data)
	portrait_picker.visible = get_character_data() and len(get_character_data()['portraits']) > 1

# has to return the wanted preview, only useful for body parts
func get_preview():
	return ''

func get_character_data():
	for ch in DialogicUtil.get_character_list():
		if ch['file'] == event_data['character']:
			return ch

func _on_CharacterPicker_data_changed(data):
	event_data = data
	
	# update the portrait picker data
	portrait_picker.load_data(data)
	portrait_picker.visible = get_character_data() and len(get_character_data()['portraits']) > 1
	
	# informs the parent about the changes!
	data_changed()


func _on_PortraitPicker_data_changed(data):
	event_data = data
	
	# update the portrait picker data
	character_picker.load_data(data)
	
	# informs the parent about the changes!
	data_changed()
