@tool
extends VSplitContainer

## This manager shows a list of changed references and allows searching for them and replacing them.

var reference_changes: Array[Dictionary] = []:
	set(changes):
		reference_changes = changes
		update_indicator()

var search_regexes: Array[Array]
var finder_thread: Thread
var progress_mutex: Mutex
var progress_percent: float = 0.0
var progress_message: String = ""


func _ready() -> void:
	if owner.get_parent() is SubViewport:
		return

	%TabA.text = "Broken References"
	%TabA.icon = get_theme_icon("Unlinked", "EditorIcons")

	owner.get_parent().visibility_changed.connect(func(): if is_visible_in_tree(): open())

	%ReplacementSection.hide()

	%CheckButton.icon = get_theme_icon("Search", "EditorIcons")
	%Replace.icon = get_theme_icon("ArrowRight", "EditorIcons")

	%State.add_theme_color_override("font_color", get_theme_color("warning_color", "Editor"))
	visibility_changed.connect(func(): if !visible: close())
	await get_parent().ready

	var tab_button: Control = %TabA
	var dot := Sprite2D.new()
	dot.texture = get_theme_icon("GuiGraphNodePort", "EditorIcons")
	dot.scale = Vector2(0.8, 0.8)
	dot.z_index = 10
	dot.position = Vector2(tab_button.size.x, tab_button.size.y*0.25)
	dot.modulate = get_theme_color("warning_color", "Editor").lightened(0.5)

	tab_button.add_child(dot)
	update_indicator()


func open() -> void:
	%ReplacementEditPanel.hide()
	%ReplacementSection.hide()
	%ChangeTree.clear()
	%ChangeTree.create_item()
	%ChangeTree.set_column_expand(0, false)
	%ChangeTree.set_column_expand(2, false)
	%ChangeTree.set_column_custom_minimum_width(2, 50)
	var categories := {null:%ChangeTree.get_root()}
	for i in reference_changes:
		var parent: TreeItem = null
		if !i.get('category', null) in categories:
			parent = %ChangeTree.create_item()
			parent.set_text(1, i.category)
			parent.set_custom_color(1, get_theme_color("disabled_font_color", "Editor"))
			categories[i.category] = parent
		else:
			parent = categories[i.get('category')]

		var item: TreeItem = %ChangeTree.create_item(parent)
		item.set_text(1, i.what+" -> "+i.forwhat)
		item.add_button(1, get_theme_icon("Edit", "EditorIcons"), 1, false, 'Edit')
		item.add_button(1, get_theme_icon("Remove", "EditorIcons"), 0, false, 'Remove Change from List')
		item.set_cell_mode(0, TreeItem.CELL_MODE_CHECK)
		item.set_checked(0, true)
		item.set_editable(0, true)
		item.set_metadata(0, i)
	%CheckButton.disabled = reference_changes.is_empty()


func _on_change_tree_button_clicked(item:TreeItem, column:int, id:int, mouse_button_index:int) -> void:
	if id == 0:
		reference_changes.erase(item.get_metadata(0))
		if item.get_parent().get_child_count() == 1:
			item.get_parent().free()
		else:
			item.free()
		update_indicator()
		%CheckButton.disabled = reference_changes.is_empty()

	if id == 1:
		%ReplacementEditPanel.open_existing(item, item.get_metadata(0))

	%ReplacementSection.hide()


func _on_change_tree_item_edited() -> void:
	if !%ChangeTree.get_selected():
		return
	%CheckButton.disabled = false


func _on_check_button_pressed() -> void:
	var to_be_checked: Array[Dictionary]= []
	var item: TreeItem = %ChangeTree.get_root()
	while item.get_next_visible():
		item = item.get_next_visible()

		if item.get_child_count():
			continue

		if item.is_checked(0):
			to_be_checked.append(item.get_metadata(0))
			to_be_checked[-1]['item'] = item
			to_be_checked[-1]['count'] = 0

	open_finder(to_be_checked)
	%CheckButton.disabled = true


func open_finder(replacements:Array[Dictionary]) -> void:
	%ReplacementSection.show()
	%Progress.show()
	%ReferenceTree.hide()

	search_regexes = []
	for i in replacements:
		if i.has('character_names') and !i.character_names.is_empty():
			i['character_regex'] = RegEx.create_from_string("(?m)^(join|update|leave)?\\s*("+str(i.character_names).replace('"', '').replace(', ', '|').trim_suffix(']').trim_prefix('[').replace('/', '\\/')+")(?(1).*|.*:)")

		for regex_string in i.regex:
			var regex := RegEx.create_from_string(regex_string)
			search_regexes.append([regex, i])

	finder_thread = Thread.new()
	progress_mutex = Mutex.new()
	finder_thread.start(search_timelines.bind(search_regexes))


