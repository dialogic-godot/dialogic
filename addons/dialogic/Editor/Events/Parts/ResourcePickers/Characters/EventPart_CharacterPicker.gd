tool
extends "res://addons/dialogic/Editor/Events/Parts/EventPart.gd"

# has an event_data variable that stores the current data!!!

export (bool) var allow_no_character := false

## node references
onready var picker_menu = $HBox/MenuButton
onready var icon = $HBox/Icon

# used to connect the signals
func _ready():
	picker_menu.get_popup().connect("index_pressed", self, '_on_PickerMenu_selected')
	picker_menu.connect("about_to_show", self, "_on_PickerMenu_about_to_show")
	
	
# called by the event block
func load_data(data:Dictionary):
	# First set the event_data
	.load_data(data)
	
	# Now update the ui nodes to display the data. 
	update_to_character()

# has to return the wanted preview, only useful for body parts
func get_preview():
	return ''

# helper to not have the same code everywhere
func update_to_character():
	if event_data['character'] != '':
		if event_data['character'] == '[All]':
			picker_menu.text = "[All characters]"
			icon.modulate = Color.white
		else:
			for ch in DialogicUtil.get_character_list():
				if ch['file'] == event_data['character']:
					picker_menu.text = ch['name']
					icon.modulate = ch['color']
	else:
		if allow_no_character:
			picker_menu.text = '[No Character]'
		else:
			picker_menu.text = '[Select Character!]'
		icon.modulate = Color.white

func _on_PickerMenu_selected(index):
	event_data['character'] = picker_menu.get_popup().get_item_metadata(index).get('file', '')
	
	update_to_character()
	
	# informs the parent about the changes!
	data_changed()


func _on_PickerMenu_about_to_show():
	picker_menu.get_popup().clear()
	var index = 0
	if allow_no_character:
		picker_menu.get_popup().add_item('[No character]')
		picker_menu.get_popup().set_item_metadata(index, {'file':''})
		index += 1
	
	# in case this is a leave event
	if event_data['event_id'] == 'dialogic_003':
		picker_menu.get_popup().add_item('[All characters]')
		picker_menu.get_popup().set_item_metadata(index, {'file': '[All]'})
		index += 1

	for c in DialogicUtil.get_sorted_character_list():
		picker_menu.get_popup().add_item(c['name'])
		picker_menu.get_popup().set_item_metadata(index, c)
		index += 1
