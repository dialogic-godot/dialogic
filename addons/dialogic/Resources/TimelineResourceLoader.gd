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
#	print('[Dialogic] Reimporting timeline "' , path, '"')
	if FileAccess.file_exists(path):
		var file := FileAccess.open(path, FileAccess.READ)
		var res := DialogicTimeline.new()
		var text : String = file.get_as_text()
		
		# Parse the lines as seperate events and insert them in an array, so they can be converted to DialogicEvent's when processed later
		var prev_indent := ""
		var events := []
		
		var lines := text.split('\n', true)
		var idx := -1
		
		while idx < len(lines)-1:
			idx += 1
			var line :String = lines[idx]
			var line_stripped :String = line.strip_edges(true, true)
			events.append(line)
		
		res.events = events
		res.events_processed = false
		return res
