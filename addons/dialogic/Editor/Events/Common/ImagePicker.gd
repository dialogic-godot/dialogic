tool
extends HBoxContainer

var editor_reference

signal clear_pressed()
signal file_selected()

onready var name_label = $Name
onready var clear_button = $ClearButton


func set_image(src: String):
	clear_button.disabled = false
	name_label.text = src;


func clear_image():
	clear_button.disabled = true
	name_label.text = 'No image (will clear previous scene event)'


func _on_file_selected(path, target):
	emit_signal("file_selected", path)


func _on_ImageButton_pressed():
	editor_reference.godot_dialog("*.png, *.jpg, *.jpeg, *.tga, *.svg, *.svgz, *.bmp, *.webp, *.tscn")
	editor_reference.godot_dialog_connect(self, "_on_file_selected")


func _on_ClearButton_pressed():
	clear_image()
	emit_signal("clear_pressed")
