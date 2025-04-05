@tool
extends Resource


func _get_extension() -> String:
	return ""


func _get_resource_name() -> String:
	return "DialogicIdentifiableResource"


func _to_string() -> String:
	return "[{name}:{id}]".format({"name":_get_resource_name(), "id":get_identifier()})


## Returns the best name for this character.
func get_identifier() -> String:
	if resource_path:
		return DialogicResourceUtil.get_unique_identifier_by_path(resource_path)
	if not Engine.is_editor_hint():
		return DialogicResourceUtil.get_runtime_unique_identifier(self, _get_extension())
	return ""


## Sets the unique identifier-string of this resource.
## In editor (if the resource is already saved) the identifier will be stored.
## In game (if the resource is not stored) the resource will be temporarily registered.
func set_identifier(new_identifier:String) -> bool:
	if resource_path and Engine.is_editor_hint():
		DialogicResourceUtil.change_unique_identifier(resource_path, new_identifier)
		return true
	if not resource_path and not Engine.is_editor_hint():
		DialogicResourceUtil.register_runtime_resource(self, new_identifier, _get_extension())
		return true
	return false
