tool
extends HBoxContainer

var editor_reference
var image_node

func _ready():
	pass


func _process(_delta):
	pass


func _on_ButtonDelete_pressed():
	if $NameEdit.text == 'Default':
		$PathEdit.text = ''
		update_preview('')
	else:
		queue_free()


func _on_ButtonSelect_pressed():
	editor_reference.godot_dialog("*.png, *.svg")
	editor_reference.godot_dialog_connect(self, "_on_file_selected")


func _on_file_selected(path, target):
	update_preview(path)
	$PathEdit.text = path
	if $NameEdit.text == '':
		$NameEdit.text = DialogicUtil.get_filename_from_path(path)


func _on_focus_entered():
	if $PathEdit.text != '':
		update_preview($PathEdit.text)


func update_preview(path):
	if path == '':
		image_node.texture = null
	else:
		if '.png' in path or '.svg' in path:
			image_node.texture = load(path)
			return true
	return false
