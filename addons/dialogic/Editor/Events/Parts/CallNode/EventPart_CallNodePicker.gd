tool
extends "res://addons/dialogic/Editor/Events/Parts/EventPart.gd"

# has an event_data variable that stores the current data!!!

## node references
onready var target_path_input = $Properties/TargetNodeEdit
onready var method_name_input = $Properties/CallMethodEdit
onready var argument_length = $Properties/ArgumentsSpinBox
onready var arguments_container = $Arguments

# used to connect the signals
func _ready():
	target_path_input.connect("text_changed", self, "_on_TargetPathInput_text_changed")
	method_name_input.connect("text_changed", self, "_on_MethodName_text_changed")
	argument_length.connect("value_changed", self, "_on_AgrumentLength_value_changed")

# called by the event block
func load_data(data:Dictionary):
	# First set the event_data
	.load_data(data)
	
	# Now update the ui nodes to display the data. 
	target_path_input.text = event_data['call_node']['target_node_path']
	method_name_input.text = event_data['call_node']['method_name']
	
	for i in range(event_data['call_node']['arguments'].size()):
		if (event_data['call_node']['arguments'][i] == null):
			event_data['call_node']['arguments'][i] = ''
	
	argument_length.value = len(event_data['call_node']['arguments'])
	
	_create_argument_controls()
	
# has to return the wanted preview, only useful for body parts
func get_preview():
	if event_data['call_node']["target_node_path"] and event_data['call_node']['method_name']:
		return 'Calls `'+event_data['call_node']['method_name']+ "` on node `"+event_data['call_node']["target_node_path"]+"` with an array with "+str(len( event_data['call_node']['arguments'])) +" items."
	else:
		return ''

func _on_TargetPathInput_text_changed(text):
	event_data['call_node']['target_node_path'] = text
	
	# informs the parent about the changes!
	data_changed()

func _on_MethodName_text_changed(text):
	event_data['call_node']['method_name'] = text
	
	# informs the parent about the changes!
	data_changed()

func _on_AgrumentLength_value_changed(value):
	event_data['call_node']['arguments'].resize(max(0, value))
	
	for i in range(event_data['call_node']['arguments'].size()):
		if (event_data['call_node']['arguments'][i] == null):
			event_data['call_node']['arguments'][i] = ''
			
	_create_argument_controls()
	
	# informs the parent about the changes!
	data_changed()

func _on_argument_value_changed(value, arg_index):
	if (arg_index < 0 or arg_index >= event_data['call_node']['arguments'].size()):
		return
		
	event_data['call_node']['arguments'][arg_index] = str(value)
	
	# informs the parent about the changes!
	data_changed()
	

# helpers
func _create_argument_controls():
	if (not event_data['call_node']['arguments'] is Array):
		return
		
	# clear old
	for c in arguments_container.get_children():
		arguments_container.remove_child(c)
		c.queue_free()
		
	# create controls
	var index = 0
	for a in event_data['call_node']['arguments']:
		var container = HBoxContainer.new()
		container.name = "Argument%s" % index
		
		var label = Label.new()
		label.name = "IndexLabel"
		label.text = "Argument %s:" % index
		label.rect_min_size.x = 100
		container.add_child(label)
		
		var edit = LineEdit.new()
		edit.name = "IndexValue"
		edit.text = str(a)
		edit.connect("text_changed", self, "_on_argument_value_changed", [ index ])
		edit.rect_min_size.x = 250
		container.add_child(edit)
		
		arguments_container.add_child(container)
		
		index += 1
