@tool
extends VBoxContainer

var current_glossary = null
var current_entry_name = ""

func _ready():
	%AddGlossaryFile.icon = get_theme_icon('Add', 'EditorIcons')
	%LoadGlossaryFile.icon = get_theme_icon('Folder', 'EditorIcons')
	%DeleteGlossaryFile.icon = get_theme_icon('Remove', 'EditorIcons')
	%DeleteGlossaryEntry.icon = get_theme_icon('Remove', 'EditorIcons')
	
	%AddGlossaryEntry.icon = get_theme_icon('Add', 'EditorIcons')
	
	%GlossaryList.item_selected.connect(_on_GlossaryList_item_selected)
	%EntryList.item_selected.connect(_on_EntryList_item_selected)
	
	%DefaultColor.color_changed.connect(set_setting.bind('dialogic/glossary/default_color'))
	%DefaultCaseSensitive.toggled.connect(set_setting.bind('dialogic/glossary/default_case_sensitive'))

func set_setting(value, setting):
	ProjectSettings.set_setting(setting, value)

func refresh():
	%DefaultColor.color = DialogicUtil.get_project_setting('dialogic/glossary/default_color', Color.POWDER_BLUE)
	
	%DefaultCaseSensitive.button_pressed = DialogicUtil.get_project_setting('dialogic/glossary/default_case_sensitive', true)
	
	
	%GlossaryList.clear()
	var idx = 0
	for file in DialogicUtil.get_project_setting('dialogic/glossary/glossary_files', []):
		if Directory.new().file_exists(file):
			%GlossaryList.add_item(DialogicUtil.pretty_name(file), get_theme_icon('FileList', 'EditorIcons'))
		else:
			%GlossaryList.add_item(DialogicUtil.pretty_name(file), get_theme_icon('FileDead', 'EditorIcons'))
			
		%GlossaryList.set_item_tooltip(idx, file)
		idx += 1
	
	if %GlossaryList.item_count != 0:
		%GlossaryList.select(0)
		_on_GlossaryList_item_selected(0)

func _on_GlossaryList_item_selected(idx):
	%EntryList.clear()
	if Directory.new().file_exists(%GlossaryList.get_item_tooltip(idx)):
		current_glossary = load(%GlossaryList.get_item_tooltip(idx))
		if not current_glossary is DialogicGlossary:
			return
		
		for entry in current_glossary.entries:
			%EntryList.add_item(entry)
	
	if %EntryList.item_count != 0:
		%EntryList.select(0)
		_on_EntryList_item_selected(0)
	else:
		hide_entry_editor()

func _on_EntryList_item_selected(idx):
	current_entry_name = %EntryList.get_item_text(idx)
	var entry_info = current_glossary.entries[current_entry_name]
	%EntryEditorTitle.text = "Edit entry"
	%EntrySettings.show()
	%EntryName.text = current_entry_name
	%EntryCaseSensitive.button_pressed = entry_info.get('case_sensitive', %DefaultCaseSensitive.button_pressed)
	var alts = ""
	for i in entry_info.get('alternatives', []):
		alts += i+", "
	%EntryAlternatives.text = alts
	%EntryTitle.text = entry_info.get('title', '')
	%EntryText.text = entry_info.get('text', '')
	%EntryExtra.text = entry_info.get('extra', '')
	%EntryEnabled.button_pressed = entry_info.get('enabled', true)
	
	%EntryColor.color = entry_info.get('color', %DefaultColor.color)
	%EntryCustomColor.button_pressed = entry_info.has('color')
	%EntryColor.disabled = !entry_info.has('color')

func hide_entry_editor():
	%EntrySettings.hide()
	%EntryEditorTitle.text = "No entry selected."


func _on_add_glossary_file_pressed():
	find_parent('EditorView').godot_file_dialog(create_new_glossary_file, '*.tres', EditorFileDialog.FILE_MODE_SAVE_FILE, 'Create new glossary resource')


func create_new_glossary_file(path):
	var glossary = DialogicGlossary.new()
	glossary.resource_path = path
	ResourceSaver.save(glossary, path)
	load_glossary_file(path)

