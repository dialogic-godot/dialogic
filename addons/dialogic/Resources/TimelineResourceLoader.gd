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
	
	# Parse the lines as seperate events and recreate them as resources
	var prev_indent = ""
	var events = []
	
	# this is needed to add a end branch event even to empty conditions/choices
	var prev_was_opener = false
	
	var lines = file.get_as_text().split('\n', true)
	var idx = -1
	
	while idx < len(lines)-1:
		idx += 1
		var line = lines[idx]
		var line_stripped = line.strip_edges(true, false)
		if line_stripped.is_empty():
			continue
		var indent = line.substr(0,len(line)-len(line_stripped))
		
		if len(indent) < len(prev_indent):
			for i in range(len(prev_indent)-len(indent)):
				events.append(DialogicEndBranchEvent.new())
		
		elif prev_was_opener and len(indent) == len(prev_indent):
			events.append(DialogicEndBranchEvent.new())
		prev_indent = indent
		var event_content = line_stripped
		var event = DialogicUtil.get_event_by_string(event_content).new()
		
		# add the following lines until the event says it's full there is an empty line or the indent changes
		while !event.is_string_full_event(event_content):
			idx += 1
			if idx == len(lines):
				break
			var following_line = lines[idx]
			var following_line_stripped = following_line.strip_edges(true, false)
			var following_line_indent = following_line.substr(0,len(following_line)-len(following_line_stripped))
			if following_line_stripped.is_empty():
				break
			if following_line_indent != indent:
				idx -= 1
				break
			event_content += "\n"+following_line_stripped
		
		event_content = event_content.replace("\n"+indent, "\n")
		event._load_from_string(event_content)
		events.append(event)
		prev_was_opener = event.can_contain_events

	
	if !prev_indent.is_empty():
		for i in range(len(prev_indent)):
			events.append(DialogicEndBranchEvent.new())
	
	res._events = events
	
	return res
