@tool
class_name DialogicResourceUtil

static var directories := {}
static var label_cache := {}
static var event_cache: Array[DialogicEvent] = []


static func _static_init() -> void:
	if Engine.is_editor_hint():
		if not Engine.get_main_loop().root.is_node_ready():
			await Engine.get_main_loop().root.ready
		update()

		DialogicUtil.get_dialogic_plugin().get_editor_interface().get_filesystem_dock().files_moved.connect(_on_files_moved)


static func update() -> void:
	update_directory('.dch')
	update_directory('.dtl')
	update_label_cache()


#region RESOURCE DIRECTORIES
################################################################################

static func get_directory(extension:String) -> Dictionary:
	extension = extension.trim_prefix('.')
	if directories.has(extension+'_directory'):
		return directories.get(extension+'_directory', {})

	var directory := ProjectSettings.get_setting("dialogic/directories/"+extension+'_directory', {})
	directories[extension+'_directory'] = directory
	return directory


static func set_directory(extension:String, directory:Dictionary) -> void:
	extension = extension.trim_prefix('.')
	ProjectSettings.set_setting("dialogic/directories/"+extension+'_directory', directory)
	directories[extension+'_directory'] = directory


static func update_directory(extension:String) -> void:
	var directory := get_directory(extension)

	for resource in list_resources_of_type(extension):
		if not resource in directory.values():
			directory = add_resource_to_directory(resource, directory)

	set_directory(extension, directory)


static func add_resource_to_directory(file_path:String, directory:Dictionary) -> Dictionary:
	var suggested_name := file_path.get_file().trim_suffix("."+file_path.get_extension())
	while suggested_name in directory:
		suggested_name = file_path.trim_suffix(suggested_name+file_path.get_extension()).get_file()
	directory[suggested_name] = file_path
	return directory


static func get_unique_identifier(file_path:String) -> String:
	var identifier := get_directory(file_path.get_extension()).find_key(file_path)
	if typeof(identifier) == TYPE_STRING:
		return identifier
	return ""


static func get_resource_from_identifier(identifier:String, extension:String) -> Resource:
	var path: String = get_directory(extension).get(identifier, '')
	if ResourceLoader.exists(path):
		return load(path)
	return null


static func change_unique_identifier(file_path:String, new_identifier:String) -> void:
	var directory := get_directory(file_path.get_extension())
	var key := directory.find_key(file_path)
	while key != null:
		if key == new_identifier:
			break
		directory.erase(key)
		directory[new_identifier] = file_path
		key = directory.find_key(file_path)
	set_directory(file_path.get_extension(), directory)


static func change_resource_path(old_path:String, new_path:String):
	var directory := get_directory(new_path.get_extension())
	var key := directory.find_key(old_path)
	while key != null:
		directory[key] = new_path
		key = directory.find_key(old_path)
	set_directory(new_path.get_extension(), directory)


static func is_identifier_unused(extension:String, identifier:String) -> bool:
	return not identifier in get_directory(extension)


static func _on_files_moved(old_path:String, new_path:String) -> void:
	change_resource_path(old_path, new_path)

#endregion

#region LABEL CACHE
################################################################################
# The label cache is only for the editor so we don't have to scan all timelines
# whenever we want to suggest labels. This has no use in game and is not always perfect.

static func get_label_cache() -> Dictionary:
	if not label_cache.is_empty():
		return label_cache

	label_cache = DialogicUtil.get_editor_setting('label_ref', {})
	return label_cache


static func set_label_cache(cache:Dictionary) -> void:
	label_cache = cache


static func update_label_cache() -> void:
	var cache := get_label_cache()
	var timelines := get_timeline_directory().values()
	for timeline in cache:
		if !timeline in timelines:
			cache.erase(timeline)
	set_label_cache(cache)

#endregion

#region EVENT CACHE
################################################################################

static func get_event_cache() -> Array:
	if not event_cache.is_empty():
		return event_cache

	event_cache = update_event_cache()
	return event_cache


static func update_event_cache() -> Array:
	event_cache = []
	for indexer in DialogicUtil.get_indexers():
		# build event cache
		for event in indexer._get_events():
			if not FileAccess.file_exists(event):
				continue
			if not 'event_end_branch.gd' in event and not 'event_text.gd' in event:
				event_cache.append(load(event).new())

	# Events are checked in order while testing them. EndBranch needs to be first, Text needs to be last
	event_cache.push_front(DialogicEndBranchEvent.new())
	event_cache.push_back(DialogicTextEvent.new())

	return event_cache

#endregion

#region HELPERS
################################################################################

static func get_character_directory() -> Dictionary:
	return get_directory('dch')


static func get_timeline_directory() -> Dictionary:
	return get_directory('dtl')


static func get_timeline_resource(timeline_identifier:String) -> DialogicTimeline:
	return get_resource_from_identifier(timeline_identifier, 'dtl')


static func get_character_resource(character_identifier:String) -> DialogicCharacter:
	return get_resource_from_identifier(character_identifier, 'dch')


static func list_resources_of_type(extension:String) -> Array:
	var all_resources := scan_folder('res://', extension)
	return all_resources


static func scan_folder(path:String, extension:String) -> Array:
	var list: Array = []
	if DirAccess.dir_exists_absolute(path):
		var dir := DirAccess.open(path)
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while file_name != "":
			if dir.current_is_dir() and not file_name.begins_with("."):
				list += scan_folder(path.path_join(file_name), extension)
			else:
				if file_name.ends_with(extension):
					list.append(path.path_join(file_name))
			file_name = dir.get_next()
	return list

#endregion
