tool
extends Control

var editor_reference
var editorPopup

var event_data = {
	'change_scene': ''
}

func _ready():	
	$PanelContainer/VBoxContainer/Header/VisibleToggle.disabled()


func _on_ButtonScenePicker_pressed():
	editor_reference.godot_dialog("*.tscn")
	editor_reference.godot_dialog_connect(self, "_on_file_selected")


func _on_file_selected(path, target):
	target.select_scene(path)


func select_scene(path):
	$PanelContainer/VBoxContainer/Header/Name.text = path
	event_data['change_scene'] = path


func load_data(data):
	event_data = data
	if data['change_scene'] != '':
		select_scene(data['change_scene'])
