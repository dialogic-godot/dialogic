@tool
extends CodeEdit

## Sub-Editor that allows editing timelines in a text format.

@onready var timeline_editor := get_parent().get_parent()
@onready var code_completion_helper: Node= find_parent('EditorsManager').get_node('CodeCompletionHelper')

var label_regex := RegEx.create_from_string('label +(?<name>[^\n]+)')

func _ready() -> void:
	await find_parent('EditorView').ready
	syntax_highlighter = code_completion_helper.syntax_highlighter
	timeline_editor.editors_manager.sidebar.content_item_activated.connect(_on_content_item_clicked)


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


func text_timeline_to_array(text:String) -> Array:
	# Parse the lines down into an array
	var events := []

	var lines := text.split('\n', true)
	var idx := -1

	while idx < len(lines)-1:
		idx += 1
		var line: String = lines[idx]
		var line_stripped: String = line.strip_edges(true, true)
		events.append(line)

	return events


################################################################################
## 					HELPFUL EDITOR FUNCTIONALITY
################################################################################

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
		"Ctrl+Shift+D":
			duplicate_line()
		_:
			return
	get_viewport().set_input_as_handled()

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


func duplicate_line() -> void:
	var cursor: Vector2 = Vector2(get_caret_column(), get_caret_line())
	var from: int = cursor.y
	var to: int = cursor.y+1
	if has_selection():
		from = get_selection_from_line()
		to = get_selection_to_line()+1

	var lines := text.split("\n")
	var lines_to_dupl: PackedStringArray = lines.slice(from, to)

	text = "\n".join(lines.slice(0, from)+lines_to_dupl+lines.slice(from))

	set_caret_line(cursor.y+to-from)
	set_caret_column(cursor.x)
	text_changed.emit()


# Allows dragging files into the editor
func _can_drop_data(at_position:Vector2, data:Variant) -> bool:
	if typeof(data) == TYPE_DICTIONARY and 'files' in data.keys() and len(data.files) == 1:
		return true
	return false


# Allows dragging files into the editor
func _drop_data(at_position:Vector2, data:Variant) -> void:
	if typeof(data) == TYPE_DICTIONARY and 'files' in data.keys() and len(data.files) == 1:
		set_caret_column(get_line_column_at_pos(at_position).x)
		set_caret_line(get_line_column_at_pos(at_position).y)
		var result: String = data.files[0]
		if get_line(get_caret_line())[get_caret_column()-1] != '"':
			result = '"'+result
		if get_line(get_caret_line())[get_caret_column()] != '"':
			result = result+'"'

		insert_text_at_caret(result)


func _on_update_timer_timeout() -> void:
	update_content_list()


func update_content_list() -> void:
	var labels: PackedStringArray = []
	for i in label_regex.search_all(text):
		labels.append(i.get_string('name'))
	timeline_editor.editors_manager.sidebar.update_content_list(labels)


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


func _search_timeline(search_text:String) -> bool:
	set_search_text(search_text)
	queue_redraw()
	set_meta("current_search", search_text)

	return search(search_text, 0, 0, 0).y != -1


func _search_navigate_down() -> void:
	search_navigate(false)


func _search_navigate_up() -> void:
	search_navigate(true)


func search_navigate(navigate_up := false) -> void:
	if not has_meta("current_search"):
		return
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

	pos = search(get_meta("current_search"), 4 if navigate_up else 0, search_from_line, search_from_column)
	select(pos.y, pos.x, pos.y, pos.x+len(get_meta("current_search")))
	set_caret_line(pos.y)
	center_viewport_to_caret()
	queue_redraw()


################################################################################
## 					AUTO COMPLETION
################################################################################

# Called if something was typed
func _request_code_completion(force:bool):
	code_completion_helper.request_code_completion(force, self)


# Filters the list of all possible options, depending on what was typed
# Purpose of the different Kinds is explained in [_request_code_completion]
func _filter_code_completion_candidates(candidates:Array) -> Array:
	return code_completion_helper.filter_code_completion_candidates(candidates, self)


# Called when code completion was activated
# Inserts the selected item
func _confirm_code_completion(replace:bool) -> void:
	code_completion_helper.confirm_code_completion(replace, self)


################################################################################
##					SYMBOL CLICKING
################################################################################

# Performs an action (like opening a link) when a valid symbol was clicked
func _on_symbol_lookup(symbol, line, column):
	code_completion_helper.symbol_lookup(symbol, line, column)


# Called to test if a symbol can be clicked
func _on_symbol_validate(symbol:String) -> void:
	code_completion_helper.symbol_validate(symbol, self)
