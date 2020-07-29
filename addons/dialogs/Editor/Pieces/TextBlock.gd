tool
extends PanelContainer

var text_height = 80
var editor_reference
	
func _ready():
	$VBoxContainer/TextEdit.set("rect_min_size", Vector2(0, 80))

func _on_TextEdit_text_changed():
	var text_edit_text = $VBoxContainer/TextEdit.text
	if '\n' in text_edit_text:
		text_edit_text = text_edit_text.split('\n')[0]
	$VBoxContainer/Header/Preview.text = '    ' + text_edit_text
