@tool
extends PanelContainer

## This manager shows a list of changed references and allows searching for them and replacing them.

var reference_changes :Array[Dictionary] = []


func _ready():
	%FindList.hide()
	self_modulate = get_theme_color("base_color", "Editor")


func open():
	show()
	%FindList.hide()

	
	%ChangeTree.clear()
	%ChangeTree.create_item()
	%ChangeTree.set_column_expand(0, false)
	%ChangeTree.set_column_expand(2, false)
	%CheckButton.disabled = false
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
		item.add_button(1, get_theme_icon("Remove", "EditorIcons"), 0, false, 'Remove Change from List')
		item.set_cell_mode(0, TreeItem.CELL_MODE_CHECK)
		item.set_checked(0, true)
		item.set_editable(0, true)
		item.set_metadata(0, i)


func _on_change_tree_button_clicked(item:TreeItem, column, id, mouse_button_index):
	if id == 0:
		reference_changes.erase(item.get_metadata(0))
		if item.get_parent().get_child_count() == 1:
			item.get_parent().free()
		else:
			item.free()
		
		%CheckButton.disabled = false


func _on_change_tree_item_edited():
	if !%ChangeTree.get_selected():
		return
	%CheckButton.disabled = false
	


func _on_check_button_pressed():
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


func open_finder(replacements:Array[Dictionary]):
	%FindList.show()
	%SearchProgress.show()
	var regexes : Array[Array] = []
	
	for i in replacements:
		for regex_string in i.regex:
			var regex := RegEx.create_from_string(regex_string)
			regexes.append([regex, i])
	
	var finds : Array[Dictionary] = []
	
	var max_progress := len(DialogicUtil.list_resources_of_type('.dtl')) * len(regexes)
	var progress := 0
	for timeline_path in DialogicUtil.list_resources_of_type('.dtl'):
		%State.text = "Loading '"+timeline_path+"'"
		var timeline_file := FileAccess.open(timeline_path, FileAccess.READ)
		var timeline_text :String = timeline_file.get_as_text()
		timeline_file.close()
		for regex_info in regexes:
			%State.text = "Searching '"+timeline_path+"' for "+regex_info[1].what+' -> '+regex_info[1].forwhat
			print("Searching '"+timeline_path+"' for "+regex_info[1].what+' -> '+regex_info[1].forwhat)
			for i in regex_info[0].search_all(timeline_text):
				finds.append({
					'match':i,
				 	'timeline':timeline_path,
					'info': regex_info[1], 
					'line_number': timeline_text.count('\n', 0, i.get_start())+1,
					'line':timeline_text.substr(max(timeline_text.rfind('\n', i.get_start()), 0), timeline_text.find('\n', i.get_end())-timeline_text.rfind('\n', i.get_start()))
					})
				regex_info[1]['count'] += 1
				
			progress += 1
			%SearchProgress.value = 100.0/max_progress*progress
	
	for regex_info in regexes:
		regex_info[1]['item'].set_text(2, str(regex_info[1]['count']))
	update_count_coloring()
	
	%SearchProgress.hide()
	%State.text = "Done Searching"
	
	%ReferenceTree.clear()
	%ReferenceTree.set_column_expand(0, false)
	%ReferenceTree.create_item()
	
	var timelines := {}
	for i in finds:
		var parent : TreeItem = null
		if !i.timeline in timelines:
			parent = %ReferenceTree.create_item()
			parent.set_text(1, i.timeline)
			parent.set_custom_color(1, get_theme_color("disabled_font_color", "Editor"))
			timelines[i.timeline] = parent
		else:
			parent = timelines[i.timeline]
		
		var item :TreeItem = %ReferenceTree.create_item(parent)
		item.set_text(1, 'Line '+str(i.line_number)+': '+i.line)
		item.set_tooltip_text(1, i.info.what+' -> '+i.info.forwhat)
		item.set_cell_mode(0, TreeItem.CELL_MODE_CHECK)
		item.set_checked(0, true)
		item.set_editable(0, true)
		item.set_metadata(0, i)
		var change_item :TreeItem = i.info.item
		change_item.set_meta('found_items', change_item.get_meta('found_items', [])+[item])
	
	%ReferenceTree.visible = !finds.is_empty()
	%Replace.disabled = finds.is_empty()
	if finds.is_empty():
		%State.text = "Done Searching: Nothing found!"
	else:
		%Replace.grab_focus()

