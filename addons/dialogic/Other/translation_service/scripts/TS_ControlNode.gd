tool
extends Control

export(String, MULTILINE) var hint_tooltip_key

func _enter_tree():
	set_meta("HINT_TOOLTIP_KEY", hint_tooltip_key)
	
	hint_tooltip = tr(hint_tooltip_key)

