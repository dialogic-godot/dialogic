tool
extends HBoxContainer

onready var character_picker = $CharacterPicker
onready var portrait_picker = $PortraitPicker

signal character_changed(character_data, portrait)

var allow_portrait_dont_change := true

var character_data: Dictionary
var portrait: String


func _ready():
	character_picker.connect('character_selected', self , '_on_character_selected')
	portrait_picker.connect("portrait_selected", self, '_on_portrait_selected')


func set_allow_portrait_dont_change(dont_allow: bool):
	allow_portrait_dont_change = dont_allow
	portrait_picker.allow_dont_change = dont_allow


func set_data(char_data: Dictionary, p: String):
	character_picker.set_data(char_data['name'], Color(char_data['color']))
	portrait_picker.set_character(char_data['file'], p)


func _on_character_selected(char_data):
	character_data = char_data
	if allow_portrait_dont_change or character_data['file'].empty():
		portrait = ''
	else:
		portrait = 'Default'
	portrait_picker.set_character(character_data['file'])
	emit_signal("character_changed", character_data, portrait)


func _on_portrait_selected(p: String):
	portrait = p
	emit_signal("character_changed", character_data, portrait)
