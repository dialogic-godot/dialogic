@tool
extends ResourceFormatLoader

class_name DialogicTransitionFormatLoader

# returns all excepted extenstions
func _get_recognized_extensions() -> PackedStringArray:
	return PackedStringArray(["dtr"])


# Returns "Resource" if this file can/should be loaded by this script
func _get_resource_type(path: String) -> String:
	var ext = path.get_extension().to_lower()
	if ext == "dtr":
		return "Resource"
	
	return ""


# Return true if this type is handled
func _handles_type(typename: StringName) -> bool:
	return ClassDB.is_parent_class(typename, "Resource")


# parse the file and return a resource
func _load(path: String, original_path: String, use_sub_threads: bool, cache_mode: int):
	if ResourceLoader.exists(path):
		var file = FileAccess.open(path, FileAccess.READ)
		return dict_to_inst(str_to_var(file.get_as_text()))
	else:
		push_error("File does not exists")
		return false
