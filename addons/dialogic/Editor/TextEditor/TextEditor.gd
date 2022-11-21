@tool
extends CodeEdit

var current_timeline: DialogicTimeline

var editor_reference = null

@onready var _toolbar = get_parent().get_parent().get_node('Toolbar')

func _ready():
	DialogicUtil.get_dialogic_plugin().dialogic_save.connect(save_timeline)
	if find_parent('EditorView'): # This prevents the view to turn black if you are editing this scene in Godot
		editor_reference = find_parent('EditorView')
	add_highlighting()

func _on_text_editor_text_changed():
	_toolbar.set_resource_unsaved()
	current_timeline.set_meta("timeline_not_saved", true)


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


func _exit_tree():
	# Explicitly free any open cache resources on close, so we don't get leaked resource errors on shutdown
	current_timeline = null

func clear_timeline():
	text = ''
	DialogicTimeline.new()


func load_timeline(object:DialogicTimeline) -> void:
	if _toolbar.is_current_unsaved():
		save_timeline()
	clear_timeline()
	current_timeline = object
	if current_timeline.events.size() == 0:
		pass
	else: 
		if typeof(current_timeline.events[0]) == TYPE_STRING:
			current_timeline.events_processed = false
			current_timeline = editor_reference.process_timeline(current_timeline)
	
	get_parent().get_parent().get_node('Toolbar').load_timeline(current_timeline.resource_path)
	
	#text = TimelineUtil.events_to_text(object.events)
	var result:String = ""	
	var indent := 0
	for idx in range(0, len(object.events)):
		var event = object.events[idx]
		
		if event['event_name'] == 'End Branch':
			indent -= 1
			continue
		
		if event != null:
			result += "\t".repeat(indent) + event['event_node_as_text'].replace('\n', "\n" + "\t".repeat(indent)) + "\n"
		if event.can_contain_events:
			indent += 1
		if indent < 0: 
			indent = 0
		
	text = result
	current_timeline.set_meta("timeline_not_saved", false)


func save_timeline():
	
	if !visible:
		return
	
	if _toolbar.is_current_unsaved():
		
		if current_timeline:
			# The translations need this to be actual Events, so we do a few steps of conversion here
			
			var text_array:Array = text_timeline_to_array(text)
			current_timeline.events = text_array
			
			# Build new processed timeline for the ResourceSaver to use
			# ResourceSaver needs a DialogicEvents timeline so the translation builder can run
			current_timeline.events_processed = false
			editor_reference.process_timeline(current_timeline)
			current_timeline.events_processed = false		
			ResourceSaver.save(current_timeline, current_timeline.resource_path)
			
			#Switch back to the text event array, in case we're switching editor modes
			current_timeline.events = text_array
			current_timeline.set_meta("timeline_not_saved", false)
			_toolbar.set_resource_saved()
			editor_reference.rebuild_timeline_directory()
		


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


func new_timeline() -> void:
	save_timeline()
	clear_timeline()
	show_save_dialog()


func show_save_dialog():
	find_parent('EditorView').godot_file_dialog(
		create_and_save_new_timeline,
		'*.dtl; DialogicTimeline',
		EditorFileDialog.FILE_MODE_SAVE_FILE,
		"Save new Timeline",
		"New_Timeline",
		true
	)

func create_and_save_new_timeline(path):
	var new_timeline = DialogicTimeline.new()
	new_timeline.resource_path = path
	current_timeline = new_timeline
	save_timeline()
	DialogicUtil.get_dialogic_plugin().editor_interface.get_resource_filesystem().update_file(path)
	load_timeline(new_timeline)

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
