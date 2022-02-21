tool
extends HBoxContainer

var editor_reference
var image_node
var image_node2
var image_label

func _ready():
	$ButtonDelete.icon = get_icon("Remove", "EditorIcons")


func _on_ButtonDelete_pressed():
	if $NameEdit.text == 'Default':
		$PathEdit.text = ''
		update_preview('')
	else:
		queue_free()


func _on_ButtonSelect_pressed():
	editor_reference.godot_dialog("*.png, *.svg, *.tscn")
	editor_reference.godot_dialog_connect(self, "_on_file_selected")


func _on_file_selected(path, target):
	update_preview(path)
	$PathEdit.text = path
	if $NameEdit.text == '':
		$NameEdit.text = DialogicResources.get_filename_from_path(path)


func _on_focus_entered():
	if $PathEdit.text == '':
		image_label.text = DTS.translate('NoImagePreview')
		image_node.texture = null
		image_node2.texture = null
	else:
		update_preview($PathEdit.text)


func update_preview(path):
	image_label.text = DTS.translate('Preview of')+' "'+$NameEdit.text+'"'
	var l_path = path.to_lower()
	if '.png' in l_path or '.svg' in l_path:
		image_node.texture = load(path)
		image_node2.texture = load(path)
		image_label.text += ' (' + str(image_node.texture.get_width()) + 'x' + str(image_node.texture.get_height())+')'
	elif '.tscn' in l_path:
		image_node.texture = null
		image_node2.texture = null
		image_label.text = DTS.translate('CustomScenePreview')
	else:
		image_node.texture = null
		image_node2.texture = null
