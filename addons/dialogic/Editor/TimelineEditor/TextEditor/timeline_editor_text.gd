@tool
extends CodeEdit

## Sub-Editor that allows editing timelines in a text format.

@onready var timeline_editor := get_parent().get_parent()
@onready var code_completion_helper: Node = find_parent('EditorsManager').get_node('CodeCompletionHelper')

var label_regex := RegEx.create_from_string('label +(?<name>[^\n]+)')
var channel_regex := RegEx.create_from_string(r'audio +(?<channel>[\w-]{2,}|[\w]+)')

func _ready() -> void:
	if get_parent() is SubViewport or owner.get_parent() is SubViewport:
		return

	await find_parent('EditorView').ready
	syntax_highlighter = code_completion_helper.syntax_highlighter
	timeline_editor.editors_manager.sidebar.content_item_activated.connect(_on_content_item_clicked)

	get_menu().add_icon_item(get_theme_icon("PlayStart", "EditorIcons"), "Play from here", 42)
	get_menu().id_pressed.connect(_on_context_menu_id_pressed)

	add_comment_delimiter("#", "", true)

func _on_text_editor_text_changed() -> void:
	timeline_editor.current_resource_state = DialogicEditor.ResourceStates.UNSAVED
	request_code_completion(true)
	$UpdateTimer.start()


func clear_timeline() -> void:
	text = ''
	update_content_list()


func load_timeline(timeline:DialogicTimeline) -> void:
	clear_timeline()

	text = timeline.as_text()

	timeline_editor.current_resource.set_meta("timeline_not_saved", false)
	clear_undo_history()

	await get_tree().process_frame
	update_content_list()


func save_timeline() -> void:
	if !timeline_editor.current_resource:
		return

	var text_array: Array = text_timeline_to_array(text)

	timeline_editor.current_resource.events = text_array
	timeline_editor.current_resource.events_processed = false
	ResourceSaver.save(timeline_editor.current_resource, timeline_editor.current_resource.resource_path)

	timeline_editor.current_resource.set_meta("timeline_not_saved", false)
	timeline_editor.current_resource_state = DialogicEditor.ResourceStates.SAVED
	DialogicResourceUtil.update_directory('dtl')


func text_timeline_to_array(orig_text:String) -> Array:
	# Parse the lines down into an array
	var events := []

	var lines := orig_text.split('\n', true)
	var idx := -1

	while idx < len(lines)-1:
		idx += 1
		var line: String = lines[idx]
		#var line_stripped: String = line.strip_edges(true, true)
		events.append(line)

	return events


################################################################################
## 					HELPFUL EDITOR FUNCTIONALITY
################################################################################

func _on_context_menu_id_pressed(id:int) -> void:
	if id == 42:
		play_from_here()


func play_from_here() -> void:
	timeline_editor.play_timeline(timeline_editor.current_resource.get_index_from_text_line(text, get_caret_line()))


func _gui_input(event):
	if not event is InputEventKey: return
	if not event.is_pressed(): return
	match event.as_text():
		"Ctrl+K", "Ctrl+Slash", "Ctrl+NumberSign":
			toggle_comment()
		"Alt+Up":
			move_lines_up()
		"Alt+Down":
			move_lines_down()

		"Ctrl+Shift+D", "Ctrl+D":
			duplicate_lines()

		"Ctrl+Shift+F6" when OS.get_name() != "macOS": # Play from here
			play_from_here()
			get_viewport().set_input_as_handled()
		"Ctrl+Shift+B" when OS.get_name() == "macOS": # Play from here
			play_from_here()
			get_viewport().set_input_as_handled()
		"Enter":
			if get_code_completion_options():
				return
			for caret in range(get_caret_count()):
				var line := get_line(get_caret_line(caret)).strip_edges()
				var event_res := DialogicTimeline.event_from_string(line, DialogicResourceUtil.get_event_cache())
				var indent_format: String = timeline_editor.current_resource.indent_format
				if event_res.can_contain_events:
					insert_text_at_caret("\n"+indent_format.repeat(get_indent_level(get_caret_line(caret))/4+1), caret)
				else:
					insert_text_at_caret("\n"+indent_format.repeat(get_indent_level(get_caret_line(caret))/4), caret)
		_:
			return
	get_viewport().set_input_as_handled()


