tool
extends MenuButton

var character
var portrait


func _ready():
	visible = false
	connect("about_to_show", self, '_on_about_to_show')


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


func _on_about_to_show():
	get_popup().clear()
	var index = 0
	for c in DialogicUtil.get_character_list():
		if c['file'] == character:
			for p in c['portraits']:
				get_popup().add_item(p['name'])
				index += 1
