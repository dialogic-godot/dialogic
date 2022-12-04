@tool
class_name DialogicCharacterEditorMainTab
extends Control

## Base class for all character editor main tabs. Methods should be overriden.


# Emit this, if something changed
signal changed


var character_editor:Control 


func _load_character(resource:DialogicCharacter) -> void:
	pass


func _save_changes(resource:DialogicCharacter) -> DialogicCharacter:
	return resource
