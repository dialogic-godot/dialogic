@tool
extends Resource
class_name DialogicTimeline

## Resource that defines a list of events.
## It can store them as text and load them from text too.

var events: Array = []
var events_processed: bool = false


## Method used for printing timeline resources identifiably
func _to_string() -> String:
	return "[DialogicTimeline:{file}]".format({"file":resource_path})


## Helper method
func get_event(index:int) -> Variant:
	if index >= len(events):
		return null
	return events[index]


## Parses the lines as seperate events and insert them in an array,
## so they can be converted to DialogicEvent's when processed later
func from_text(text:String) -> void:
	events = text.split('\n', true)
	events_processed = false


## Stores all events in their text format and returns them as a string
func as_text() -> String:
	var result: String = ""

	if events_processed:
		var indent := 0
		for idx in range(0, len(events)):
			var event: DialogicEvent = events[idx]

			if event.event_name == 'End Branch':
				indent -= 1
				continue

			if event != null:
				for i in event.empty_lines_above:
					result += "\t".repeat(indent)+"\n"
				result += "\t".repeat(indent)+event.event_node_as_text.replace('\n', "\n"+"\t".repeat(indent)) + "\n"
			if event.can_contain_events:
				indent += 1
			if indent < 0:
				indent = 0
	else:
		for event in events:
			result += str(event)+"\n"

		result.trim_suffix('\n')

	return result.strip_edges()


## Method that loads all the event resources from the strings, if it wasn't done before
func process() -> void:
	if typeof(events[0]) == TYPE_STRING:
		events_processed = false

	# if the timeline is already processed
	if events_processed:
		for event in events:
			event.event_node_ready = true
		return

	var event_cache := DialogicResourceUtil.get_event_cache()
	var end_event := DialogicEndBranchEvent.new()

	var prev_indent := ""
	var processed_events := []

	# this is needed to add an end branch event even to empty conditions/choices
	var prev_was_opener := false

	var lines := events
	var idx := -1
	var empty_lines := 0
	while idx < len(lines)-1:
		idx += 1

		# make sure we are using the string version, in case this was already converted
		var line := ""
		if typeof(lines[idx]) == TYPE_STRING:
			line = lines[idx]
		else:
			line = lines[idx].event_node_as_text

		## Ignore empty lines, but record them in @empty_lines
		var line_stripped: String = line.strip_edges(true, false)
		if line_stripped.is_empty():
			empty_lines += 1
			continue

		## Add an end event if the indent is smaller then previously
		var indent: String = line.substr(0,len(line)-len(line_stripped))
		if len(indent) < len(prev_indent):
			for i in range(len(prev_indent)-len(indent)):
				processed_events.append(end_event.duplicate())
		## Add an end event if the indent is the same but the previous was an opener
		## (so for example choice that is empty)
		if prev_was_opener and len(indent) <= len(prev_indent):
			processed_events.append(end_event.duplicate())

		prev_indent = indent

		## Now we process the event into a resource
		## by checking on each event if it recognizes this string
		var event_content: String = line_stripped
		var event: DialogicEvent
		for i in event_cache:
			if i._test_event_string(event_content):
				event = i.duplicate()
				break

		event.empty_lines_above = empty_lines
		# add the following lines until the event says it's full or there is an empty line
		while !event.is_string_full_event(event_content):
			idx += 1
			if idx == len(lines):
				break

			var following_line_stripped: String = lines[idx].strip_edges(true, false)

			if following_line_stripped.is_empty():
				break

			event_content += "\n"+following_line_stripped

		event._load_from_string(event_content)
		event.event_node_as_text = event_content

		processed_events.append(event)
		prev_was_opener = event.can_contain_events
		empty_lines = 0

	if !prev_indent.is_empty():
		for i in range(len(prev_indent)):
			processed_events.append(end_event.duplicate())

	events = processed_events
	events_processed = true


## This method makes sure that all events in a timeline are correctly reset
func clean() -> void:
	if not events_processed:
		return
	reference()
	# This is necessary because otherwise INTERNAL GODOT ONESHOT CONNECTIONS
	# are disconnected before they can disconnect themselves.
	await Engine.get_main_loop().process_frame

	for event:DialogicEvent in events:
		for con_in in event.get_incoming_connections():
			con_in.signal.disconnect(con_in.callable)

		for sig in event.get_signal_list():
			for con_out in event.get_signal_connection_list(sig.name):
				con_out.signal.disconnect(con_out.callable)
	unreference()
