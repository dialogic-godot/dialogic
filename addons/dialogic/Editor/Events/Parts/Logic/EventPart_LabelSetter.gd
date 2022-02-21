tool
extends "res://addons/dialogic/Editor/Events/Parts/EventPart.gd"

# has an event_data variable that stores the current data!!!

## node references
onready var input_field = $NameInput
onready var new_id = $NewIdButton

# used to connect the signals
func _ready():
	input_field.connect("text_changed", self, "_on_InputField_text_changed")
	new_id.icon = get_icon("RotateRight", "EditorIcons")
	new_id.connect("pressed", self, "new_id")

# called by the event block
func load_data(data:Dictionary):
	# First set the event_data
	.load_data(data)
	
	# Now update the ui nodes to display the data. 
	if data['id'] == null:
		new_id()
	input_field.text = event_data['name']
	
	new_id.hint_tooltip = "Change to a new unique ID. \nOnly do this if you have a duplicate id in this timeline! \nWill break existing links. \n\nCurrent ID: "+data['id']

func new_id():
	event_data['id'] = 'anchor-' + str(OS.get_unix_time())
	
	new_id.hint_tooltip = "Change to a new unique ID. \nOnly do this if you have a duplicate id in this timeline! \nWill break existing links. \n\nCurrent ID: "+event_data['id']
	data_changed()

func _on_InputField_text_changed(text):
	event_data['name'] = text
	
	# informs the parent about the changes!
	data_changed()
