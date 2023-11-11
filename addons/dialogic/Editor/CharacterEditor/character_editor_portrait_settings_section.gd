@tool
class_name DialogicCharacterEditorPortraitSection
extends Control

## Base class for all portrait settings sections. Methods should be overriden.
## Changes made through fields in such a section should instantly be "saved"
##  to the portrait_items metadata from where they will be saved to the resource.

## Emit this, if something changed
signal changed
## Emit this if the preview should reload
signal update_preview

## Reference to the character editor, set when instantiated
var character_editor:Control
## Reference to the selected portrait item.
##  `selected_item.get_metadata(0)` can access the portraits data
var selected_item :TreeItem = null

## If not empty a hint icon is added to the section title
var hint_text := ""


## Overwrite to set the title of this section
func _get_title() -> String:
	return "CustomSection"


## Overwrite to set the visibility of the section title
func _show_title() -> bool:
	return true


## Overwrite to set whether this should initially be opened.
func _start_opened() -> bool:
	return false


## Overwrite to load all the information from the character into this section.
func _load_portrait_data(data:Dictionary) -> void:
	pass


## Overwrite to recheck visibility of your section and the content of your fields.
## This is called whenever the preview is updated so it allows reacting to major
##  changes in other portrait sections.
func _recheck(data:Dictionary) -> void:
	pass
