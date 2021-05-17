tool
extends "res://addons/dialogic/Editor/Events/Parts/EventPart.gd"

# has an event_data variable that stores the current data!!!
export (String) var default_text = "Select Theme"

## node references
onready var picker_menu = $MenuButton

# used to connect the signals
func _ready():
	picker_menu.get_popup().connect("index_pressed", self, '_on_PickerMenu_selected')
	picker_menu.connect("about_to_show", self, "_on_PickerMenu_about_to_show")

# called by the event block
func load_data(data:Dictionary):
	# First set the event_data
	.load_data(data)
	
	# Now update the ui nodes to display the data. 
	select_theme()
	
# has to return the wanted preview, only useful for body parts
func get_preview():
	return ''

func select_theme():
	if event_data['set_theme'] != '':
		for theme in DialogicUtil.get_theme_list():
			if theme['file'] == event_data['set_theme']:
				picker_menu.text = theme['name']
	else:
		picker_menu.text = default_text

func _on_PickerMenu_selected(index):
	event_data['set_theme'] = picker_menu.get_popup().get_item_metadata(index).get('file', '')
	
	select_theme()
	
	# informs the parent about the changes!
	data_changed()

func _on_PickerMenu_about_to_show():
	picker_menu.get_popup().clear()
	
	var index = 0
	for t in DialogicUtil.get_sorted_theme_list():
		picker_menu.get_popup().add_item(t['name'])
		picker_menu.get_popup().set_item_metadata(index, t)
		index += 1
