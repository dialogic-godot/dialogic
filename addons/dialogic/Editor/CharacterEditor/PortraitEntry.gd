tool
extends HBoxContainer

var editor_reference
var image_node

func _ready():
	pass


func _process(_delta):
	pass


func _on_ButtonDelete_pressed():
	queue_free()


func _on_ButtonSelect_pressed():
	editor_reference.godot_dialog("*.png, *.jpg, *.jpeg, *.tga, *.svg, *.svgz, *.bmp, *.webp;Image")
	editor_reference.godot_dialog_connect(self, "_on_file_selected")


func _on_file_selected(path, target):
	image_node.texture = load(path)
	$PathEdit.text = path
	if $NameEdit.text == '':
		$NameEdit.text = editor_reference.get_filename_from_path(path)


func _on_focus_entered():
	if $PathEdit.text != '':
		image_node.texture = load($PathEdit.text)
