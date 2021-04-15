tool
extends Control

var editor_reference
var preview = "..."

var preview_scene = preload("res://addons/dialogic/Editor/Events/Common/ImagePreview.tscn")

onready var event_template = $EventTemplate

var image_picker

# This is the information of this event and it will get parsed and saved to the JSON file.
var event_data = {
	'background': ''
}

func _ready():
	image_picker = event_template.get_header()
	# Needed to open the file dialog
	image_picker.editor_reference = editor_reference
	image_picker.connect("file_selected", self, "_on_file_selected")
	image_picker.connect("clear_pressed", self, "_on_clear_pressed")


func load_data(data):
	event_data = data
	load_image(event_data['background'])


func load_image(img_src: String):
	event_data['background'] = img_src
	if not img_src.empty() and not img_src.ends_with('.tscn'):
		event_template.set_preview("...")
		event_template.set_body(preview_scene)
		event_template.get_body().set_image(load(img_src))
		image_picker.set_image(img_src)
	elif img_src.ends_with('.tscn'):
		event_template.set_preview("...")
		image_picker.set_image(img_src)
		event_template.set_body(null)
	else:
		event_template.set_body(null)
		image_picker.clear_image()


func _on_file_selected(path):
	load_image(path)


func _on_clear_pressed():
	load_image('')
