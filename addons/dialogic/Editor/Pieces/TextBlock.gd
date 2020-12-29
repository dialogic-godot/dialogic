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
	$PanelContainer/VBoxContainer/Header/CharacterDropdown.get_popup().connect("index_pressed", self, '_on_character_selected')
	$PanelContainer/VBoxContainer/Header/PortraitDropdown.get_popup().connect("index_pressed", self, '_on_portrait_selected')
	# Default Speaker
	for c in DialogicUtil.get_character_list():
		if c['default_speaker']:
			event_data['character'] = c['file']
	update_preview()


func _on_MenuButton_about_to_show():
	var Dropdown = $PanelContainer/VBoxContainer/Header/CharacterDropdown
	Dropdown.get_popup().clear()
	var index = 0
	for c in DialogicUtil.get_character_list():
		Dropdown.get_popup().add_item(c['name'])
		if c.has('color'):
			Dropdown.get_popup().set_item_metadata(index, {'file': c['file'],'color': c['color']})
		else:
			Dropdown.get_popup().set_item_metadata(index, {'file': c['file'], 'color': Color('#ffffff')})
		index += 1


func _on_character_selected(index):
	var text = $PanelContainer/VBoxContainer/Header/CharacterDropdown.get_popup().get_item_text(index)
	var metadata = $PanelContainer/VBoxContainer/Header/CharacterDropdown.get_popup().get_item_metadata(index)
	var color = metadata['color']
	$PanelContainer/VBoxContainer/Header/CharacterDropdown.text = text
	event_data['character'] = metadata['file']
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
			$PanelContainer/VBoxContainer/Header/CharacterDropdown.text = c['name']
			$PanelContainer/VBoxContainer/Header/TextureRect.set("self_modulate", c['color'])
			if c.has('portraits'):
				if c['portraits'].size() > 1:
					$PanelContainer/VBoxContainer/Header/PortraitDropdown.visible = true
					for p in c['portraits']:
						if p['name'] == event_data['portrait']:
							$PanelContainer/VBoxContainer/Header/PortraitDropdown.text = event_data['portrait']
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
