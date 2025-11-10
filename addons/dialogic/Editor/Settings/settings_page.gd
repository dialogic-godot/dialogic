@tool
extends Control
class_name DialogicSettingsPage

@export_multiline var short_info := ""
@onready var settings_editor: Control = find_parent('Settings')

## Called to get the title of the page
func _get_title() -> String:
	return name


## Called to get the ordering of the page
func _get_priority() -> int:
	return 0


## Called to know whether to put this in the features section
func _is_feature_tab() -> bool:
	return false


## Called when the settings editor is opened
func _refresh() -> void:
	pass


## Called before the settings editor closes (another editor is opened)
## Can be used to safe stuff
func _about_to_close() -> void:
	pass


## Return a section with information.
func _get_info_section() -> Control:
	return null
