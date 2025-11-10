@tool
class_name DialogicIndexer
extends RefCounted

## Script that indexes events, subsystems, settings pages and more. [br]
## Place a script of this type in every folder in "addons/Events". [br]
## Overwrite the methods to return the contents of that folder.


var this_folder: String = get_script().resource_path.get_base_dir()

## Overwrite if this module contains any events. [br]
## Return an array with all the paths to the event scripts.[br]
## You can use the [property this_folder].path_join('my_event.gd')
func _get_events() -> Array:
	if ResourceLoader.exists(this_folder.path_join('event.gd')):
		return [this_folder.path_join('event.gd')]
	return []


## Overwrite if this module contains any subsystems.
## Should return an array of dictionaries each with the following keys: [br]
## "name" 		-> name for this subsystem[br]
## "script" 	-> array of preview images[br]
func _get_subsystems() -> Array[Dictionary]:
	return []


func _get_editors() -> Array[String]:
	return []


func _get_settings_pages() -> Array:
	return []


func _get_character_editor_sections() -> Array:
	return []


#region TEXT EFFECTS & MODIFIERS

## Should return array of dictionaries with the following keys:[br]
## "command" 	-> the text e.g. "speed"[br]
## "node_path" or "subsystem" -> whichever contains your effect method[br]
## "method" 	-> name of the effect method[br]
func _get_text_effects() -> Array[Dictionary]:
	return []


## Should return array of dictionaries with the same arguments as _get_text_effects()
func _get_text_modifiers() -> Array[Dictionary]:
	return []

#endregion


## Return a list of resources, scripts, etc.
## These can later be retrieved with DialogicResourceUtil.
## Each dictionary should contain (at least "type" and "path").
## 		E.g. {"type":"Animation", "path": "res://..."}
func _get_special_resources() -> Dictionary:
	return {}


## Return a list of dictionaries, each
func _get_portrait_scene_presets() -> Array[Dictionary]:
	return []


#region HELPERS
################################################################################

func list_dir(subdir:='') -> Array:
	return Array(DirAccess.get_files_at(this_folder.path_join(subdir))).map(func(file):return this_folder.path_join(subdir).path_join(file))


func list_special_resources(subdir:='', extension:="") -> Dictionary:
	var dict := {}
	for i in list_dir(subdir):
		if extension.is_empty() or i.ends_with(extension) or (extension == ".gd" and i.ends_with(".gdc")):
			dict[DialogicUtil.pretty_name(i).to_lower()] = {"path":i}
	return dict


func list_animations(subdir := "") -> Dictionary:
	var full_animation_list := {}
	for path in list_dir(subdir):
		if not path.ends_with(".gd") and not path.ends_with(".gdc"):
			continue
		var anim_object: DialogicAnimation = load(path).new()
		var versions := anim_object._get_named_variations()
		for version_name in versions:
			full_animation_list[version_name] = versions[version_name]
			full_animation_list[version_name]["path"] = path
		anim_object.queue_free()
	return full_animation_list

#endregion


#region STYLES & LAYOUTS
################################################################################

func _get_style_presets() -> Array[Dictionary]:
	return []


## Should return an array of dictionaries with the following keys:[br]
## "path" 		-> the path to the scene[br]
## "name"		-> name for this layout[br]
## "description"-> description of this layout. list what features/events are supported[br]
## "preview_image"-> array of preview images[br]
func _get_layout_parts() -> Array[Dictionary]:
	return []


## Helper that allows scanning sub directories that might be layout parts or styles
func scan_for_layout_parts() -> Array[Dictionary]:
	var dir := DirAccess.open(this_folder)
	var style_list: Array[Dictionary] = []
	if !dir:
		return style_list
	dir.list_dir_begin()
	var dir_name := dir.get_next()
	while dir_name != "":
		if !dir.current_is_dir() or !dir.file_exists(dir_name.path_join('part_config.cfg')):
			dir_name = dir.get_next()
			continue
		var config := ConfigFile.new()
		config.load(this_folder.path_join(dir_name).path_join('part_config.cfg'))
		var default_image_path: String = this_folder.path_join(dir_name).path_join('preview.png')
		style_list.append(
			{
				'type': config.get_value('style', 'type', 'Unknown type'),
				'name': config.get_value('style', 'name', 'Unnamed Layout'),
				'path': this_folder.path_join(dir_name).path_join(config.get_value('style', 'scene', '')),
				'author': config.get_value('style', 'author', 'Anonymous'),
				'description': config.get_value('style', 'description', 'No description'),
				'preview_image': [config.get_value('style', 'image', default_image_path)],
				'style_path':config.get_value('style', 'style_path', ''),
				'icon':this_folder.path_join(dir_name).path_join(config.get_value('style', 'icon', '')),
			})

		if not style_list[-1].style_path.begins_with('res://'):
			style_list[-1].style_path = this_folder.path_join(dir_name).path_join(style_list[-1].style_path)

		dir_name = dir.get_next()

	return style_list

#endregion
