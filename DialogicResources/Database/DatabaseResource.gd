extends Resource
class_name DialogicDatabaseResource

export(PoolStringArray) var resources = PoolStringArray() setget _set_resources, _get_resources

func _init() -> void:
	pass

func save(path: String) -> void:
	var _err = ResourceSaver.save(path, self)
	if _err != OK:
		print_debug("FATAL_ERROR: ", _err)
	pass

func _set_resources(value:PoolStringArray):
	if value.empty():
		return
	resources = value
	emit_signal("changed")
	

func _get_resources():
	return resources

func add(path: String):
	var _old_resources:PoolStringArray = resources
	_old_resources.append(path)
	self.resources = _old_resources
	save(path)
