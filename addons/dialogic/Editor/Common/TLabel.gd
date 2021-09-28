tool
extends Label
export var text_key : String = ""

func set_text_from_key(value):
	text = DTS.translate(value)

func _ready():
	set_text_from_key(text_key)
