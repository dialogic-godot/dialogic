tool
extends Control

var editor_reference
var editorPopup

onready var definition_picker = $PanelContainer/VBoxContainer/Header/Condition/DefinitionPicker
onready var condition_picker = $PanelContainer/VBoxContainer/Header/Condition/ConditionPicker
onready var condition_line_edit = $PanelContainer/VBoxContainer/Header/Condition/CustomLineEdit2
onready var condition_checkbox = $PanelContainer/VBoxContainer/Header/ConditionCheckBox


# This is the information of this event and it will get parsed and saved to the JSON file.
var event_data = {
	'choice': '',
	'condition': '',
	'definition': '',
	'value': ''
}


func _ready():
	$PanelContainer/VBoxContainer/Header/Warning.visible = false
	$PanelContainer/VBoxContainer/Header/CustomLineEdit.connect('text_changed', self, '_on_LineEdit_text_changed')
	definition_picker.get_popup().connect("index_pressed", self, '_on_definition_entry_selected')
	condition_picker.get_popup().connect("index_pressed", self, '_on_condition_entry_selected')


func load_data(data):
	event_data = data
	$PanelContainer/VBoxContainer/Header/CustomLineEdit.text = event_data['choice']
	if event_data.has('condition') and event_data.has('definition') and event_data.has('value'):
		condition_checkbox.pressed = not event_data['condition'].empty() and not event_data['definition'].empty() and not event_data['value'].empty()
	else:
		_reset_conditions()
		condition_checkbox.pressed = false
	_load_condition_data(event_data)

func _on_LineEdit_text_changed(new_text):
	event_data['choice'] = new_text


func _on_Indent_visibility_changed():
	$PanelContainer/VBoxContainer/Header/Warning.visible = !$Indent.visible


func _load_condition_data(event_data):
	condition_line_edit.text = event_data['value']
	definition_picker.load_definition(event_data['definition'])
	condition_picker.load_condition(event_data['condition'])


func _reset_conditions():
	event_data['condition'] = ''
	event_data['definition'] = ''
	event_data['value'] = ''


func _on_ConditionCheckBox_toggled(button_pressed):
	$PanelContainer/VBoxContainer/Header/Condition.visible = button_pressed
	if not button_pressed:
		_reset_conditions()
		_load_condition_data(event_data)
	elif event_data['condition'].empty():
		event_data['condition'] = '=='
		_load_condition_data(event_data)


func _on_CustomLineEdit2_text_changed(new_text):
	event_data['value'] = new_text


func _on_definition_entry_selected(index):
	var metadata = definition_picker.get_popup().get_item_metadata(index)
	event_data['definition'] = metadata['id']


func _on_condition_entry_selected(index):
	var metadata = condition_picker.get_popup().get_item_metadata(index)
	event_data['condition'] = metadata['condition']
