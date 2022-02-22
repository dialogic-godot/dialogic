tool
extends "res://addons/dialogic/Editor/Events/Parts/EventPart.gd"

# has an event_data variable that stores the current data!!!

## node references
onready var slot_picker = $MenuButton
onready var custom_slot = $CustomSlot

# used to connect the signals
func _ready():
	custom_slot.connect("text_changed", self, '_on_CustomSlot_text_changed')
	slot_picker.get_popup().connect("index_pressed", self, "on_SlotPicker_index_pressed")
	slot_picker.get_popup().clear()
	slot_picker.get_popup().add_icon_item(get_icon("Save", "EditorIcons"), "Default slot")
	slot_picker.get_popup().add_icon_item(get_icon("Tools", "EditorIcons"), "Custom slot")
	slot_picker.custom_icon = get_icon("Save", "EditorIcons")

# called by the event block
func load_data(data:Dictionary):
	# First set the event_data
	.load_data(data)
	
	# Now update the ui nodes to display the data. 
	if event_data.get('use_default_slot', true):
		slot_picker.text = "Default slot"
	else:
		slot_picker.text = "Custom slot"
	custom_slot.text = event_data.get('custom_slot', '')
	
	custom_slot.visible = not event_data.get('use_default_slot', true)

func on_SlotPicker_index_pressed(index):
	event_data['use_default_slot'] = index == 0
	
	# Now update the ui nodes to display the data. 
	if event_data.get('use_default_slot', true):
		slot_picker.text = "Default slot"
	else:
		slot_picker.text = "Custom slot"
	custom_slot.text = event_data.get('custom_slot', '')
	
	custom_slot.visible = not event_data.get('use_default_slot', true)
	
	# informs the parent about the changes!
	data_changed()


func _on_CustomSlot_text_changed(text):
	event_data['custom_slot'] = text
	
	# informs the parent about the changes!
	data_changed()
