tool

const DialogicResources = preload("res://addons/dialogic/Core/DialogicResources.gd")

class _DB:
	static func get_paths() -> Array:
		var _paths = get_database().resources
		return _paths
	
	static func get_database() -> Resource:
		return Resource.new()
	
	static func add(name) -> void:
		pass


class Timelines extends _DB:
	
	static func get_database() -> Resource:
		var _db = ResourceLoader.load(
			DialogicResources.TIMELINEDB_PATH,"")
		return _db
	
	static func add(name) -> void:
		var file_name = "{name}.tres".format({"name":name})
		var file_path = "res://{file_name}".format({"file_name":file_name})
		var _n_tl = DialogicTimelineResource.new()
		_n_tl.resource_name = name

		var _err = ResourceSaver.save(
			file_path, 
			_n_tl
			)
		if _err != OK:
			print_debug("FATAL_ERROR: ", _err)
		_n_tl = load(file_path)
		get_database().add(file_path)


class Characters extends _DB:
	
	static func get_database() -> Resource:
		var _db = ResourceLoader.load(
			DialogicResources.CHARACTERDB_PATH,""
		)
		return _db


class Definitions extends _DB:
	pass

class Themes extends _DB:
	pass

static func get_editor_configuration() -> Resource:
	var _config = load(DialogicResources.CONFIGURATION_PATH)
	return _config
