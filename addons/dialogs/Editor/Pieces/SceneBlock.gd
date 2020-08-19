tool
extends PanelContainer

var editor_reference
var editorPopup
var preview = "..."
	
func _ready():
	#$FileDialog.resizable = true
	pass

func _on_ImageButton_pressed():
	var file_dialog = editor_reference.godot_dialog()
	file_dialog.add_filter("*.png, *.jpg, *.jpeg, *.tga, *.svg, *.svgz, *.bmp, *.webp;Image")
	file_dialog.connect("file_selected", self, "_on_file_selected")

func _on_file_selected(path):
	print('here')
	load_image(path)

func load_image(img_src):
	if img_src != '':
		$VBoxContainer/HBoxContainer/LineEdit.text = img_src
		$VBoxContainer/TextureRect.texture = load(img_src)
		$VBoxContainer/TextureRect.rect_min_size = Vector2(200,200)
		preview = img_src
	else:
		$VBoxContainer/TextureRect.rect_min_size = Vector2(0,0)