func _on_load_glossary_file_pressed():
	find_parent('EditorView').godot_file_dialog(load_glossary_file, '*.tres', EditorFileDialog.FILE_MODE_OPEN_FILE, 'Select glossary resource')

func load_glossary_file(path):
	var list = DialogicUtil.get_project_setting('dialogic/glossary/glossary_files', [])
	if not path in list:
		list.append(path)
		ProjectSettings.set_setting('dialogic/glossary/glossary_files', list)
		%GlossaryList.add_item(DialogicUtil.pretty_name(path), get_theme_icon('FileList', 'EditorIcons'))
		%GlossaryList.set_item_tooltip(%GlossaryList.item_count-1, path)
		%GlossaryList.select(%GlossaryList.item_count-1)


func _on_add_glossary_entry_pressed():
	if !current_glossary:
		return
	
	var new_name = "New Entry"
	if new_name in current_glossary.entries:
		var count = 2
		while new_name + " " +str(count) in current_glossary.entries:
			count += 1
		new_name += " " + str(count)
	current_glossary.entries[new_name] = {}
	ResourceSaver.save(current_glossary)
	%EntryList.add_item(new_name)
	_on_EntryList_item_selected(%EntryList.item_count-1)


func _on_delete_glossary_file_pressed():
	if len(%GlossaryList.get_selected_items()) != 0:
		var list = DialogicUtil.get_project_setting('dialogic/glossary/glossary_files', [])
		list.erase(%GlossaryList.get_item_tooltip(
			%GlossaryList.get_selected_items()[0]))
		ProjectSettings.set_setting('dialogic/glossary/glossary_files', list)
		refresh()

func _on_delete_glossary_entry_pressed():
	if len(%EntryList.get_selected_items()) != 0:
		if current_glossary:
			current_glossary.entries.erase(%EntryList.get_item_text(
			%EntryList.get_selected_items()[0]))
		%EntryList.remove_item(%EntryList.get_selected_items()[0])


func _on_entry_name_text_submitted(new_text):
	if current_entry_name != new_text.strip_edges():
		var info = current_glossary.entries[current_entry_name]
		current_glossary.entries.erase(current_entry_name)
		current_glossary.entries[new_text.strip_edges()] = info
		%EntryList.set_item_text(%EntryList.get_selected_items()[0], new_text.strip_edges())
		current_entry_name = new_text.strip_edges()
	ResourceSaver.save(current_glossary)
	
func _on_entry_case_sensitive_toggled(button_pressed):
	current_glossary.entries[current_entry_name]['case_sensitive'] = button_pressed
	ResourceSaver.save(current_glossary)

func _on_entry_alternatives_text_changed(new_text):
	var alts = []
	for i in new_text.split(',', false):
		alts.append(i.strip_edges())
	current_glossary.entries[current_entry_name]['alternatives'] = alts
	ResourceSaver.save(current_glossary)


func _on_entry_title_text_changed(new_text):
	current_glossary.entries[current_entry_name]['title'] = new_text
	ResourceSaver.save(current_glossary)


func _on_entry_text_text_changed():
	current_glossary.entries[current_entry_name]['text'] = %EntryText.text
	ResourceSaver.save(current_glossary)


func _on_entry_extra_text_changed():
	current_glossary.entries[current_entry_name]['extra'] = %EntryExtra.text
	ResourceSaver.save(current_glossary)


func _on_entry_enabled_toggled(button_pressed):
	current_glossary.entries[current_entry_name]['enabled'] = button_pressed
	ResourceSaver.save(current_glossary)

func _on_entry_custom_color_toggled(button_pressed):
	%EntryColor.disabled = !button_pressed
	if !button_pressed:
		current_glossary.entries[current_entry_name].erase('color')
	else:
		current_glossary.entries[current_entry_name]['color'] = %EntryColor.color

func _on_entry_color_color_changed(color):
	current_glossary.entries[current_entry_name]['color'] = color
	ResourceSaver.save(current_glossary)
