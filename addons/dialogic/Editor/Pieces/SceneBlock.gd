tool
extends Control

var editor_reference
var editorPopup
var preview = "..."
onready var toggler = get_node("PanelContainer/VBoxContainer/Header/VisibleToggle")

# This is the information of this event and it will get parsed and saved to the JSON file.
var event_data = {
	'background': ''
}


func _ready():
	connect("gui_input", self, '_on_gui_input')
	load_image(event_data['background'])


func _on_ImageButton_pressed():
	editor_reference.godot_dialog("*.png, *.jpg, *.jpeg, *.tga, *.svg, *.svgz, *.bmp, *.webp;Image")
	editor_reference.godot_dialog_connect(self, "_on_file_selected")


func _on_file_selected(path, target):
	target.load_image(path)


func load_data(data):
	event_data = data
	load_image(event_data['background'])


func load_image(img_src):
	event_data['background'] = img_src
	if event_data['background'] != '':
		$PanelContainer/VBoxContainer/HBoxContainer/LineEdit.text = event_data['background']
		$PanelContainer/VBoxContainer/TextureRect.texture = load(event_data['background'])
		$PanelContainer/VBoxContainer/TextureRect.rect_min_size = Vector2(200,200)
		preview = event_data['background']
	else:
		$PanelContainer/VBoxContainer/TextureRect.rect_min_size = Vector2(0,0)


func _on_gui_input(event):
	if event is InputEventMouseButton and event.is_pressed() and event.doubleclick:
		if event.button_index == 1:
			if toggler.pressed:
				toggler.pressed = false
			else:
				toggler.pressed = true
