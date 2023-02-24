@tool
class_name DialogicIndexer
extends RefCounted

## Script that indexes events, subsystems, settings pages and more. [br]
## Place a script of this type in every folder in "addons/Events".
## Overwrite the methods to return the contents of that folder.


var this_folder : String = get_script().resource_path.get_base_dir()

func _get_events() -> Array:
	if FileAccess.file_exists(this_folder.path_join('event.gd')):
		return [this_folder.path_join('event.gd')]
	return []


## Should return an array of dictionaries with the following keys: [br]
## "name"		-> name for this subsystem[br]
## "script"-> array of preview images[br]
func _get_subsystems() -> Array[Dictionary]:
	return []


func _get_editors() -> Array[String]:
	return []


func _get_settings_pages() -> Array:
	return []


func _get_character_editor_tabs() -> Array:
	return []



## Should return an array of dictionaries with the following keys:[br]
## "path" 		-> the path to the scene[br]
## "name"		-> name for this layout[br]
## "description"-> description of this layout. list what features/events are supported[br]
## "preview_image"-> array of preview images[br]
func _get_layout_scenes() -> Array[Dictionary]:
	return []


## Should return array of dictionaries with the following keys:[br]
## "command" 	-> the text e.g. "speed"[br]
## "node_path" or "subsystem" -> whichever contains your effect method[br]
## "method" 	-> name of the effect method[br]
func _get_text_effects() -> Array[Dictionary]:
	return []


## Should return array of dictionaries with the same arguments as _get_text_effects()
func _get_text_modifiers() -> Array[Dictionary]:
	return []
