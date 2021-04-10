tool
class_name DialogicDatabaseResource
extends Resource

# BUGS:
# - If you delete the database resource from editor, plugin still holds the resource cache
# - Running the editor can create timelines but can't save this file

const DialogicResources = preload("res://addons/dialogic/Core/DialogicResources.gd")

export(Resource) var resources = ResourceArray.new() setget _set_resources


func add(path):
	assert(false)


func save(path: String) -> void:
	var _err = ResourceSaver.save(path, self)
	if _err != OK:
		print_debug("FATAL_ERROR: ", _err)


func _to_string() -> String:
	return "[DatabaseResource]"

func _set_resources(value):
	if not value:
		resources = ResourceArray.new()
		return
	resources = value
	emit_signal("changed")
	save(self.resource_path)
