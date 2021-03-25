tool
extends Control

var text_height = 26
var editor_reference
var preview = ''
onready var toggler = get_node("PanelContainer/VBoxContainer/Header/VisibleToggle")

# This is the information of this event and it will get parsed and saved to the JSON file.
var event_data = {
	'character': '',
	'text': '',
	'portrait': '',
}

onready var portrait_picker = $PanelContainer/VBoxContainer/Header/PortraitPicker

func _ready():
	connect("gui_input", self, '_on_gui_input')
	$PanelContainer/VBoxContainer/TextEdit.set("rect_min_size", Vector2(0, 80))
	$PanelContainer/VBoxContainer/Header/CharacterPicker.connect('character_selected', self , '_on_character_selected')
	portrait_picker.get_popup().connect("index_pressed", self, '_on_portrait_selected')

	var c_list = DialogicUtil.get_sorted_character_list()
	if c_list.size() == 0:
		$PanelContainer/VBoxContainer/Header/CharacterPicker.visible = false
	else:
		# Default Speaker
		for c in c_list:
			if c['default_speaker']:
				event_data['character'] = c['file']


func _on_character_selected(data):
	event_data['character'] = data['file']
	update_preview()


func _on_portrait_selected(index):
	var text = portrait_picker.get_popup().get_item_text(index)
	if text == "[Don't change]":
		text = ''
		portrait_picker.text = ''
	event_data['portrait'] = text
	update_preview()


func _on_TextEdit_text_changed():
	var text = $PanelContainer/VBoxContainer/TextEdit.text
	event_data['text'] = text
	update_preview()


func load_text(text):
	get_node("VBoxContainer/TextEdit").text = text
	event_data['text'] = text
	update_preview()


func load_data(data):
	event_data = data
	$PanelContainer/VBoxContainer/TextEdit.text = event_data['text']
	update_preview()


func update_preview() -> String:
	portrait_picker.set_character(event_data['character'], event_data['portrait'])
	var t = $PanelContainer/VBoxContainer/TextEdit.text
	$PanelContainer/VBoxContainer/TextEdit.rect_min_size.y = text_height * (2 + t.count('\n'))

	for c in DialogicUtil.get_character_list():
		if c['file'] == event_data['character']:
			$PanelContainer/VBoxContainer/Header/CharacterPicker.set_data_by_file(event_data['character'])
	
	var text = event_data['text']
	var lines = text.count('\n')
	if text == '':
		return ''
	if '\n' in text:
		text = text.split('\n')[0]
	preview = text
	if preview.length() > 60:
		preview = preview.left(60) + '...'
	
	if lines > 0:
		preview += '  -  ' + str(lines + 1) + ' lines'
	return preview


func _on_gui_input(event):
	if event is InputEventMouseButton and event.is_pressed() and event.doubleclick:
		if event.button_index == 1:
			if toggler.pressed:
				toggler.pressed = false
			else:
				toggler.pressed = true


func _on_saver_timer_timeout():
	update_preview()
