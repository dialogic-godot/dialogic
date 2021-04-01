tool
extends "res://addons/dialogic/Other/translation_service/scripts/TS_ControlNode.gd"

# This can be used on buttons too, text and hint_tooltip
# property can be used from both nodes without problem

export(String, MULTILINE) var text_key

func _enter_tree():
	set_meta("TEXT_KEY", text_key)
	# Since i can't be sure if this is going to be the default
	# behaviour, i'll lead the translation to Godot if
	# everything fails
	self.text = tr(get_meta("TEXT_KEY"))