func _process(delta: float) -> void:
	if finder_thread and finder_thread.is_started():
		if finder_thread.is_alive():
			progress_mutex.lock()
			%State.text = progress_message
			%Progress.value = progress_percent
			progress_mutex.unlock()
		else:
			var finds: Variant = finder_thread.wait_to_finish()
			display_search_results(finds)



func display_search_results(finds:Array[Dictionary]) -> void:
	%Progress.hide()
	%ReferenceTree.show()
	for regex_info in search_regexes:
		regex_info[1]['item'].set_text(2, str(regex_info[1]['count']))

	update_count_coloring()
	%State.text = str(len(finds))+ " occurrences found"

	%ReferenceTree.clear()
	%ReferenceTree.set_column_expand(0, false)
	%ReferenceTree.set_column_expand(1, false)
	%ReferenceTree.set_column_custom_minimum_width(1, 50)
	%ReferenceTree.create_item()

	var timelines := {}
	var height := 0
	for i in finds:
		var parent: TreeItem = null
		if !i.timeline in timelines:
			parent = %ReferenceTree.create_item()
			parent.set_text(0, i.timeline)
			parent.set_custom_color(0, get_theme_color("disabled_font_color", "Editor"))
			parent.set_expand_right(0, true)
			timelines[i.timeline] = parent
			height += %ReferenceTree.get_item_area_rect(parent).size.y+10
		else:
			parent = timelines[i.timeline]

		var item: TreeItem = %ReferenceTree.create_item(parent)
		item.set_cell_mode(0, TreeItem.CELL_MODE_CHECK)
		item.set_checked(0, true)
		item.set_editable(0, true)
		item.set_metadata(0, i)
		item.set_text(1, str(i.line_number)+':')
		item.set_text_alignment(1, HORIZONTAL_ALIGNMENT_RIGHT)
		item.set_cell_mode(2, TreeItem.CELL_MODE_CUSTOM)
		item.set_text(2, i.line)
		item.set_tooltip_text(2, i.info.what+' -> '+i.info.forwhat)
		item.set_custom_draw_callback(2, _custom_draw)
		height += %ReferenceTree.get_item_area_rect(item).size.y+10
		var change_item: TreeItem = i.info.item
		change_item.set_meta('found_items', change_item.get_meta('found_items', [])+[item])

	%ReferenceTree.custom_minimum_size.y = min(height, 200)

	%ReferenceTree.visible = !finds.is_empty()
	%Replace.disabled = finds.is_empty()
	if finds.is_empty():
		%State.text = "Nothing found"
	else:
		%Replace.grab_focus()


