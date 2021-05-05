tool
extends HBoxContainer

onready var character_picker = $CharacterPicker
onready var portrait_picker = $PortraitPicker
onready var definition_picker = $DefinitionPicker

signal character_changed(character, portrait, port_defn)

var allow_portrait_dont_change := true
var allow_portrait_definition := true

var character := {}
var portrait: String
var port_defn: String


func _ready():
	character_picker.connect('character_selected', self , '_on_character_selected')
	portrait_picker.connect("portrait_selected", self, '_on_portrait_selected')
	definition_picker.connect("definition_selected", self, "_on_definition_selected")


func set_allow_portrait_dont_change(dont_allow: bool):
	allow_portrait_dont_change = dont_allow
	portrait_picker.allow_dont_change = dont_allow


func set_allow_portrait_definition(defintion_allow: bool):
	allow_portrait_definition = defintion_allow
	portrait_picker.allow_definition = defintion_allow


func set_data(c: String, p: String, d: String):
	character = {}
	for ch in DialogicUtil.get_character_list():
		if ch['file'] == c:
			character = ch
	
	if character.has('name') and character.has('color'):
		character_picker.set_data(character['name'], Color(character['color']))
		portrait_picker.set_character(character, p)
		
		if d:
			portrait_picker.set_character(character, '[Definition]')
			definition_picker.load_definition(d)
			definition_picker.visible = true
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
	emit_signal("character_changed", character, portrait, port_defn)


func _on_portrait_selected(p: String):
	portrait = p
	definition_picker.visible = portrait_picker.is_definition_selected
	emit_signal("character_changed", character, portrait, port_defn)


func _on_definition_selected(id: String):
	emit_signal("character_changed", character, portrait, id)

func get_selected_character() -> Dictionary:
	return character
