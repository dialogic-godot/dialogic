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
	$VBoxContainer/Header/CharacterDropdown.get_popup().connect("index_pressed", self, '_on_character_selected')
	update_preview()

func _on_MenuButton_about_to_show():
	var Dropdown = $VBoxContainer/Header/CharacterDropdown
	Dropdown.get_popup().clear()
	var index = 0
	for c in editor_reference.get_character_list():
		Dropdown.get_popup().add_item(c['name'])
		if c.has('color'):
			Dropdown.get_popup().set_item_metadata(index, {'file': c['file'],'color': c['color']})
		else:
			Dropdown.get_popup().set_item_metadata(index, {'file': c['file'], 'color': Color('#ffffff')})
		index += 1

func _on_character_selected(index):
	var text = $VBoxContainer/Header/CharacterDropdown.get_popup().get_item_text(index)
	var metadata = $VBoxContainer/Header/CharacterDropdown.get_popup().get_item_metadata(index)
	var color = metadata['color']
	$VBoxContainer/Header/CharacterDropdown.text = text
	event_data['character'] = metadata['file']
	update_preview()

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
	update_preview()

func update_preview():
	if editor_reference:
		for c in editor_reference.get_character_list():
			if c['file'] == event_data['character']:
				$VBoxContainer/Header/CharacterDropdown.text = c['name']
				$VBoxContainer/Header/TextureRect.set("self_modulate", c['color'])
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
