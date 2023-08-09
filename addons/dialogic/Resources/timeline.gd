@tool
extends Resource
class_name DialogicTimeline


var events:Array = []:
	get:
		return events
	set(value):
		emit_changed()
		notify_property_list_changed()
		events = value
		
var events_processed:bool = false


func get_event(index):
	if index >= len(events):
		return null
	return events[index]


func _set(property, value):
	if str(property).begins_with("event/"):
		var event_idx:int = str(property).split("/", true, 2)[1].to_int()
		if event_idx < events.size():
			events[event_idx] = value
		else:
			events.insert(event_idx, value)
		
		emit_changed()
		notify_property_list_changed()

	return false


func _get(property):
	if str(property).begins_with("event/"):
		var event_idx:int = str(property).split("/", true, 2)[1].to_int()
		if event_idx < len(events):
			return events[event_idx]
			return true


func _init() -> void:
	events = []
	resource_name = get_class()


func _to_string() -> String:
	return "[DialogicTimeline:{file}]".format({"file":resource_path})


func _get_property_list() -> Array:
	var p : Array = []
	var usage = PROPERTY_USAGE_SCRIPT_VARIABLE
	usage |= PROPERTY_USAGE_NO_EDITOR
	usage |= PROPERTY_USAGE_EDITOR # Comment this line to hide events from editor
	if events != null:
		for event_idx in events.size():
			p.append(
				{
					"name":"event/{idx}".format({"idx":event_idx}),
					"type":TYPE_OBJECT,
					"usage":PROPERTY_USAGE_DEFAULT|PROPERTY_USAGE_SCRIPT_VARIABLE
				}
			)
	return p


func from_text(text:String) -> void:
	# Parse the lines as seperate events and insert them in an array, so they can be converted to DialogicEvent's when processed later
	
	events = text.split('\n', true)
	events_processed = false


func as_text() -> String:
	var result:String = ""
	
	if events_processed:
		var indent := 0
		for idx in range(0, len(events)):
			var event = events[idx]
			
			if event['event_name'] == 'End Branch':
				indent -= 1
				continue
			
			if event != null:
				for i in event.empty_lines_above:
					result += "\t".repeat(indent)+"\n"
				result += "\t".repeat(indent)+event['event_node_as_text'].replace('\n', "\n"+"\t".repeat(indent)) + "\n"
			if event.can_contain_events:
				indent += 1
			if indent < 0: 
				indent = 0
	else:
		for event in events:
			result += str(event)+"\n"
		
		result.trim_suffix('\n')
	
	return result.strip_edges()


func process() -> void:
	if typeof(events[0]) == TYPE_STRING:
		events_processed = false
	
	# if the timeline is already processed
	if events_processed:
		for event in events:
			event.event_node_ready = true
		return
	
	var character_directory: Dictionary = Engine.get_main_loop().get_meta('dialogic_character_directory', {})
	var timeline_directory: Dictionary = Engine.get_main_loop().get_meta('dialogic_timeline_directory', {})
	var event_cache: Array[DialogicEvent] = Engine.get_main_loop().get_meta('dialogic_event_cache', [])
	
	var end_event := DialogicEndBranchEvent.new()
	
	var prev_indent := ""
	var _events := []
	
	# this is needed to add an end branch event even to empty conditions/choices
	var prev_was_opener := false
	
	var lines := events
	var idx := -1
	var empty_lines = 0
	while idx < len(lines)-1:
		idx += 1
		
		# make sure we are using the string version, in case this was already converted
		var line: String = ""
		if typeof(lines[idx]) == TYPE_STRING:
			line = lines[idx]
		else:
			line = lines[idx]['event_node_as_text']
		
		# ignore empty lines, but record them in @empty_lines
		var line_stripped :String = line.strip_edges(true, false)
		if line_stripped.is_empty():
			empty_lines += 1
			continue
		
		
		## Add an end event if the indent is smaller then previously
		var indent :String= line.substr(0,len(line)-len(line_stripped))
		if len(indent) < len(prev_indent):
			for i in range(len(prev_indent)-len(indent)):
				_events.append(end_event.duplicate())
		# Add an end event if the indent is the same but the previous was an opener
		# (so for example choice that is empty)
		elif prev_was_opener and len(indent) == len(prev_indent):
			_events.append(end_event.duplicate())
		prev_indent = indent
		
		## Now we process the event into a resource 
		## by checking on each event if it recognizes this string 
		var event_content :String = line_stripped
		var event :Variant
		for i in event_cache:
			if i._test_event_string(event_content):
				event = i.duplicate()
				break
		
		event.empty_lines_above = empty_lines
		# add the following lines until the event says it's full, there is an empty line or the indent changes
		while !event.is_string_full_event(event_content):
			idx += 1
			if idx == len(lines):
				break
			var following_line :String = lines[idx]
			var following_line_stripped :String = following_line.strip_edges(true, false)
			var following_line_indent :String = following_line.substr(0,len(following_line)-len(following_line_stripped))
			if following_line_stripped.is_empty():
				break
			if following_line_indent != indent:
				idx -= 1
				break
			event_content += "\n"+following_line_stripped
		
		if Engine.is_editor_hint():
			# Unlike at runtime, for some reason here the event scripts can't access the scene tree to get to the character directory, so we will need to pass it to it before processing
			if event['event_name'] == 'Character' || event['event_name'] == 'Text':
				event.set_meta('editor_character_directory', character_directory)

		
		event._load_from_string(event_content)
		event['event_node_as_text'] = event_content

		_events.append(event)
		prev_was_opener = event.can_contain_events
		empty_lines = 0
	
	
	if !prev_indent.is_empty():
		for i in range(len(prev_indent)):
			_events.append(end_event.duplicate())
	
	events = _events
	events_processed = true
