tool
extends "res://addons/dialogic/Editor/Events/Parts/EventPart.gd"

# has an event_data variable that stores the current data!!!

var options = [
	{
		"text": "to be",
		"operation": "="
	},
	{
		"text": "to itself plus",
		"operation": "+"
	},
	{
		"text": "to itself minus",
		"operation": "-"
	},
	{
		"text": "to itself multiplied by",
		"operation": "*"
	},
	{
		"text": "to itself divided by",
		"operation": "/"
	},
]

## node references
onready var picker_menu = $MenuButton

# used to connect the signals
func _ready():
	picker_menu.get_popup().connect("index_pressed", self, '_on_PickerMenu_selected')
	picker_menu.connect("about_to_show", self, "_on_PickerMenu_about_to_show")
	picker_menu.custom_icon = get_icon("GDScript", "EditorIcons")

# called by the event block
func load_data(data:Dictionary):
	# First set the event_data
	.load_data(data)
	
	# Now update the ui nodes to display the data. 
	select_operation()
	
# has to return the wanted preview, only useful for body parts
func get_preview():
	return ''

func select_operation():
	for o in options:
		if (o['operation'] == event_data['operation']):
			picker_menu.text = o['text']


func _on_PickerMenu_selected(index):
	event_data['operation'] = picker_menu.get_popup().get_item_metadata(index).get('operation')
	
	select_operation()
	
	# informs the parent about the changes!
	data_changed()

func _on_PickerMenu_about_to_show():
	picker_menu.get_popup().clear()
	
	var index = 0
	for o in options:
		picker_menu.get_popup().add_item(o['text'])
		picker_menu.get_popup().set_item_metadata(index, o)
		index += 1
