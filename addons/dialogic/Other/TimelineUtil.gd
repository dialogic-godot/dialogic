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
				events.append("<<END BRANCH>>")
		
		elif prev_was_opener and len(indent) == len(prev_indent):
			events.append("<<END BRANCH>>")
		prev_indent = indent
		var event_content :String = line_stripped

		events.append(event_content)	

	if !prev_indent.is_empty():
		for i in range(len(prev_indent)):
			events.append("<<END BRANCH>>")
		
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