# Toggle the selected lines as comments
func toggle_comment() -> void:
	begin_complex_operation()

	var comment_delimiter: String = delimiter_comments[0]
	var is_first_line: bool = true
	var will_comment: bool = true
	var selections: Array = []
	var line_offsets: Dictionary = {}

	for caret_index: int in range(0, get_caret_count()):
		var from_line: int = get_caret_line(caret_index)
		var from_column: int = get_caret_column(caret_index)
		var to_line: int = get_caret_line(caret_index)
		var to_column: int = get_caret_column(caret_index)

		if has_selection(caret_index):
			#from_line = get_selection_from_line(caret_index)
			to_line = get_selection_to_line(caret_index)
			from_column = get_selection_from_column(caret_index)
			to_column = get_selection_to_column(caret_index)

		selections.append({
			from_line = from_line,
			from_column = from_column,
			to_line = to_line,
			to_column = to_column
		})

		for line_number: int in range(from_line, to_line + 1):
			if line_offsets.has(line_number): continue

			var line_text: String = get_line(line_number)

			# The first line determines if we are commenting or uncommentingg
			if is_first_line:
				is_first_line = false
				will_comment = not line_text.strip_edges().begins_with(comment_delimiter)

			# Only comment/uncomment if the current line needs to
			if will_comment:
				set_line(line_number, comment_delimiter + line_text)
				line_offsets[line_number] = 1
			elif line_text.begins_with(comment_delimiter):
				set_line(line_number, line_text.substr(comment_delimiter.length()))
				line_offsets[line_number] = -1
			else:
				line_offsets[line_number] = 0

	for caret_index: int in range(0, get_caret_count()):
		var selection: Dictionary = selections[caret_index]
		select(
			selection.from_line,
			selection.from_column + line_offsets[selection.from_line],
			selection.to_line,
			selection.to_column + line_offsets[selection.to_line],
			caret_index
		)
		set_caret_column(selection.from_column + line_offsets[selection.from_line], false, caret_index)

	end_complex_operation()

	text_set.emit()
	text_changed.emit()


## Allows dragging files into the editor
func _can_drop_data(_at_position:Vector2, data:Variant) -> bool:
	if typeof(data) == TYPE_DICTIONARY and 'files' in data.keys() and len(data.files) == 1:
		return true
	return false


## Allows dragging files into the editor
func _drop_data(at_position:Vector2, data:Variant) -> void:
	if typeof(data) == TYPE_DICTIONARY and 'files' in data.keys() and len(data.files) == 1:
		set_caret_column(get_line_column_at_pos(at_position).x)
		set_caret_line(get_line_column_at_pos(at_position).y)
		var result: String = data.files[0]
		var line := get_line(get_caret_line())
		if line[get_caret_column()-1] != '"':
			result = '"'+result
		if line.length() == get_caret_column() or line[get_caret_column()] != '"':
			result = result+'"'

		insert_text_at_caret(result)
		grab_focus()


func _on_update_timer_timeout() -> void:
	update_content_list()


func update_content_list() -> void:
	var labels: PackedStringArray = []
	for i in label_regex.search_all(text):
		labels.append(i.get_string('name'))
	timeline_editor.update_label_cache(labels)

	var channels: PackedStringArray = []
	for i in channel_regex.search_all(text):
		channels.append(i.get_string('channel'))
	timeline_editor.update_audio_channel_cache(channels)


func _on_content_item_clicked(label:String) -> void:
	if label == "~ Top":
		set_caret_line(0)
		set_caret_column(0)
		adjust_viewport_to_caret()
		return

	for i in label_regex.search_all(text):
		if i.get_string('name') == label:
			set_caret_column(0)
			set_caret_line(text.count('\n', 0, i.get_start()+1))
			center_viewport_to_caret()
			return


