tool
extends HBoxContainer

onready var character_picker = $CharacterPicker
onready var portrait_picker = $PortraitPicker

signal character_changed(character, portrait)

var allow_portrait_dont_change := true

var character := {}
var portrait: String


func _ready():
	character_picker.connect('character_selected', self , '_on_character_selected')
	portrait_picker.connect("portrait_selected", self, '_on_portrait_selected')


func set_allow_portrait_dont_change(dont_allow: bool):
	allow_portrait_dont_change = dont_allow
	portrait_picker.allow_dont_change = dont_allow


func set_data(c: String, p: String):
	character = {}
	for ch in DialogicUtil.get_character_list():
		if ch['file'] == c:
			character = ch
	
	if character.has('name') and character.has('color'):
		character_picker.set_data(character['name'], Color(character['color']))
		portrait_picker.set_character(character, p)
	else:
		character_picker.set_data('',  Color('#FFFFFF'))
		portrait_picker.set_character({}, '')
		


func _on_character_selected(data: Dictionary):
	character = data
	if allow_portrait_dont_change or character.keys().size() == 0:
		portrait = ''
	else:
		portrait = 'Default'
	portrait_picker.set_character(character)
	emit_signal("character_changed", character, portrait)


func _on_portrait_selected(p: String):
	portrait = p
	emit_signal("character_changed", character, portrait)


func get_selected_character() -> Dictionary:
	return character
