@tool
class_name DialogicCharacterEditorPortraitSection
extends Control

## Base class for all portrait settings tabs. Methods should be overriden.

# Emit this, if something changed
signal changed
signal update_preview

var character_editor:Control 
var hint_text := ""
var selected_item :TreeItem = null

func _get_title() -> String:
	return "CustomSection"

func _show_title() -> bool:
	return true

func _start_opened() -> bool:
	return false

func _load_portrait_data(data:Dictionary) -> void:
	pass

func _recheck(data:Dictionary) -> void:
	pass 
