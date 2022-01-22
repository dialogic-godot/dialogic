tool
extends "res://addons/dialogic/Editor/Events/Parts/EventPart.gd"

# has an event_data variable that stores the current data!!!
var options = [
	{
		"text": "Equal to",
		"condition": "=="
	},
	{
		"text": "Different from",
		"condition": "!="
	},
	{
		"text": "Greater than",
		"condition": ">"
	},
	{
		"text": "Greater or equal to",
		"condition": ">="
	},
	{
		"text": "Less than",
		"condition": "<"
	},
	{
		"text": "Less or equal to",
		"condition": "<="
	}
]
## node references
onready var picker_menu = $MenuButton

# used to connect the signals
func _ready():
	# e.g. 
	picker_menu.get_popup().connect("index_pressed", self, '_on_PickerMenu_selected')
	picker_menu.connect("about_to_show", self, "_on_PickerMenu_about_to_show")
	picker_menu.custom_icon = get_icon("GDScript", "EditorIcons")

# called by the event block
func load_data(data:Dictionary):
	# First set the event_data
	.load_data(data)
	
	# Now update the ui nodes to display the data. 
	select_condition_type(data['condition'])
	

# has to return the wanted preview, only useful for body parts
func get_preview():
	return ''

func select_condition_type(condition):
	if condition != '':
		for o in options:
			if (o['condition'] == condition):
				picker_menu.text = o['text']
	else:
		picker_menu.text = options[0]['text']

func _on_PickerMenu_selected(index):
	event_data['condition'] = picker_menu.get_popup().get_item_metadata(index).get('condition', '')
	
	select_condition_type(event_data['condition'])
	
	# informs the parent about the changes!
	data_changed()

func _on_PickerMenu_about_to_show():
	picker_menu.get_popup().clear()
	var index = 0
	for o in options:
		picker_menu.get_popup().add_item(o['text'])
		picker_menu.get_popup().set_item_metadata(index, o)
		index += 1
