@tool
class_name DialogicTimelineFormatLoader
extends ResourceFormatLoader


## Returns all excepted extenstions
func _get_recognized_extensions() -> PackedStringArray:
	return PackedStringArray(["dtl"])


## Returns "Resource" if this file can/should be loaded by this script
func _get_resource_type(path: String) -> String:
	var ext := path.get_extension().to_lower()
	if ext == "dtl":
		return "Resource"

	return ""


## Returns the script class associated with a Resource
func _get_resource_script_class(path: String) -> String:
	var ext := path.get_extension().to_lower()
	if ext == "dtl":
		return "DialogicTimeline"

	return ""


## Return true if this type is handled
func _handles_type(typename: StringName) -> bool:
	return ClassDB.is_parent_class(typename, "Resource")


## Parse the file and return a resource
func _load(path: String, _original_path: String, _use_sub_threads: bool, _cache_mode: int) -> Variant:
	var file := FileAccess.open(path, FileAccess.READ)

	if not file:
		# For now, just let editor know that for some reason you can't
		# read the file.
		print("[Dialogic] Error opening file:", FileAccess.get_open_error())
		return FileAccess.get_open_error()

	var tml := DialogicTimeline.new()
	tml.from_text(file.get_as_text())
	return tml


func _get_dependencies(path: String, _add_types: bool) -> PackedStringArray:
	var deps := PackedStringArray()

	var tml: DialogicTimeline = load(path)
	tml.process()

	for ev in tml.events:
		deps += ev.get_dependencies()

	var clean_deps := PackedStringArray()

	for i in deps:
		var clean := i
		if clean.begins_with("res://"):
			clean = ResourceUID.id_to_text(ResourceLoader.get_resource_uid(clean))
		if not clean.is_empty() and not clean in clean_deps:
			clean_deps.append(clean)

	return clean_deps
