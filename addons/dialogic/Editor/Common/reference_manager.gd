@tool
extends PanelContainer

## This manager shows a list of changed references and allows searching for them and replacing them.

var reference_changes :Array[Dictionary] = []


func _ready() -> void:
	if owner.get_parent() is SubViewport:
		return
	%ReplacementSection.hide()
	
	%CheckButton.icon = get_theme_icon("Search", "EditorIcons")
	%Replace.icon = get_theme_icon("ArrowRight", "EditorIcons")
	%TitleTooltip.texture = get_theme_icon("NodeInfo", "EditorIcons")
	%TitleTooltip.modulate = get_theme_color("readonly_color", "Editor")
	
	%State.add_theme_color_override("font_color", get_theme_color("warning_color", "Editor"))
	
	self_modulate = get_theme_color("background", "Editor")
	
	
	%Title.add_theme_font_override("font", get_theme_font("title", "EditorFonts"))
	%Title.add_theme_color_override("font_color", get_theme_color("accent_color", "Editor"))
	%Title.add_theme_font_size_override("font_size", get_theme_font_size("doc_size", "EditorFonts"))
	
	
	%SectionTitle.add_theme_font_override("font", get_theme_font("title", "EditorFonts"))
	%SectionTitle.add_theme_font_size_override("font_size", get_theme_font_size("doc_size", "EditorFonts"))
	
	%SectionTitle2.add_theme_font_override("font", get_theme_font("title", "EditorFonts"))
	%SectionTitle2.add_theme_font_size_override("font_size", get_theme_font_size("doc_size", "EditorFonts"))


func open() -> void:
	show()
	%ReplacementPanel.hide()
	%ReplacementSection.hide()
	%ChangeTree.clear()
	%ChangeTree.create_item()
	%ChangeTree.set_column_expand(0, false)
	%ChangeTree.set_column_expand(2, false)
	var categories := {null:%ChangeTree.get_root()}
	for i in reference_changes:
		var parent : TreeItem = null
		if !i.get('category', null) in categories:
			parent = %ChangeTree.create_item()
			parent.set_text(1, i.category)
			parent.set_custom_color(1, get_theme_color("disabled_font_color", "Editor"))
			categories[i.category] = parent
		else:
			parent = categories[i.get('category')]
		
		var item :TreeItem = %ChangeTree.create_item(parent)
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
		
		%CheckButton.disabled = reference_changes.is_empty()
	
	if id == 1:
		%ReplacementPanel.open_existing(item, item.get_metadata(0))


func _on_change_tree_item_edited() -> void:
	if !%ChangeTree.get_selected():
		return
	%CheckButton.disabled = false


func _on_check_button_pressed() -> void:
	var to_be_checked :Array[Dictionary]= []
	var item :TreeItem = %ChangeTree.get_root()
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
	var regexes : Array[Array] = []
	
	for i in replacements:
		if i.has('character_names') and !i.character_names.is_empty():
			i['character_regex'] = RegEx.create_from_string("(?m)^(Join|Update|Leave)?\\s*("+str(i.character_names).replace('"', '').replace(', ', '|').trim_suffix(']').trim_prefix('[').replace('/', '\\/')+")(?(1).*|.*:)")
		
		for regex_string in i.regex:
			var regex := RegEx.create_from_string(regex_string)
			regexes.append([regex, i])
	
	var finds : Array[Dictionary] = []
	
	for timeline_path in DialogicUtil.list_resources_of_type('.dtl'):
		%State.text = "Loading '"+timeline_path+"'"
		
		var timeline_file := FileAccess.open(timeline_path, FileAccess.READ)
		var timeline_text :String = timeline_file.get_as_text()
		var timeline_events : PackedStringArray = timeline_text.split('\n')
		timeline_file.close()

		for regex_info in regexes:
			%State.text = "Searching '"+timeline_path+"' for "+regex_info[1].what+' -> '+regex_info[1].forwhat
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
				
	
	for regex_info in regexes:
		regex_info[1]['item'].set_text(2, str(regex_info[1]['count']))
	update_count_coloring()
	
	%State.text = str(len(finds))+ " occurrences found"
	
	%ReferenceTree.clear()
	%ReferenceTree.set_column_expand(0, false)
	%ReferenceTree.create_item()
	
	var timelines := {}
	var height := 0
	for i in finds:
		var parent : TreeItem = null
		if !i.timeline in timelines:
			parent = %ReferenceTree.create_item()
			parent.set_text(1, i.timeline)
			parent.set_custom_color(1, get_theme_color("disabled_font_color", "Editor"))
			timelines[i.timeline] = parent
			height += %ReferenceTree.get_item_area_rect(parent).size.y+10
		else:
			parent = timelines[i.timeline]
		
		var item :TreeItem = %ReferenceTree.create_item(parent)
		item.set_text(1, 'Line '+str(i.line_number)+': '+i.line)
		item.set_tooltip_text(1, i.info.what+' -> '+i.info.forwhat)
		item.set_cell_mode(0, TreeItem.CELL_MODE_CHECK)
		item.set_checked(0, true)
		item.set_editable(0, true)
		item.set_metadata(0, i)
		height += %ReferenceTree.get_item_area_rect(item).size.y+10
		var change_item :TreeItem = i.info.item
		change_item.set_meta('found_items', change_item.get_meta('found_items', [])+[item])
		
	
	
	%ReferenceTree.custom_minimum_size.y = min(height, 200)
	
	%ReferenceTree.visible = !finds.is_empty()
	%Replace.disabled = finds.is_empty()
	if finds.is_empty():
		%State.text = "Nothing found"
	else:
		%Replace.grab_focus()


func get_line(string:String, at_index:int) -> String:
	return string.substr(max(string.rfind('\n', at_index), 0), string.find('\n', at_index)-string.rfind('\n', at_index))


func update_count_coloring() -> void:
	var item :TreeItem = %ChangeTree.get_root()
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
	var to_be_replaced :Array[Dictionary]= []
	var item :TreeItem = %ReferenceTree.get_root()
	var affected_timelines :Array[String]= []
	
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
	var timeline_editor :DialogicEditor = find_parent('EditorView').editors_manager.editors['Timeline'].node
	if timeline_editor.current_resource != null and timeline_editor.current_resource.resource_path in timelines:
		reopen_timeline = timeline_editor.current_resource.resource_path
		find_parent('EditorView').editors_manager.clear_editor(timeline_editor)
	
	replacement_info.sort_custom(func(a,b): return a.match.get_start() < b.match.get_start())
	
	for timeline_path in timelines:
		%State.text = "Loading '"+timeline_path+"'"
		
		var timeline_file := FileAccess.open(timeline_path, FileAccess.READ_WRITE)
		var timeline_text :String = timeline_file.get_as_text()
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


func close() -> void:
	var item :TreeItem = %ChangeTree.get_root()
	while item.get_next_visible():
		item = item.get_next_visible()
		
		if item.get_child_count():
			continue
		if item.get_text(2) != "" and int(item.get_text(2)) == 0:
			reference_changes.erase(item.get_metadata(0))

