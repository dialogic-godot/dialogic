tool
extends MenuButton

var character
var portrait

var allow_dont_change:bool = true


func _ready():
	visible = false
	connect("about_to_show", self, '_on_about_to_show')
	if allow_dont_change == false:
		text = 'Default'


func set_character(c: String, p: String = '') -> void:
	character = c
	portrait = p
	visible = false
	for c in DialogicUtil.get_character_list():
		if c['file'] == character:
			if c.has('portraits'):
				if c['portraits'].size() > 1:
					visible = true
					for p in c['portraits']:
						if p['name'] == portrait:
							text = portrait
	if allow_dont_change:
		if p == "[Don't change]":
			text = ''


func _on_about_to_show():
	get_popup().clear()
	var index = 0
	if allow_dont_change:
		get_popup().add_item("[Don't change]")
		index += 1
	for c in DialogicUtil.get_character_list():
		if c['file'] == character:
			for p in c['portraits']:
				get_popup().add_item(p['name'])
				index += 1
