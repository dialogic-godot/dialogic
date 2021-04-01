tool
extends Control

var editor_reference
var editorPopup


# This is the information of this event and it will get parsed and saved to the JSON file.
var event_data = {
	'call_node': {
		'target_node_path': '',
		'method_name': '',
		'arguments': []
	}
}


func load_data(data):
	event_data = data
	
	if (not event_data['call_node']['arguments'] is Array):
		event_data['call_node']['arguments'] = []
	
	for i in range(event_data['call_node']['arguments'].size()):
		if (event_data['call_node']['arguments'][i] == null):
			event_data['call_node']['arguments'][i] = ''
	
	$PanelContainer/VBoxContainer/Properties/TargetNodeEdit.text = event_data['call_node']['target_node_path']
	$PanelContainer/VBoxContainer/Properties/CallMethodEdit.text = event_data['call_node']['method_name']
	$PanelContainer/VBoxContainer/Properties/ArgumentsSpinBox.value = event_data['call_node']['arguments'].size()
	
	_create_argument_controls()


# signal callbacks

func _on_Target_LineEdit_text_changed(new_text):
	event_data['call_node']['target_node_path'] = new_text
	
func _on_Method_LineEdit_text_changed(new_text):
	event_data['call_node']['method_name'] = new_text

func _on_ArgumentsSpinBox_value_changed(value):
	event_data['call_node']['arguments'].resize(max(0, value))
	
	for i in range(event_data['call_node']['arguments'].size()):
		if (event_data['call_node']['arguments'][i] == null):
			event_data['call_node']['arguments'][i] = ''
			
	_create_argument_controls()
	pass
	
func _on_argument_value_changed(value, arg_index):
	if (arg_index < 0 or arg_index >= event_data['call_node']['arguments'].size()):
		return
		
	event_data['call_node']['arguments'][arg_index] = str(value)
	pass
	
# helpers
func _create_argument_controls():
	if (not event_data['call_node']['arguments'] is Array):
		return
		
	# clear old
	for c in $PanelContainer/VBoxContainer/Arguments.get_children():
		$PanelContainer/VBoxContainer/Arguments.remove_child(c)
		c.queue_free()
		
	# create controls
	var index = 0
	for a in event_data['call_node']['arguments']:
		var container = HBoxContainer.new()
		container.name = "Argument%s" % index
		
		var label = Label.new()
		label.name = "ArgumentLabel"
		label.text = "Argument %s:" % index
		label.rect_min_size.x = 100
		container.add_child(label)
		
		var edit = LineEdit.new()
		edit.name = "ArgumentValue"
		edit.text = str(a)
		edit.connect("text_changed", self, "_on_argument_value_changed", [ index ])
		edit.rect_min_size.x = 250
		container.add_child(edit)
		
		$PanelContainer/VBoxContainer/Arguments.add_child(container)
		
		index += 1
		
	pass
