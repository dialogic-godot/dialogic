extends Control

onready var character_picker = $HBoxContainer/CharacterPicker
onready var portrait_picker = $HBoxContainer/PortraitPicker

signal character_changed(character_data, portrait)

var data = {
	'character_data': {},
	'portrait': '',
}


func _ready():
	character_picker.connect('character_selected', self , '_on_character_selected')
	portrait_picker.get_popup().connect("index_pressed", self, '_on_portrait_selected')


func _on_character_selected(data):
	data['character_data'] = data
	data['portrait'] = ''


func _on_portrait_selected(index):
	data['portrait'] = ''
	var text = portrait_picker.get_popup().get_item_text(index)
	if portrait_picker.allow_dont_change:
		if text == "[Don't change]":
			text = ''
	event_data['portrait'] = text
	portrait_picker.set_character(event_data['character'], event_data['portrait'])
