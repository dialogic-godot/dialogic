@tool
extends CodeEdit

## Sub-Editor that allows editing timelines in a text format.

@onready var timeline_editor := get_parent().get_parent()
@onready var code_completion_helper: Node= find_parent('EditorsManager').get_node('CodeCompletionHelper')

var label_regex := RegEx.create_from_string('label +(?<name>[^\n]+)')
var channel_regex := RegEx.create_from_string(r'audio +(?<channel>[\w-]{2,}|[\w]+)')

func _ready() -> void:
	await find_parent('EditorView').ready
	syntax_highlighter = code_completion_helper.syntax_highlighter
	timeline_editor.editors_manager.sidebar.content_item_activated.connect(_on_content_item_clicked)

	get_menu().add_icon_item(get_theme_icon("PlayStart", "EditorIcons"), "Play from here", 42)
	get_menu().id_pressed.connect(_on_context_menu_id_pressed)


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

func _on_context_menu_id_pressed(id:int) -> void:
	if id == 42:
		play_from_here()


func play_from_here() -> void:
	timeline_editor.play_timeline(timeline_editor.current_resource.get_index_from_text_line(text, get_caret_line()))


func _gui_input(event):
	if not event is InputEventKey: return
	if not event.is_pressed(): return
	match event.as_text():
		"Ctrl+K", "Ctrl+Slash":
			toggle_comment()

		# TODO clean this up when dropping 4.2 support
		"Alt+Up":
			if has_method("move_lines_up"):
				call("move_lines_up")
		"Alt+Down":
			if has_method("move_lines_down"):
				call("move_lines_down")

		"Ctrl+Shift+D", "Ctrl+D":
			duplicate_lines()

		"Ctrl+F6" when OS.get_name() != "macOS": # Play from here
			play_from_here()
		"Ctrl+Shift+B" when OS.get_name() == "macOS": # Play from here
			play_from_here()
		_:
			return
	get_viewport().set_input_as_handled()


# Toggle the selected lines as comments
func toggle_comment() -> void:
	var cursor: Vector2 = Vector2(get_caret_column(), get_caret_line())
	var selection := Rect2i(
		Vector2i(get_selection_line(), get_selection_column()),
		# TODO When ditching godot 4.2, switch to this, the above methods have been deprecated in 4.3
		#Vector2i(get_selection_origin_line(), get_selection_origin_column()),
		Vector2i(get_caret_line(), get_caret_column()))
	var from: int = cursor.y
	var to: int = cursor.y
	if has_selection():
		from = get_selection_from_line()
		to = get_selection_to_line()

	var lines: PackedStringArray = text.split("\n")
	var will_comment: bool = false
	for i in range(from, to+1):
		if not lines[i].begins_with("#"):
			will_comment = true

	for i in range(from, to + 1):
		if will_comment:
			lines[i] = "#" + lines[i]
		else:
			lines[i] = lines[i].trim_prefix("#")

	text = "\n".join(lines)
	if will_comment:
		cursor.x += 1
		selection.position.y += 1
		selection.size.y += 1
	else:
		cursor.x -= 1
		selection.position.y -= 1
		selection.size.y -= 1
	select(selection.position.x, selection.position.y, selection.size.x, selection.size.y)
	text_changed.emit()


## Allows dragging files into the editor
func _can_drop_data(at_position:Vector2, data:Variant) -> bool:
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
	timeline_editor.editors_manager.sidebar.update_content_list(labels)

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

## Called if something was typed
func _request_code_completion(force:bool):
	code_completion_helper.request_code_completion(force, self)


## Filters the list of all possible options, depending on what was typed
## Purpose of the different Kinds is explained in [_request_code_completion]
func _filter_code_completion_candidates(candidates:Array) -> Array:
	return code_completion_helper.filter_code_completion_candidates(candidates, self)


## Called when code completion was activated
## Inserts the selected item
func _confirm_code_completion(replace:bool) -> void:
	code_completion_helper.confirm_code_completion(replace, self)


################################################################################
##					SYMBOL CLICKING
################################################################################

## Performs an action (like opening a link) when a valid symbol was clicked
func _on_symbol_lookup(symbol, line, column):
	code_completion_helper.symbol_lookup(symbol, line, column)


## Called to test if a symbol can be clicked
func _on_symbol_validate(symbol:String) -> void:
	code_completion_helper.symbol_validate(symbol, self)