## Highlights the found text in the result tree
## Inspired by how godot highlights stuff in its search results
func _custom_draw(item:TreeItem, rect:Rect2) -> void:
	var text := item.get_text(2)
	var find: Dictionary = item.get_metadata(0)

	var font: Font = %ReferenceTree.get_theme_font("font")
	var font_size: int = %ReferenceTree.get_theme_font_size("font_size")

	var match_rect := rect
	var beginning_index: int = find.match.get_start("replace")-find.line_start-1
	match_rect.position.x += font.get_string_size(text.left(beginning_index), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x -1
	match_rect.size.x = font.get_string_size(find.info.what, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x + 1
	match_rect.position.y += 1 * DialogicUtil.get_editor_scale()
	match_rect.size.y -= 2 * DialogicUtil.get_editor_scale()
	match_rect.position.x += 4

	%ReferenceTree.draw_rect(match_rect, get_theme_color("highlight_color", "Editor"), true)
	%ReferenceTree.draw_rect(match_rect, get_theme_color("box_selection_stroke_color", "Editor"), false)


func search_timelines(regexes:Array[Array]) -> Array[Dictionary]:
	var finds: Array[Dictionary] = []

	var timeline_paths := DialogicResourceUtil.list_resources_of_type('.dtl')

	var progress := 0
	var progress_max: float = len(timeline_paths)*len(regexes)

	for timeline_path:String in timeline_paths:

		var timeline_file := FileAccess.open(timeline_path, FileAccess.READ)
		var timeline_text: String = timeline_file.get_as_text()
		var timeline_event: PackedStringArray = timeline_text.split('\n')
		timeline_file.close()

		for regex_info in regexes:
			progress += 1
			progress_mutex.lock()
			progress_percent = 1/progress_max*progress
			progress_message = "Searching '"+timeline_path+"' for "+regex_info[1].what+' -> '+regex_info[1].forwhat
			progress_mutex.unlock()
			for i in regex_info[0].search_all(timeline_text):
				if regex_info[1].has('character_regex'):
					if regex_info[1].character_regex.search(get_line(timeline_text, i.get_start()+1)) == null:
						continue

				var line_number := timeline_text.count('\n', 0, i.get_start()+1)+1
				var line := timeline_text.get_slice('\n', line_number-1)
				finds.append({
				'match':i,
				'timeline':timeline_path,
				'info': regex_info[1],
				'line_number': line_number,
				'line': line,
				'line_start': timeline_text.rfind('\n', i.get_start())
				})
				regex_info[1]['count'] += 1
	return finds


func _exit_tree() -> void:
	# Shutting of
	if finder_thread and finder_thread.is_alive():
		finder_thread.wait_to_finish()


func get_line(string:String, at_index:int) -> String:
	return string.substr(max(string.rfind('\n', at_index), 0), string.find('\n', at_index)-string.rfind('\n', at_index))


func update_count_coloring() -> void:
	var item: TreeItem = %ChangeTree.get_root()
	while item.get_next_visible():
		item = item.get_next_visible()

		if item.get_child_count():
			continue
		if int(item.get_text(2)) > 0:
			item.set_custom_bg_color(1, get_theme_color("warning_color", "Editor").darkened(0.8))
			item.set_custom_color(1, get_theme_color("warning_color", "Editor"))
			item.set_custom_color(2, get_theme_color("warning_color", "Editor"))
		else:
			item.set_custom_color(2, get_theme_color("success_color", "Editor"))
			item.set_custom_color(1, get_theme_color("readonly_font_color", "Editor"))
			if item.get_button_count(1):
				item.erase_button(1, 1)
			item.add_button(1, get_theme_icon("Eraser", "EditorIcons"), -1, true, "This reference was not found anywhere and will be removed from this list.")


func _on_replace_pressed() -> void:
	var to_be_replaced: Array[Dictionary]= []
	var item: TreeItem = %ReferenceTree.get_root()
	var affected_timelines: Array[String]= []

	while item.get_next_visible():
		item = item.get_next_visible()

		if item.get_child_count():
			continue

		if item.is_checked(0):
			to_be_replaced.append(item.get_metadata(0))
			to_be_replaced[-1]['f_item'] = item
			if !item.get_metadata(0).timeline in affected_timelines:
				affected_timelines.append(item.get_metadata(0).timeline)
	replace(affected_timelines, to_be_replaced)


func replace(timelines:Array[String], replacement_info:Array[Dictionary]) -> void:
	var reopen_timeline := ""
	var timeline_editor: DialogicEditor = find_parent('EditorView').editors_manager.editors['Timeline'].node
	if timeline_editor.current_resource != null and timeline_editor.current_resource.resource_path in timelines:
		reopen_timeline = timeline_editor.current_resource.resource_path
		find_parent('EditorView').editors_manager.clear_editor(timeline_editor)

	replacement_info.sort_custom(func(a,b): return a.match.get_start() < b.match.get_start())

	for timeline_path in timelines:
		%State.text = "Loading '"+timeline_path+"'"

		var timeline_file := FileAccess.open(timeline_path, FileAccess.READ_WRITE)
		var timeline_text: String = timeline_file.get_as_text()
		var timeline_events := timeline_text.split('\n')
		timeline_file.close()

		var idx := 1
		var offset_correction := 0
		for replacement in replacement_info:
			if replacement.timeline != timeline_path:
				continue

			%State.text = "Replacing in '"+timeline_path + "' ("+str(idx)+"/"+str(len(replacement_info))+")"
			var group := 'replace'
			if not 'replace' in replacement.match.names:
				group = ''


			timeline_text = timeline_text.substr(0, replacement.match.get_start(group) + offset_correction) + \
							replacement.info.regex_replacement + \
							timeline_text.substr(replacement.match.get_end(group) + offset_correction)
			offset_correction += len(replacement.info.regex_replacement)-len(replacement.match.get_string(group))

			replacement.info.count -= 1
			replacement.info.item.set_text(2, str(replacement.info.count))
			replacement.f_item.set_custom_bg_color(1, get_theme_color("success_color", "Editor").darkened(0.8))

		timeline_file = FileAccess.open(timeline_path, FileAccess.WRITE)
		timeline_file.store_string(timeline_text.strip_edges(false, true))
		timeline_file.close()

		if ResourceLoader.has_cached(timeline_path):
			var tml := load(timeline_path)
			tml.from_text(timeline_text)

	if !reopen_timeline.is_empty():
		find_parent('EditorView').editors_manager.edit_resource(load(reopen_timeline), false, true)

	update_count_coloring()

	%Replace.disabled = true
	%CheckButton.disabled = false
	%State.text = "Done Replacing"


func update_indicator() -> void:
	%TabA.get_child(0).visible = !reference_changes.is_empty()


func close() -> void:
	var item: TreeItem = %ChangeTree.get_root()
	if item:
		while item.get_next_visible():
			item = item.get_next_visible()

			if item.get_child_count():
				continue
			if item.get_text(2) != "" and int(item.get_text(2)) == 0:
				reference_changes.erase(item.get_metadata(0))
	for i in reference_changes:
		i.item = null
	DialogicUtil.set_editor_setting('reference_changes', reference_changes)
	update_indicator()
	find_parent("ReferenceManager").update_indicator()


func _on_add_button_pressed() -> void:
	%ReplacementEditPanel._on_add_pressed()
