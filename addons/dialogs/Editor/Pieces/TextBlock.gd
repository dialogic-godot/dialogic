tool
extends PanelContainer

var text_height = 80
var editor_reference
var preview = '...'
	
func _ready():
	$VBoxContainer/TextEdit.set("rect_min_size", Vector2(0, 80))

func _on_TextEdit_text_changed():
	update_preview()

func set_character_position():
	pass

func load_text(text):
	get_node("VBoxContainer/TextEdit").text = text
	update_preview()

func update_preview():
	var text_edit_text = $VBoxContainer/TextEdit.text
	if '\n' in text_edit_text:
		text_edit_text = text_edit_text.split('\n')[0]
	preview = text_edit_text
	return preview
