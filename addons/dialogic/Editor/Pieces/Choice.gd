tool
extends Control

var editor_reference
var editorPopup


# This is the information of this event and it will get parsed and saved to the JSON file.
var event_data = {
	'choice': ''
}


func _ready():
	$PanelContainer/VBoxContainer/Header/Warning.visible = false
	$PanelContainer/VBoxContainer/Header/CustomLineEdit.connect('text_changed', self, '_on_LineEdit_text_changed')
	pass


func load_data(data):
	event_data = data
	$PanelContainer/VBoxContainer/Header/CustomLineEdit.text = event_data['choice']


func _on_LineEdit_text_changed(new_text):
	event_data['choice'] = new_text


func _on_Indent_visibility_changed():
	$PanelContainer/VBoxContainer/Header/Warning.visible = !$Indent.visible
