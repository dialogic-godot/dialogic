tool
extends Label
export var text_key : String = ""
var editor_reference

func set_text_from_key(value):
	text = editor_reference.dialogicTranslator.translate(value)

func _ready():
	editor_reference = find_parent('EditorView')
	if text_key != '':
		set_text_from_key(text_key)
