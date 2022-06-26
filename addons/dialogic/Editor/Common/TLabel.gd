tool
extends Label
export var text_key : String = ""
export (bool) var  title : bool = false

func set_text_from_key(value):
	text = DTS.translate(value)

func _ready():
	if DTS.translate(text_key) != text_key:
		set_text_from_key(text_key) 
	if title:
		get_stylebox('normal').bg_color = Color(0.521569, 0.521569, 0.521569, 0.423529)
	else:
		get_stylebox('normal').bg_color = Color.transparent
