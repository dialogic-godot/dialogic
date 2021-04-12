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

onready var character_picker = $PanelContainer/VBoxContainer/Header/CharacterAndPortraitPicker

func _ready():
	character_picker.connect("character_changed", self, '_on_character_changed')

	var c_list = DialogicUtil.get_sorted_character_list()
	if c_list.size() == 0:
		character_picker.visible = false
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
	character_picker.set_data(event_data['character'], event_data['portrait'])


func _on_LineEdit_text_changed(new_text):
	event_data['question'] = new_text


func _on_character_changed(character_data: Dictionary, portrait: String) -> void:
	if character_data.keys().size() > 0:
		event_data['character'] = character_data['file']
		event_data['portrait'] = portrait
	else:
		event_data['character'] = ''
		event_data['portrait'] = ''
