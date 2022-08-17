@tool
class_name TimelineUtil

static func text_to_events(text:String) -> Array:
	# Parse the lines as seperate events and recreate them as resources
	var prev_indent := ""
	var events := []
	
	# this is needed to add a end branch event even to empty conditions/choices
	var prev_was_opener := false
	
	var lines := text.split('\n', true)
	var idx := -1
	
	while idx < len(lines)-1:
		idx += 1
		var line :String = lines[idx]
		var line_stripped :String = line.strip_edges(true, false)
		if line_stripped.is_empty():
			continue
		var indent :String= line.substr(0,len(line)-len(line_stripped))
		
		if len(indent) < len(prev_indent):
			for i in range(len(prev_indent)-len(indent)):
				events.append(DialogicEndBranchEvent.new())
		
		elif prev_was_opener and len(indent) == len(prev_indent):
			events.append(DialogicEndBranchEvent.new())
		prev_indent = indent
		var event_content :String = line_stripped
		var event :DialogicEvent = DialogicUtil.get_event_by_string(event_content).new()
		
		# add the following lines until the event says it's full there is an empty line or the indent changes
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
		
		event_content = event_content.replace("\n"+indent, "\n")
		
		# a few types have exceptions with how they're currently written
		if (event['event_name'] == "Label") || (event['event_name'] == "Choice"):
			event._load_from_string(event_content)
		else:
			#hold it for later if we're not processing it right now
			event['deferred_processing_text'] = event_content
		events.append(event)
		prev_was_opener = event.can_contain_events
	
	if !prev_indent.is_empty():
		for i in range(len(prev_indent)):
			events.append(DialogicEndBranchEvent.new())
	
	return events

static func events_to_text(events:Array) -> String:
	var result := ""
	var indent := 0

	for idx in range(0, len(events)):
		var event = events[idx]
		
		#it shouldn't be trying to save if the node's not been prepared, but if it does then it will just save default values instead so prepare it from what was there before
		if event['event_node_ready'] == false:
			event._load_from_string(event['deferred_processing_text'])
		
		if event['event_name'] == 'End Branch':
			indent -= 1
			continue
		
		if event != null:
			result += "\t".repeat(indent)+event._store_as_string().replace('\n', "\n"+"\t".repeat(indent)) + "\n"
		if event.can_contain_events:
			indent += 1
		if indent < 0: indent = 0
		result += "\t".repeat(indent)+"\n"
	
	return result
