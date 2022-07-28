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
	
	var res = DialogicTimeline.new()
	
	err = file.open(path, File.READ)
	if err != OK:
		push_error("For some reason, loading custom resource failed with error code: %s"%err)
		return err
	
	# Parse the lines as seperate events and recreate them as resources
	var prev_indent = ""
	var events = []
	
	# this is needed to add a end branch event even to empty conditions/choices
	var prev_was_opener = false
	
	for line in file.get_as_text().split("\n", false):
		var stripped_line = line.strip_edges(true, false)
		
		if stripped_line.is_empty():
			continue
		
		var indent = line.substr(0,len(line)-len(stripped_line))
		if len(indent) < len(prev_indent):
			for i in range(len(prev_indent)-len(indent)):
				events.append(DialogicEndBranchEvent.new())
		elif prev_was_opener and len(indent) == len(prev_indent):
			events.append(DialogicEndBranchEvent.new())
			
		prev_indent = indent
		
		line = stripped_line
		var event = DialogicUtil.get_event_by_string(line).new()
		event._load_from_string(line)
		events.append(event)
		
		prev_was_opener = (event is DialogicChoiceEvent or event is DialogicConditionEvent)

	
	if !prev_indent.is_empty():
		for i in range(len(prev_indent)):
			events.append(DialogicEndBranchEvent.new())
	
	
	res._events = events
	
	return res
