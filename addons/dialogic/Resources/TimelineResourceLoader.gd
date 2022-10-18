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
	if FileAccess.file_exists(path):
		var file := FileAccess.open(path, FileAccess.READ)
		var res = DialogicTimeline.new()
		var text = file.get_as_text()
		
		# Parse the lines as seperate events and insert them in an array, so they can be converted to DialogicEvent's when processed later
		var prev_indent := ""
		var events := []
		
		var lines := text.split('\n', true)
		var idx := -1
		
		while idx < len(lines)-1:
			idx += 1
			var line :String = lines[idx]
			var line_stripped :String = line.strip_edges(true, true)
			if line_stripped.is_empty():
				continue
			events.append(line)


		res.events = events
		res.events_processed = false
		return res


func _get_dependencies(path:String, add_type:bool):
	var depends_on : PackedStringArray
	var timeline:DialogicTimeline = load(path)
	for event in timeline.events:
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
	for event in timeline.events:
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
