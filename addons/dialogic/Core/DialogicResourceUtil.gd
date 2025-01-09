@tool
class_name DialogicResourceUtil

static var label_cache := {}
static var event_cache: Array[DialogicEvent] = []

static var special_resources := {}


static func update() -> void:
	update_directory('.dch')
	update_directory('.dtl')
	update_label_cache()


#region RESOURCE DIRECTORIES
################################################################################

static func get_directory(extension:String) -> Dictionary:
	extension = extension.trim_prefix('.')
	if Engine.has_meta(extension+'_directory'):
		return Engine.get_meta(extension+'_directory', {})

	var directory: Dictionary = ProjectSettings.get_setting("dialogic/directories/"+extension+'_directory', {})
	Engine.set_meta(extension+'_directory', directory)
	return directory


static func set_directory(extension:String, directory:Dictionary) -> void:
	extension = extension.trim_prefix('.')
	if Engine.is_editor_hint():
		ProjectSettings.set_setting("dialogic/directories/"+extension+'_directory', directory)
		ProjectSettings.save()
	Engine.set_meta(extension+'_directory', directory)


static func update_directory(extension:String) -> void:
	var directory := get_directory(extension)

	for resource in list_resources_of_type(extension):
		if not resource in directory.values():
			directory = add_resource_to_directory(resource, directory)

	var keys_to_remove := []
	for key in directory:
		if not ResourceLoader.exists(directory[key]):
			keys_to_remove.append(key)
	for key in keys_to_remove:
		directory.erase(key)

	set_directory(extension, directory)


static func add_resource_to_directory(file_path:String, directory:Dictionary) -> Dictionary:
	var suggested_name := file_path.get_file().trim_suffix("."+file_path.get_extension())
	while suggested_name in directory:
		suggested_name = file_path.trim_suffix("/"+suggested_name+"."+file_path.get_extension()).get_file().path_join(suggested_name)
	directory[suggested_name] = file_path
	return directory


## Returns the unique identifier for the given resource path.
## Returns an empty string if no identifier was found.
static func get_unique_identifier(file_path:String) -> String:
	if not file_path: return ""
	var identifier: Variant = get_directory(file_path.get_extension()).find_key(file_path)
	if typeof(identifier) == TYPE_STRING:
		return identifier
	return ""


## Returns the resource associated with the given unique identifier.
## The expected extension is needed to use the right directory.
static func get_resource_from_identifier(identifier:String, extension:String) -> Resource:
	var path: String = get_directory(extension).get(identifier, '')
	if ResourceLoader.exists(path):
		return load(path)
	return null


static func change_unique_identifier(file_path:String, new_identifier:String) -> void:
	var directory := get_directory(file_path.get_extension())
	var key: String = directory.find_key(file_path)
	while key != null:
		if key == new_identifier:
			break
		directory.erase(key)
		directory[new_identifier] = file_path
		key = directory.find_key(file_path)
	set_directory(file_path.get_extension(), directory)


static func change_resource_path(old_path:String, new_path:String) -> void:
	var directory := get_directory(new_path.get_extension())
	var key: String = directory.find_key(old_path)
	while key != null:
		directory[key] = new_path
		key = directory.find_key(old_path)
	set_directory(new_path.get_extension(), directory)


static func remove_resource(file_path:String) -> void:
	var directory := get_directory(file_path.get_extension())
	var key: String = directory.find_key(file_path)
	while key != null:
		directory.erase(key)
		key = directory.find_key(file_path)
	set_directory(file_path.get_extension(), directory)


static func is_identifier_unused(extension:String, identifier:String) -> bool:
	return not identifier in get_directory(extension)

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

##  Dialogic keeps a list that has each event once. This allows retrieval of that list.
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
			if not ResourceLoader.exists(event):
				continue
			if not 'event_end_branch.gd' in event and not 'event_text.gd' in event:
				event_cache.append(load(event).new())

	# Events are checked in order while testing them. EndBranch needs to be first, Text needs to be last
	event_cache.push_front(DialogicEndBranchEvent.new())
	event_cache.push_back(DialogicTextEvent.new())

	return event_cache

#endregion

#region SPECIAL RESOURCES
################################################################################

static func update_special_resources() -> void:
	special_resources.clear()
	for indexer in DialogicUtil.get_indexers():
		var additions := indexer._get_special_resources()
		for resource_type in additions:
			if not resource_type in special_resources:
				special_resources[resource_type] = {}
			special_resources[resource_type].merge(additions[resource_type])


static func list_special_resources(type:String, filter := {}) -> Dictionary:
	if special_resources.is_empty():
		update_special_resources()
	if type in special_resources:
		if filter.is_empty():
			return special_resources[type]
		else:
			var results := {}
			for i in special_resources[type]:
				if match_resource_filter(special_resources[type][i], filter):
					results[i] = special_resources[type][i]
			return results
	return {}


static func match_resource_filter(dict:Dictionary, filter:Dictionary) -> bool:
	for i in filter:
		if not i in dict:
			return false
		if typeof(filter[i]) == TYPE_ARRAY:
			if not dict[i] in filter[i]:
				return false
		else:
			if not dict[i] == filter[i]:
				return false
	return true


static func guess_special_resource(type: String, string: String, default := {}, filter := {}, ignores:PackedStringArray=[]) -> Dictionary:
	if string.is_empty():
		return default

	if special_resources.is_empty():
		update_special_resources()
	var resources := list_special_resources(type, filter)
	if resources.is_empty():
		printerr("[Dialogic] No ", type, "s found, but attempted to use one.")
		return default

	if string.begins_with('res://'):
		for i in resources.values():
			if i.path == string:
				return i
		printerr("[Dialogic] Unable to find ", type, " at path '", string, "'.")
		return default

	string = string.to_lower()

	if string in resources:
		return resources[string]

	if not ignores.is_empty():
		var regex := RegEx.create_from_string(r" ?\b(" + "|".join(ignores) + r")\b")
		for name in resources:
			if regex.sub(name, "") == regex.sub(string, ""):
				return resources[name]

	## As a last effort check against the unfiltered list
	if string in special_resources[type]:
		push_warning("[Dialogic] Using ", type, " '", string,"' when not supposed to.")
		return special_resources[type][string]

	printerr("[Dialogic] Unable to identify ", type, " based on string '", string, "'.")
	return default

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
	if DirAccess.dir_exists_absolute(path) and not FileAccess.file_exists(path + "/" + ".gdignore"):
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
