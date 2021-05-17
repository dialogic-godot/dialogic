tool
extends "res://addons/dialogic/Editor/Events/Parts/EventPart.gd"

# has an event_data variable that stores the current data!!!
export (String) var default_text = "Select Glossary Item"

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
	select_glossary_by_id(data['glossary_id'])
	
# has to return the wanted preview, only useful for body parts
func get_preview():
	return ''

func select_glossary_by_id(id):
	if id != '':
		for d in DialogicResources.get_default_definitions()['glossary']:
			if d['id'] == id:
				picker_menu.text = d['name']
	else:
		picker_menu.text = default_text

func _on_PickerMenu_selected(index):
	event_data['glossary_id'] = picker_menu.get_popup().get_item_metadata(index).get('id', '')
	
	select_glossary_by_id(event_data['glossary_id'])
	
	# informs the parent about the changes!
	data_changed()

func _on_PickerMenu_about_to_show():
	picker_menu.get_popup().clear()
	
	var index = 0
	for d in DialogicUtil.get_default_definitions_list():
		if d['type'] == 1:
			picker_menu.get_popup().add_item(d['name'])
			picker_menu.get_popup().set_item_metadata(index, d)
			index += 1
