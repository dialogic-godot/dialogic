tool
class_name DialogicDatabaseResource
extends Resource

# BUGS:
# - If you delete the database resource from editor, plugin still holds the resource cache
# - Running the editor can create timelines but can't save this file

const DialogicResources = preload("res://addons/dialogic/Core/DialogicResources.gd")

export(Resource) var resources = null setget _set_resources


func add(item):
	assert(false)

func remove(item):
	assert(false)

func save(path: String) -> void:
	var _err = ResourceSaver.save(path, self, ResourceSaver.FLAG_CHANGE_PATH)
	if _err != OK:
		push_error("FATAL_ERROR: "+str(_err))


func _to_string() -> String:
	return "[DatabaseResource]"

func _set_resources(value):
	if not value:
		resources = ResourceArray.new()
		return
	resources = value
	emit_signal("changed")
