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
	print('[Dialogic] Reimporting timeline "' , path, '"')
	
	var file := File.new()
	var err:int
	
	err = file.open(path, File.READ)
	if err != OK:
		push_error("For some reason, loading custom resource failed with error code: %s"%err)
		return err
		
	var res = DialogicTimeline.new()
	
	res._events = TimelineUtil.text_to_events(file.get_as_text())
	
	return res


func _get_dependencies(path:String, add_type:bool):
	var depends_on : PackedStringArray
	var timeline:DialogicTimeline = load(path)
	for event in timeline._events:
		for property in event.get_shortcode_parameters().values():
			if event.get(property) is DialogicTimeline:
				depends_on.append(event.get(property).resource_path)
			elif event.get(property) is DialogicCharacter:
				depends_on.append(event.get(property).resource_path)
			elif typeof(event.get(property)) == TYPE_STRING and event.get(property).begins_with('res://'):
				depends_on.append(event.get(property))
	return depends_on

func _rename_dependencies(path: String, renames: Dictionary):
	var timeline:DialogicTimeline = load(path)
	for event in timeline._events:
		for property in event.get_shortcode_parameters().values():
			if event.get(property) is DialogicTimeline:
				if event.get(property).resource_path in renames:
					event.set(property, load(renames[event.get(property).resource_path]))
			elif event.get(property) is DialogicCharacter:
				if event.get(property).resource_path in renames:
					event.set(property, load(renames[event.get(property).resource_path]))
			elif typeof(event.get(property)) == TYPE_STRING and event.get(property) in renames:
				event.set(property, renames[event.get(property)])
	ResourceSaver.save(timeline, path)
	return OK
