tool
extends PanelContainer

var text_height = 80
var editor_reference
var preview = '...'
onready var toggler = get_node("VBoxContainer/Header/VisibleToggle")

# This is the information of this event and it will get parsed and saved to the JSON file.
var event_data = {
	'character': '',
	'text': ''
}

func _ready():
	connect("gui_input", self, '_on_gui_input')
	$VBoxContainer/TextEdit.set("rect_min_size", Vector2(0, 80))
	print(editor_reference)
	$VBoxContainer/Header/MenuButton.get_popup().connect("index_pressed", self, '_on_character_selected')
	update_preview()

func _on_MenuButton_about_to_show():
	$VBoxContainer/Header/MenuButton.get_popup().clear()
	for c in editor_reference.get_character_list():
		$VBoxContainer/Header/MenuButton.get_popup().add_item(c)

func _on_character_selected(index):
	var text = $VBoxContainer/Header/MenuButton.get_popup().get_item_text(index)
	$VBoxContainer/Header/MenuButton.text = text
	event_data['character'] = text

func _on_TextEdit_text_changed():
	event_data['text'] = $VBoxContainer/TextEdit.text
	update_preview()

func load_text(text):
	get_node("VBoxContainer/TextEdit").text = text
	event_data['text'] = text
	update_preview()

func load_data(data):
	event_data = data
	$VBoxContainer/TextEdit.text = event_data['text']
	if event_data['character'] != '':
		$VBoxContainer/Header/MenuButton.text = event_data['character']
	update_preview()

func update_preview():
	var text = event_data['text']
	if text == '':
		return '...'
	if '\n' in text:
		text = text.split('\n')[0]
	preview = text
	if preview.length() > 60:
		preview = preview.left(60) + '...'
	
	return preview


func _on_gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == 1:
			if toggler.pressed:
				toggler.pressed = false
			else:
				toggler.pressed = true