func update_count_coloring():
	var item :TreeItem = %ChangeTree.get_root()
	while item.get_next_visible():
		item = item.get_next_visible()
		
		if item.get_child_count():
			continue
		if int(item.get_text(2)) > 0:
			item.set_custom_bg_color(1, get_theme_color("warning_color", "Editor").darkened(0.8))
		else:
			item.set_custom_bg_color(1, get_theme_color("success_color", "Editor").darkened(0.8))
			if item.get_button_count(1):
				item.erase_button(1, 0)
			item.add_button(1, get_theme_icon("Eraser", "EditorIcons"), 0, true, "This item will auto-deleted because it wasn't found anywhere.")
	

func _on_replace_pressed() -> void:
	var to_be_repalced :Array[Dictionary]= []
	var item :TreeItem = %ReferenceTree.get_root()
	var affected_timelines :Array[String]= []
	
	while item.get_next_visible():
		item = item.get_next_visible()
		
		if item.get_child_count():
			continue
		
		if item.is_checked(0):
			to_be_repalced.append(item.get_metadata(0))
			if !item.get_metadata(0).timeline in affected_timelines:
				affected_timelines.append(item.get_metadata(0).timeline)
	
	replace(affected_timelines, to_be_repalced)


func replace(timelines:Array[String], replacement_info:Array[Dictionary]) -> void:
	var timeline_editor = find_parent('EditorsManager').editors['Timeline Editor'].node
	if timeline_editor.current_resource in timelines:
		find_parent('EditorsManager').clear_editor(timeline_editor)
	
	%SearchProgress.value = 0
	%SearchProgress.show()
	var max_progress := len(replacement_info)
	var progress := 0
	
	for timeline_path in timelines:
		%State.text = "Loading '"+timeline_path+"'"
		
		var timeline_file := FileAccess.open(timeline_path, FileAccess.READ_WRITE)
		var timeline_text :String = timeline_file.get_as_text()
		var timeline_events := timeline_text.split('\n')
		timeline_file.close()
		
		
		var offset_correction := 0
		for replacement in replacement_info:
			if replacement.timeline != timeline_path:
				continue
			
			%State.text = "Searching '"+timeline_path+"' for "+replacement.info.what+' -> '+replacement.info.forwhat
			print("Searching '"+timeline_path+"' for "+replacement.info.what+' -> '+replacement.info.forwhat)
			
			if 'replace' in replacement.match.names:
				timeline_text = timeline_text.substr(0, replacement.match.get_start('replace')+offset_correction)+replacement.info.regex_replacement+timeline_text.substr(replacement.match.get_end()+offset_correction)
				offset_correction += len(replacement.info.regex_replacement)-len(replacement.match.get_string('replace'))
			else:
				timeline_text = timeline_text.substr(0, replacement.match.get_start()+offset_correction)+replacement.info.regex_replacement+timeline_text.substr(replacement.match.get_end()+offset_correction)
				offset_correction += len(replacement.info.regex_replacement)-len(replacement.match.get_string())
			
			replacement.info.count -= 1
			replacement.info.item.set_text(2, str(replacement.info.count))
			
			progress += 1
			%SearchProgress.value = 100.0/max_progress*progress
		
		timeline_file = FileAccess.open(timeline_path, FileAccess.WRITE)
		timeline_file.store_string(timeline_text)
		timeline_file.close()
	
	update_count_coloring()
	%Replace.disabled = false
	%SearchProgress.hide()
	%State.text = "Done Replacing"


func close():
	var item :TreeItem = %ChangeTree.get_root()
	while item.get_next_visible():
		item = item.get_next_visible()
		
		if item.get_child_count():
			continue
		if item.get_text(2) != "" and int(item.get_text(2)) == 0:
			reference_changes.erase(item.get_metadata(0))
			
func _on_back_pressed():
	%FindList.hide()
	%ChangeList.show()

