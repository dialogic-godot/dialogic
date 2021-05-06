tool
extends MenuButton

var character := {}
var portrait := ""

var allow_dont_change := true

signal portrait_selected(portrait)


func _ready():
	visible = false
	connect("about_to_show", self, '_on_about_to_show')
	get_popup().connect("index_pressed", self, '_on_portrait_selected')
	if not allow_dont_change:
		_set_portrait('Default')


func set_character(c: Dictionary, p: String = '') -> void:
	character = c
	visible = character.has('portraits') and character['portraits'].size() > 1
	_set_portrait('Default')
	if allow_dont_change and (p == "[Don't change]" or p.empty()):
		_set_portrait('')
	elif visible:
		for port in character['portraits']:
			if port['name'] == p:
				_set_portrait(p)

func _set_portrait(val: String):
	if (val.empty() or val == "[Don't change]") and allow_dont_change:
		text = "[Don't change]"
		portrait = ""
	else:
		text = val
		portrait = val


func _on_about_to_show():
	get_popup().clear()
	var index = 0
	if allow_dont_change:
		get_popup().add_item("[Don't change]")
		index += 1
	if character.has('portraits'):
		for p in character['portraits']:
			get_popup().add_item(p['name'])
			index += 1


func _on_portrait_selected(index: int):
	set_character(character, get_popup().get_item_text(index))
	emit_signal("portrait_selected", portrait)
