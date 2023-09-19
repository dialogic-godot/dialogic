@tool
class_name DialogicCharacterEditorMainSection
extends Control

## Base class for all character editor main tabs. Methods should be overriden.

# Emit this, if something changed
signal changed

var character_editor:Control 
var hint_text := ""

func _get_title() -> String:
	return "MainSection"

func _show_title() -> bool:
	return true

func _start_opened() -> bool:
	return false


func _load_character(resource:DialogicCharacter) -> void:
	pass


func _save_changes(resource:DialogicCharacter) -> DialogicCharacter:
	return resource
