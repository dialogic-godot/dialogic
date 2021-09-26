tool
extends Label
export var text_key : String = ""

func set_text_from_key(value):
	text = DTS.translate(value)

func _ready():
	if text_key != '':
		set_text_from_key(text_key)
