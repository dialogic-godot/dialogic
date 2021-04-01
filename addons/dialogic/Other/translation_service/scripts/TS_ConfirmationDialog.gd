tool
extends "res://addons/dialogic/Other/translation_service/scripts/TS_ControlNode.gd"

export(String, MULTILINE) var dialog_text_key

func _enter_tree():
	set_meta("DIALOG_TEXT_KEY", dialog_text_key)
	
	self.dialog_text = tr(dialog_text_key)