func _search_timeline(search_text:String, match_case := false, whole_words := false) -> bool:
	var flags := 0
	if match_case:
		flags = flags | SEARCH_MATCH_CASE
	if whole_words:
		flags = flags | SEARCH_WHOLE_WORDS
	set_meta("current_search", search_text)
	set_meta("current_search_flags", flags)

	set_search_text(search_text)
	set_search_flags(flags)
	queue_redraw()

	var result := search(search_text, flags, get_selection_from_line(), get_selection_from_column())
	if result.y != -1:
		select.call_deferred(result.y, result.x, result.y, result.x + search_text.length())
	return result.y != -1


func _search_navigate_down() -> void:
	search_navigate(false)


func _search_navigate_up() -> void:
	search_navigate(true)


func search_navigate(navigate_up := false) -> void:
	var pos := get_next_search_position(navigate_up)
	if pos.x == -1:
		return
	select(pos.y, pos.x, pos.y, pos.x+len(get_meta("current_search")))
	set_caret_line(pos.y)
	center_viewport_to_caret()
	queue_redraw()


func get_next_search_position(navigate_up := false) -> Vector2i:
	if not has_meta("current_search"):
		return Vector2i(-1, -1)
	var pos: Vector2i
	var search_from_line := 0
	var search_from_column := 0
	if has_selection():
		if navigate_up:
			search_from_line = get_selection_from_line()
			search_from_column = get_selection_from_column()-1
			if search_from_column == -1:
				if search_from_line == 0:
					search_from_line = get_line_count()
				else:
					search_from_line -= 1
				search_from_column = max(get_line(search_from_line).length()-1,0)
		else:
			search_from_line = get_selection_to_line()
			search_from_column = get_selection_to_column()
	else:
		search_from_line = get_caret_line()
		search_from_column = get_caret_column()

	var flags: int = get_meta("current_search_flags", 0)
	if navigate_up:
		flags = flags | SEARCH_BACKWARDS

	pos = search(get_meta("current_search"), flags, search_from_line, search_from_column)
	return pos


func replace(replace_text:String) -> void:
	if has_selection():
		set_caret_line(get_selection_from_line())
		set_caret_column(get_selection_from_column())

	var pos := get_next_search_position()
	if pos.x == -1:
		return

	if not has_meta("current_search"):
		return

	begin_complex_operation()
	insert_text("@@", pos.y, pos.x)
	if get_meta("current_search_flags") & SEARCH_MATCH_CASE:
		text = text.replace("@@"+get_meta("current_search"), replace_text)
	else:
		text = text.replacen("@@"+get_meta("current_search"), replace_text)
	end_complex_operation()

	set_caret_line(pos.y)
	set_caret_column(pos.x)

	timeline_editor.replace_in_timeline()


func replace_all(replace_text:String) -> void:
	begin_complex_operation()
	var next_pos := get_next_search_position()
	while next_pos.y != -1:
		insert_text("@@", next_pos.y, next_pos.x)
		if get_meta("current_search_flags") & SEARCH_MATCH_CASE:
			text = text.replace("@@"+get_meta("current_search"), replace_text)
		else:
			text = text.replacen("@@"+get_meta("current_search"), replace_text)
		next_pos = get_next_search_position()
		set_caret_line(next_pos.y)
		set_caret_column(next_pos.x)
	end_complex_operation()

	timeline_editor.replace_in_timeline()


################################################################################
## 					AUTO COMPLETION
################################################################################

## Called if something was typed
func _request_code_completion(force:bool):
	code_completion_helper.request_code_completion(force, self)


## Filters the list of all possible options, depending on what was typed
## Purpose of the different Kinds is explained in [_request_code_completion]
func _filter_code_completion_candidates(candidates:Array) -> Array:
	return code_completion_helper.filter_code_completion_candidates(candidates, self)


## Called when code completion was activated
## Inserts the selected item
func _confirm_code_completion(should_replace:bool) -> void:
	code_completion_helper.confirm_code_completion(should_replace, self)


################################################################################
##					SYMBOL CLICKING
################################################################################

## Performs an action (like opening a link) when a valid symbol was clicked
func _on_symbol_lookup(symbol, line, column):
	code_completion_helper.symbol_lookup(symbol, line, column)


## Called to test if a symbol can be clicked
func _on_symbol_validate(symbol:String) -> void:
	code_completion_helper.symbol_validate(symbol, self)
