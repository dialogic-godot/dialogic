tool
extends Label
export var text_key : String = ""

export (String, "Normal", "Title", "Info") var  mode : String ="Normal"

func set_text_from_key(value):
	text = DTS.translate(value)

func _ready():
	if DTS.translate(text_key) != text_key:
		set_text_from_key(text_key)
	remove_color_override('font_color')
	if find_parent('EditorView'):
		if mode == "Title":
			var x = StyleBoxFlat.new()
			x.bg_color = Color(0.545098, 0.545098, 0.545098, 0.211765)
			x.content_margin_bottom = 5
			x.content_margin_top = 5
			x.content_margin_left = 5
			x.content_margin_right = 5
			add_stylebox_override("normal", x)
