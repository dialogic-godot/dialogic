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


func load_data(data):
	event_data = data
	load_image(event_data['background'])


func load_image(img_src: String):
	event_data['background'] = img_src
	if not img_src.empty() and not img_src.ends_with('.tscn'):
		$PanelContainer/VBoxContainer/Header/Name.text = img_src
		$PanelContainer/VBoxContainer/TextureRect.texture = load(img_src)
		$PanelContainer/VBoxContainer/TextureRect.rect_min_size = Vector2(200,200)
		$PanelContainer/VBoxContainer/Header/ClearButton.disabled = false
		preview = "..."
		toggler.show()
		toggler.set_visible(true)
	else:
		$PanelContainer/VBoxContainer/Header/Name.text = 'No image (will clear previous scene event)'
		$PanelContainer/VBoxContainer/TextureRect.rect_min_size = Vector2(0,0)
		$PanelContainer/VBoxContainer/Header/ClearButton.disabled = true
		preview = ""
		toggler.hide()
		toggler.set_visible(false)


func _on_gui_input(event):
	if event is InputEventMouseButton and event.is_pressed() and event.doubleclick and event.button_index == 1 and toggler.visible:
		toggler.set_visible(not toggler.pressed)


func _on_ImageButton_pressed():
	editor_reference.godot_dialog("*.png, *.jpg, *.jpeg, *.tga, *.svg, *.svgz, *.bmp, *.webp, *.tscn")
	editor_reference.godot_dialog_connect(self, "_on_file_selected")


func _on_file_selected(path, target):
	target.load_image(path)


func _on_ClearButton_pressed():
	load_image('')
