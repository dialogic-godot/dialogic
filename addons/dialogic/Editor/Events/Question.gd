tool
extends Control

var editor_reference
var editorPopup


# This is the information of this event and it will get parsed and saved to the JSON file.
var event_data = {
	'question': '',
	'options': [],
	'character': '',
	'portrait': '',
}

onready var portrait_picker = $PanelContainer/VBoxContainer/Header/PortraitPicker

func _ready():
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

func load_data(data):
	event_data = data
	if not event_data.has('character'):
		event_data['character'] = ''
	if not event_data.has('portrait'):
		event_data['portrait'] = ''
	
	$PanelContainer/VBoxContainer/Header/LineEdit.text = event_data['question']
	update_preview()


func _on_LineEdit_text_changed(new_text):
	event_data['question'] = new_text


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


func update_preview():
	portrait_picker.set_character(event_data['character'], event_data['portrait'])
	
	for c in DialogicUtil.get_character_list():
		if c['file'] == event_data['character']:
			$PanelContainer/VBoxContainer/Header/CharacterPicker.set_data_by_file(event_data['character'])

