extends Label

class_name DialogicNode_NameLabel

@export var hide_when_empty := true

@export var use_character_color := true

func _ready():
	add_to_group('dialogic_name_label')
	text = ""
	
func _set(property, what):
	if property == 'text' and typeof(what) == TYPE_STRING:
		text = what
		if hide_when_empty:
			visible = !what.is_empty()
		return true
