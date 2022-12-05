@tool
extends CodeEdit

## Sub-Editor that allows editing timelines in a text format.

 
func _ready():
	DialogicUtil.get_dialogic_plugin().dialogic_save.connect(save_timeline)
	add_highlighting()


func _on_text_editor_text_changed():
	get_parent().current_resource_state = DialogicEditor.ResourceStates.Unsaved


func _gui_input(event):
	if not event is InputEventKey: return
	if not event.is_pressed(): return
	match event.as_text():
		"Ctrl+K":
			toggle_comment()
		"Alt+Up":
			move_line(-1)
		"Alt+Down":
			move_line(1)
		_:
			return
	get_viewport().set_input_as_handled()
	

func clear_timeline():
	text = ''


func load_timeline(object:DialogicTimeline) -> void:
	clear_timeline()
	if get_parent().current_resource.events.size() == 0:
		pass
	else: 
		if typeof(get_parent().current_resource.events[0]) == TYPE_STRING:
			get_parent().current_resource.events_processed = false
			get_parent().current_resource = get_parent().editors_manager.resource_helper.process_timeline(get_parent().current_resource)
	
	
	#text = TimelineUtil.events_to_text(object.events)
	var result:String = ""	
	var indent := 0
	for idx in range(0, len(object.events)):
		var event = object.events[idx]
		
		if event['event_name'] == 'End Branch':
			indent -= 1
			continue
		
		if event != null:
			result += "\t".repeat(indent)+event['event_node_as_text'].replace('\n', "\n"+"\t".repeat(indent)) + "\n"
		if event.can_contain_events:
			indent += 1
		if indent < 0: 
			indent = 0
		
	text = result
	get_parent().current_resource.set_meta("timeline_not_saved", false)


func save_timeline():
	if get_parent().current_resource:
			# The translations need this to be actual Events, so we do a few steps of conversion here
			
			var text_array:Array = text_timeline_to_array(text)
			get_parent().current_resource.events = text_array
			
			# Build new processed timeline for the ResourceSaver to use
			# ResourceSaver needs a DialogicEvents timeline so the translation builder can run
			get_parent().current_resource.events_processed = false
			get_parent().editors_manager.resource_helper.process_timeline(get_parent().current_resource)
			get_parent().current_resource.events_processed = false		
			ResourceSaver.save(get_parent().current_resource, get_parent().current_resource.resource_path)
			
			#Switch back to the text event array, in case we're switching editor modes
			get_parent().current_resource.events = text_array
			get_parent().current_resource.set_meta("timeline_not_saved", false)
			get_parent().current_resource_state = DialogicEditor.ResourceStates.Saved
			get_parent().editors_manager.resource_helper.rebuild_timeline_directory()
		


func add_highlighting():
	# This is a dumpster fire, so hopefully it will be improved during beta?
	var editor_settings = DialogicUtil.get_dialogic_plugin().editor_interface.get_editor_settings()
	var keywords_color: Color = editor_settings.get('text_editor/theme/highlighting/keyword_color')
	var functions_color: Color = editor_settings.get('text_editor/theme/highlighting/function_color')
	var strings_color: Color = editor_settings.get('text_editor/theme/highlighting/string_color')
	var numbers_color: Color = editor_settings.get("text_editor/theme/highlighting/number_color")
	var types_color: Color = editor_settings.get('text_editor/theme/highlighting/engine_type_color')
	var jumps_color: Color = editor_settings.get("text_editor/theme/highlighting/control_flow_keyword_color")
	var symbols_color: Color = editor_settings.get('text_editor/theme/highlighting/text_color')
	var text_color: Color = editor_settings.get('text_editor/theme/highlighting/text_color')
	var comments_color: Color = editor_settings.get('text_editor/theme/highlighting/comment_color')
	
	var s := CodeHighlighter.new()
	
	s.color_regions = {
		'[ ]': functions_color,
		'< >': functions_color,
		'" "': strings_color,
		'{ }': types_color
	}
	s.add_color_region('- ', '', types_color, true)
	s.add_color_region('# ', '', comments_color, true)
	s.add_color_region(': ', '', text_color, true)
	
	s.keyword_colors = {
		"if": keywords_color,
		"elif": keywords_color,
		"else": keywords_color,
		"and": keywords_color,
		"or": keywords_color
	}
	
	s.symbol_color = symbols_color
	s.number_color = numbers_color
	s.member_variable_color = text_color
	s.function_color = text_color
	set('syntax_highlighter', s)


func text_timeline_to_array(text:String) -> Array:
	# Parse the lines down into an array
	var prev_indent := ""
	var events := []
	
	# this is needed to add a end branch event even to empty conditions/choices
	var prev_was_opener := false
	
	var lines := text.split('\n', true)
	var idx := -1
	
	while idx < len(lines)-1:
		idx += 1
		var line :String = lines[idx]
		var line_stripped :String = line.strip_edges(true, true)
		if !line_stripped.is_empty():
			events.append(line)
	
	
	return events


# Toggle the selected lines as comments
func toggle_comment() -> void:
	var cursor: Vector2 = Vector2(get_caret_column(), get_caret_line())
	var from: int = cursor.y
	var to: int = cursor.y
	if has_selection():
		from = get_selection_from_line()
		to = get_selection_to_line()

	var lines: PackedStringArray = text.split("\n")
	var will_comment: bool = not lines[from].begins_with("# ")
	for i in range(from, to + 1):
		lines[i] = "# " + lines[i] if will_comment else lines[i].substr(2)

	text = "\n".join(lines)
	select(from, 0, to, get_line_width(to))
	set_caret_line(cursor.y)
	set_caret_column(cursor.x)
	text_changed.emit()


# Move the selected lines up or down
func move_line(offset: int) -> void:
	offset = clamp(offset, -1, 1)

	var cursor: Vector2 = Vector2(get_caret_column(), get_caret_line())
	var reselect: bool = false
	var from: int = cursor.y
	var to: int = cursor.y
	if has_selection():
		reselect = true
		from = get_selection_from_line()
		to = get_selection_to_line()

	var lines := text.split("\n")

	if from + offset < 0 or to + offset >= lines.size(): return

	var target_from_index: int = from - 1 if offset == -1 else to + 1
	var target_to_index: int = to if offset == -1 else from
	var line_to_move: String = lines[target_from_index]
	lines.remove_at(target_from_index)
	lines.insert(target_to_index, line_to_move)

	text = "\n".join(lines)

	cursor.y += offset
	from += offset
	to += offset
	if reselect:
		select(from, 0, to, get_line_width(to))
	set_caret_line(cursor.y)
	set_caret_column(cursor.x)
	text_changed.emit()
