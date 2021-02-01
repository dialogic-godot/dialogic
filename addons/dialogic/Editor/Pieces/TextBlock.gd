tool
extends Control

var text_height = 80
var editor_reference
var preview = '...'
onready var toggler = get_node("PanelContainer/VBoxContainer/Header/VisibleToggle")

# This is the information of this event and it will get parsed and saved to the JSON file.
var event_data = {
	'character': '',
	'text': '',
	'portrait': '',
}


func _ready():
	connect("gui_input", self, '_on_gui_input')
	$PanelContainer/VBoxContainer/TextEdit.set("rect_min_size", Vector2(0, 80))
	$PanelContainer/VBoxContainer/Header/CharacterPicker.connect('character_selected', self , '_on_character_selected')
	$PanelContainer/VBoxContainer/Header/PortraitDropdown.get_popup().connect("index_pressed", self, '_on_portrait_selected')

	var c_list = DialogicUtil.get_character_list()
	if c_list.size() == 0:
		$PanelContainer/VBoxContainer/Header/CharacterDropdown.visible = false
		$PanelContainer/VBoxContainer/Header/CharacterIcon.visible = false
	else:
		# Default Speaker
		for c in c_list:
			if c['default_speaker']:
				event_data['character'] = c['file']
	update_preview()


func _on_character_selected(data):
	event_data['character'] = data['file']
	update_preview()


func _on_PortraitDropdown_about_to_show():
	var Dropdown = $PanelContainer/VBoxContainer/Header/PortraitDropdown
	Dropdown.get_popup().clear()
	var index = 0
	for c in DialogicUtil.get_character_list():
		if c['file'] == event_data['character']:
			for p in c['portraits']:
				Dropdown.get_popup().add_item(p['name'])
				index += 1

func _on_portrait_selected(index):
	var text = $PanelContainer/VBoxContainer/Header/PortraitDropdown.get_popup().get_item_text(index)
	$PanelContainer/VBoxContainer/Header/CharacterDropdown.text = text
	event_data['portrait'] = text
	update_preview()

func check_portraits():
	pass


func _on_TextEdit_text_changed():
	event_data['text'] = $PanelContainer/VBoxContainer/TextEdit.text
	update_preview()


func load_text(text):
	get_node("VBoxContainer/TextEdit").text = text
	event_data['text'] = text
	update_preview()


func load_data(data):
	event_data = data
	$PanelContainer/VBoxContainer/TextEdit.text = event_data['text']
	update_preview()


func update_preview():
	$PanelContainer/VBoxContainer/Header/PortraitDropdown.visible = false
	for c in DialogicUtil.get_character_list():
		if c['file'] == event_data['character']:
			$PanelContainer/VBoxContainer/Header/CharacterPicker.set_data_by_file(event_data['character'])
			if c.has('portraits'):
				if c['portraits'].size() > 1:
					$PanelContainer/VBoxContainer/Header/PortraitDropdown.visible = true
					for p in c['portraits']:
						if p['name'] == event_data['portrait']:
							$PanelContainer/VBoxContainer/Header/PortraitDropdown.text = event_data['portrait']

	editor_reference.manual_save()
	
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
	if event is InputEventMouseButton and event.is_pressed() and event.doubleclick:
		if event.button_index == 1:
			if toggler.pressed:
				toggler.pressed = false
			else:
				toggler.pressed = true
