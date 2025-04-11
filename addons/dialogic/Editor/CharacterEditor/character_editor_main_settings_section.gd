@tool
class_name DialogicCharacterEditorMainSection
extends Control

## Base class for all character editor main sections. Methods should be overriden.

## Emit this, if something changed
@warning_ignore("unused_signal") # this is used by extending scripts
signal changed

## Reference to the character editor, set when instantiated
var character_editor: Control

## If not empty, a hint icon is added to the section title.
var hint_text := ""


## Overwrite to set the title of this section
func _get_title() -> String:
	return "MainSection"


## Overwrite to set the visibility of the section title
func _show_title() -> bool:
	return true


## Overwrite to set whether this should initially be opened.
func _start_opened() -> bool:
	return false


## Overwrite to load all the information from the character into this section.
func _load_character(_resource:DialogicCharacter) -> void:
	pass


## Overwrite to save all changes made in this section to the resource.
## In custom sections you will mostly likely save to the [resource.custom_info]
##  dictionary.
func _save_changes(resource:DialogicCharacter) -> DialogicCharacter:
	return resource
