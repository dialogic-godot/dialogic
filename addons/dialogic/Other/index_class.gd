@tool
class_name DialogicIndexer
extends RefCounted

## Script that indexes events, subsystems, settings pages and more.
## Place a script of this type in every folder in "addons/Events".
## Overwrite the methods to return the contents of that folder.


var this_folder : String = get_script().resource_path.get_base_dir()

func _get_events() -> Array:
	if FileAccess.file_exists(this_folder.path_join('event.gd')):
		return [this_folder.path_join('event.gd')]
	return []


func _get_subsystems() -> Array[Dictionary]:
	return []


func _get_settings_pages() -> Array:
	return []


func _get_character_editor_tabs() -> Array:
	return []


## Should return array of dictionaries with the following keys:
## "command" 	-> the text e.g. "speed"
## "node_path" or "subsystem" -> whichever contains your effect method
## "method" 	-> name of the effect method
func _get_text_effects() -> Array[Dictionary]:
	return []


func _get_text_modifiers() -> Array:
	return []
