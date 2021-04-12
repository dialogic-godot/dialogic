tool
extends MenuButton

var character

var allow_dont_change := true

signal portrait_selected(portrait)


func _ready():
	visible = false
	connect("about_to_show", self, '_on_about_to_show')
	get_popup().connect("index_pressed", self, '_on_portrait_selected')
	if not allow_dont_change:
		text = 'Default'


func set_character(c: String, p: String = '') -> void:
	character = c
	visible = false
	if allow_dont_change and p == "[Don't change]":
		text = ''
	else:
		text = 'Default'
		for c in DialogicUtil.get_character_list():
			if c['file'] == character and c.has('portraits') and c['portraits'].size() > 1:
				visible = true
				for port in c['portraits']:
					if port['name'] == p:
						text = p


func _on_about_to_show():
	get_popup().clear()
	var index = 0
	if allow_dont_change:
		get_popup().add_item("[Don't change]")
		index += 1
	for c in DialogicUtil.get_sorted_character_list():
		if c['file'] == character:
			for p in c['portraits']:
				get_popup().add_item(p['name'])
				index += 1


func _on_portrait_selected(index: int):
	var text = get_popup().get_item_text(index)
	if allow_dont_change:
		if text == "[Don't change]":
			text = ''
	set_character(character, text)
	emit_signal("portrait_selected", text)
