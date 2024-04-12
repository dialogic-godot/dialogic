@tool
extends ResourceFormatLoader

# Needed by godot
class_name DialogicTimelineFormatLoader


# returns all excepted extenstions
func _get_recognized_extensions() -> PackedStringArray:
	return PackedStringArray(["dtl"])


# Returns "Rrsource" if this file can/should be loaded by this script
func _get_resource_type(path: String) -> String:
	var ext = path.get_extension().to_lower()
	if ext == "dtl":
		return "Resource"

	return ""


# Return true if this type is handled
func _handles_type(typename: StringName) -> bool:
	return ClassDB.is_parent_class(typename, "Resource")


# parse the file and return a resource
func _load(path: String, original_path: String, use_sub_threads: bool, cache_mode: int):
	if ResourceLoader.exists(path):
		var file := FileAccess.open(path, FileAccess.READ)

		var tml := DialogicTimeline.new()
		tml.from_text(file.get_as_text())

		return tml
