extends Label

class_name DialogicDisplay_NameLabel

export (bool) var hide_when_empty = true

export (bool) var use_character_color = true

func _ready():
	add_to_group('dialogic_name_label')
	text = ""
	
func _set(property, what):
	if property == 'text' and typeof(what) == TYPE_STRING:
		text = what
		if hide_when_empty:
			visible = bool(what)
		return true
