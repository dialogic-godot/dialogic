tool
extends "res://addons/dialogic/Editor/Events/Parts/EventPart.gd"

# has an event_data variable that stores the current data!!!

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
	if event_data['change_timeline'] != '':
		for c in DialogicUtil.get_timeline_list():
			if c['file'] == event_data['change_timeline']:
				picker_menu.text = c['name']
	else:
		picker_menu.text = 'Select Timeline'

# has to return the wanted preview, only useful for body parts
func get_preview():
	return ''

func _on_PickerMenu_selected(index):
	var text = picker_menu.get_popup().get_item_text(index)
	var metadata = picker_menu.get_popup().get_item_metadata(index)
	picker_menu.text = text
	
	event_data['change_timeline'] = metadata['file']
	# informs the parent about the changes!
	data_changed()


func _on_PickerMenu_about_to_show():
	picker_menu.get_popup().clear()
	var index = 0
	for c in DialogicUtil.get_sorted_timeline_list():
		picker_menu.get_popup().add_item(c['name'])
		picker_menu.get_popup().set_item_metadata(index, {'file': c['file'], 'color': c['color']})
		index += 1
