tool
extends "res://addons/dialogic/Editor/Events/Parts/EventPart.gd"

# has an event_data variable that stores the current data!!!

## node references
onready var picker_menu = $MenuButton

# used to connect the signals
func _ready():
	picker_menu.connect("about_to_show", self, "_on_PickerMenu_about_to_show")
	picker_menu.get_popup().connect("index_pressed", self, '_on_PickerMenu_selected')
	find_parent("TimelineEditor").connect("timeline_loaded", self, "update")
	picker_menu.custom_icon = load("res://addons/dialogic/Images/Event Icons/label.svg")

# called by the event block
func load_data(data:Dictionary):
	# First set the event_data
	.load_data(data)
	
	# Now update the ui nodes to display the data. 
	update()

func update():
	if event_data['anchor_id'] == "":
		picker_menu.text = "Select label"
	else:
		var anchors = find_parent('TimelineEditor').get_current_events_anchors()
		if event_data['anchor_id'] in anchors.keys():
			picker_menu.text = anchors[event_data['anchor_id']]
		else:
			picker_menu.text = "Label not found"

# has to return the wanted preview, only useful for body parts
func get_preview():
	return ''


func _on_PickerMenu_about_to_show():
	picker_menu.get_popup().clear()
	
	var anchors = find_parent('TimelineEditor').get_current_events_anchors()
	var index = 0
	for id in anchors.keys():
		picker_menu.get_popup().add_item(anchors[id])
		picker_menu.get_popup().set_item_metadata(index, {'id':id})
		index += 1
	
func _on_PickerMenu_selected(index):
	var text = picker_menu.get_popup().get_item_text(index)
	var metadata = picker_menu.get_popup().get_item_metadata(index)
	
	picker_menu.text = text
	
	event_data['anchor_id'] = metadata['id']
	
	data_changed()
