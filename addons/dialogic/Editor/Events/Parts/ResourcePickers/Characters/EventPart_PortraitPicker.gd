tool
extends "res://addons/dialogic/Editor/Events/Parts/EventPart.gd"

# has an event_data variable that stores the current data!!!

export (bool) var allow_dont_change := true
export (bool) var allow_definition := true

## node references
onready var picker_menu = $HBox/MenuButton

# used to connect the signals
func _ready():
	picker_menu.get_popup().connect("index_pressed", self, '_on_PickerMenu_selected')
	picker_menu.connect("about_to_show", self, "_on_PickerMenu_about_to_show")

# called by the event block
func load_data(data:Dictionary):
	# First set the event_data
	.load_data(data)
	
	# Now update the ui nodes to display the data. 
	picker_menu.text = event_data['portrait']

# has to return the wanted preview, only useful for body parts
func get_preview():
	return ''

func _on_PickerMenu_selected(index):
	if index == 0 and allow_dont_change:
		event_data['portrait'] = "(Don't change)"
	elif allow_definition and ((allow_dont_change and index == 1) or index == 0):
		event_data['portrait'] = "[Definition]"
	else:
		event_data['portrait'] = picker_menu.get_popup().get_item_text(index)
	
	picker_menu.text = event_data['portrait']
	
	# informs the parent about the changes!
	data_changed()

func get_character_data():
	for ch in DialogicUtil.get_character_list():
		if ch['file'] == event_data['character']:
			return ch

func _on_PickerMenu_about_to_show():
	picker_menu.get_popup().clear()
	var index = 0
	if allow_dont_change:
		picker_menu.get_popup().add_item("(Don't change)")
		index += 1
	if allow_definition:
		picker_menu.get_popup().add_item("[Definition]")
		index += 1
	if event_data['character']:
		var character = get_character_data()
		if character.has('portraits'):
			for p in character['portraits']:
				picker_menu.get_popup().add_item(p['name'])
				index += 1
