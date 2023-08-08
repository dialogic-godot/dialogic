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


func _get_character_editor_sections() -> Array:
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


## Should return array of animation scripts.
func _get_portrait_animations() -> Array:
	return []


func list_dir(subdir:='') -> Array:
	return Array(DirAccess.get_files_at(this_folder.path_join(subdir))).map(func(file):return this_folder.path_join(subdir).path_join(file))


## Helper that allows scanning sub directories that might be styles
func scan_for_layouts() -> Array[Dictionary]:
	var dir := DirAccess.open(this_folder)
	var style_list :Array[Dictionary] = []
	if !dir:
		return style_list
	dir.list_dir_begin()
	var dir_name := dir.get_next()
	while dir_name != "":
		if !dir.current_is_dir() or !dir.file_exists(dir_name.path_join('style.cfg')):
			dir_name = dir.get_next()
			continue
		var config := ConfigFile.new()
		var config_path: String = this_folder.path_join(dir_name).path_join('style.cfg')
		var default_image_path: String = this_folder.path_join(dir_name).path_join('preview.png')
		config.load(config_path)
		style_list.append(
			{
				'name': config.get_value('style', 'name', 'Unnamed Layout'),
				'path': this_folder.path_join(dir_name).path_join(config.get_value('style', 'scene')),
				'author': config.get_value('style', 'author', 'Anonymous'),
				'description': config.get_value('style', 'description', 'No description'),
				'preview_image': [config.get_value('style', 'image', default_image_path)]
			})
		dir_name = dir.get_next()
	
	return style_list
