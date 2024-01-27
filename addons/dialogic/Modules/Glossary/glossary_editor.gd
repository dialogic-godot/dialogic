@tool
extends DialogicEditor

var current_glossary: DialogicGlossary = null
var current_entry_name := ""

################################################################################
##					BASICS
################################################################################

func _get_title() -> String:
	return "Glossary"


func _get_icon() -> Texture:
	var base_directory: String = self.get_script().get_path().get_base_dir()
	var icon_path := base_directory + "/icon.svg"
	return load(icon_path)


func _register() -> void:
	editors_manager.register_simple_editor(self)
	alternative_text = "Create and edit glossaries."


func _ready() -> void:
	var add_glossary_icon_path: String = self.get_script().get_path().get_base_dir() + "/add-glossary.svg"
	var add_glossary_icon := load(add_glossary_icon_path)
	%AddGlossaryFile.icon = add_glossary_icon

	%LoadGlossaryFile.icon = get_theme_icon('Folder', 'EditorIcons')
	%DeleteGlossaryFile.icon = get_theme_icon('Remove', 'EditorIcons')
	%DeleteGlossaryEntry.icon = get_theme_icon('Remove', 'EditorIcons')

	%DeleteGlossaryFile.pressed.connect(_on_delete_glossary_file_pressed)

	%AddGlossaryEntry.icon = get_theme_icon('Add', 'EditorIcons')
	%EntrySearch.right_icon = get_theme_icon('Search', 'EditorIcons')

	%GlossaryList.item_selected.connect(_on_GlossaryList_item_selected)
	%EntryList.item_selected.connect(_on_EntryList_item_selected)

	%DefaultColor.color_changed.connect(set_setting.bind('dialogic/glossary/default_color'))
	%DefaultCaseSensitive.toggled.connect(set_setting.bind('dialogic/glossary/default_case_sensitive'))

	%EntryCaseSensitive.icon = get_theme_icon("MatchCase", "EditorIcons")


func set_setting(value: Variant, setting: String)  -> void:
	ProjectSettings.set_setting(setting, value)
	ProjectSettings.save()


func _open(_argument: Variant = null) -> void:
	%DefaultColor.color = ProjectSettings.get_setting('dialogic/glossary/default_color', Color.POWDER_BLUE)
	%DefaultCaseSensitive.button_pressed = ProjectSettings.get_setting('dialogic/glossary/default_case_sensitive', true)

	%GlossaryList.clear()
	var idx := 0
	for file: String in ProjectSettings.get_setting('dialogic/glossary/glossary_files', []):

		if FileAccess.file_exists(file):
			%GlossaryList.add_item(DialogicUtil.pretty_name(file), get_theme_icon('FileList', 'EditorIcons'))
		else:
			%GlossaryList.add_item(DialogicUtil.pretty_name(file), get_theme_icon('FileDead', 'EditorIcons'))

		%GlossaryList.set_item_tooltip(idx, file)
		idx += 1

	%EntryList.clear()

	if %GlossaryList.item_count != 0:
		%GlossaryList.select(0)
		_on_GlossaryList_item_selected(0)
	else:
		current_glossary = null
		hide_entry_editor()

################################################################################
##					GLOSSARY LIST
################################################################################
func _on_GlossaryList_item_selected(idx: int) -> void:
	%EntryList.clear()
	var tooltip_item: String = %GlossaryList.get_item_tooltip(idx)

	if FileAccess.file_exists(tooltip_item):
		var glossary_item := load(tooltip_item)

		if not glossary_item is DialogicGlossary:
			return

		current_glossary = load(tooltip_item)

		if not current_glossary is DialogicGlossary:
			return

		var entry_idx := 0

		for entry_key: String in current_glossary.entries.keys():
			var entry: Variant = current_glossary.entries.get(entry_key)

			if entry is String:
				continue

			# Older glossary entries may not have the name property and the
			# alternatives may not be set up as alias entries.
			if not entry.has(DialogicGlossary.NAME_PROPERTY):
				entry[DialogicGlossary.NAME_PROPERTY] = entry_key
				var alternatives: String = entry.get(DialogicGlossary.ALTERNATIVE_PROPERTY, "")
				_on_entry_alternatives_text_changed(alternatives)
				ResourceSaver.save(current_glossary)

			%EntryList.add_item(entry.get(DialogicGlossary.NAME_PROPERTY, str(DialogicGlossary.NAME_PROPERTY)), get_theme_icon("Breakpoint", "EditorIcons"))
			var modulate_color: Color = entry.get('color', %DefaultColor.color)
			%EntryList.set_item_metadata(entry_idx, entry)
			%EntryList.set_item_icon_modulate(entry_idx, modulate_color)
			entry_idx += 1

	if %EntryList.item_count != 0:
		%EntryList.select(0)
		_on_EntryList_item_selected(0)
	else:
		hide_entry_editor()


func _on_add_glossary_file_pressed() -> void:
	find_parent('EditorView').godot_file_dialog(create_new_glossary_file, '*.tres', EditorFileDialog.FILE_MODE_SAVE_FILE, 'Create new glossary resource')


func create_new_glossary_file(path:String) -> void:
	var glossary := DialogicGlossary.new()
	glossary.resource_path = path
	ResourceSaver.save(glossary, path)
	load_glossary_file(path)


func _on_load_glossary_file_pressed() -> void:
	find_parent('EditorView').godot_file_dialog(load_glossary_file, '*.tres', EditorFileDialog.FILE_MODE_OPEN_FILE, 'Select glossary resource')


func load_glossary_file(path:String) -> void:
	var list :Array= ProjectSettings.get_setting('dialogic/glossary/glossary_files', [])

	if not path in list:
		list.append(path)
		ProjectSettings.set_setting('dialogic/glossary/glossary_files', list)
		ProjectSettings.save()
		%GlossaryList.add_item(DialogicUtil.pretty_name(path), get_theme_icon('FileList', 'EditorIcons'))

		var selected_item_index: int = %GlossaryList.item_count - 1

		%GlossaryList.set_item_tooltip(selected_item_index, path)
		%GlossaryList.select(selected_item_index)
		_on_GlossaryList_item_selected(selected_item_index)


func _on_delete_glossary_file_pressed() -> void:
	var selected_items: PackedInt32Array = %GlossaryList.get_selected_items()

	if not selected_items.is_empty():
		var list: Array = ProjectSettings.get_setting('dialogic/glossary/glossary_files', [])
		var selected_item_index := selected_items[0]
		list.remove_at(selected_item_index)

		ProjectSettings.set_setting('dialogic/glossary/glossary_files', list)
		ProjectSettings.save()

		_open()


################################################################################
##					ENTRY LIST
################################################################################
func _on_EntryList_item_selected(idx:int) -> void:
	current_entry_name = %EntryList.get_item_text(idx)
	var entry_info: Dictionary = current_glossary.get_entry(current_entry_name)

	%EntrySettings.show()
	%EntryName.text = current_entry_name
	%EntryCaseSensitive.button_pressed = entry_info.get('case_sensitive', %DefaultCaseSensitive.button_pressed)

	var alternative_property: Array = entry_info.get(DialogicGlossary.ALTERNATIVE_PROPERTY, [])
	var alternatives := ", ".join(alternative_property)
	%EntryAlternatives.text = alternatives

	%EntryTitle.text = entry_info.get('title', '')
	%EntryText.text = entry_info.get('text', '')
	%EntryExtra.text = entry_info.get('extra', '')
	%EntryEnabled.button_pressed = entry_info.get('enabled', true)

	%EntryColor.color = entry_info.get('color', %DefaultColor.color)
	%EntryCustomColor.button_pressed = entry_info.has('color')
	%EntryColor.disabled = !entry_info.has('color')


func _on_add_glossary_entry_pressed() -> void:
	if !current_glossary:
		return

	var entry_count := current_glossary.entries.size() + 1
	var new_name := "New Entry " + str(entry_count)

	var new_glossary := {}
	new_glossary[DialogicGlossary.NAME_PROPERTY] = new_name

	current_glossary.set_entry(new_name, new_glossary)

	ResourceSaver.save(current_glossary)

	%EntryList.add_item(new_name, get_theme_icon("Breakpoint", "EditorIcons"))
	var item_count: int = %EntryList.item_count - 1

	%EntryList.set_item_metadata(item_count, new_name)
	%EntryList.set_item_icon_modulate(item_count, %DefaultColor.color)
	%EntryList.select(item_count)

	_on_EntryList_item_selected(item_count)

	%EntryList.ensure_current_is_visible()
	%EntryName.grab_focus()


func _on_delete_glossary_entry_pressed() -> void:
	var selected_items: Array = %EntryList.get_selected_items()

	if not selected_items.is_empty():
		var selected_item_index: int = selected_items[0]

		if not current_glossary == null:
			current_glossary.erase_entry(current_entry_name)
			ResourceSaver.save(current_glossary)

			%EntryList.remove_item(selected_item_index)
			var entries_count: int = %EntryList.item_count

			if entries_count > 0:
				var previous_item_index := selected_item_index - 1
				%EntryList.select(previous_item_index)



func _on_entry_search_text_changed(new_text: String) -> void:
	if new_text.is_empty() or new_text.to_lower() in %EntryList.get_item_text(%EntryList.get_selected_items()[0]).to_lower():
		return

	for i: int in %EntryList.item_count:

		if new_text.is_empty() or new_text.to_lower() in %EntryList.get_item_text(i).to_lower():
			%EntryList.select(i)
			_on_EntryList_item_selected(i)
			%EntryList.ensure_current_is_visible()


################################################################################
##					ENTRY EDITOR
################################################################################
func hide_entry_editor() -> void:
	%EntrySettings.hide()


func _update_alias_entries(old_alias_value_key: String, new_alias_value_key: String) -> void:
	for entry_key: String in current_glossary.entries.keys():

		var entry_value: Variant = current_glossary.entries.get(entry_key)

		if not entry_value is String:
			continue

		if not entry_value == old_alias_value_key:
			continue

		current_glossary.entries[entry_key] = new_alias_value_key


func _on_entry_name_text_changed(new_name: String) -> void:
	new_name = new_name.strip_edges()

	if current_entry_name != new_name:
		var selected_item: int = %EntryList.get_selected_items()[0]

		if new_name.is_empty() or new_name in current_glossary.entries.keys():
			%EntryList.set_item_custom_bg_color(selected_item,
					get_theme_color("warning_color", "Editor").darkened(0.8))
			%EntryList.set_item_text(selected_item, new_name + " (invalid name)")
			return

		else:
			%EntryList.set_item_custom_bg_color(
				selected_item,
				Color.TRANSPARENT
			)

		print_rich("[color=green]Renaming entry '" + current_entry_name + "'' to '" + new_name + "'[/color]")

		_update_alias_entries(current_entry_name, new_name)

		current_glossary.replace_entry_key(current_entry_name, new_name)


		%EntryList.set_item_text(selected_item, new_name)
		%EntryList.set_item_metadata(selected_item, new_name)
		ResourceSaver.save(current_glossary)
		current_entry_name = new_name


func _on_entry_case_sensitive_toggled(button_pressed: bool) -> void:
	current_glossary.get_entry(current_entry_name)['case_sensitive'] = button_pressed
	ResourceSaver.save(current_glossary)


## The [param new_alternatives] is a passed as a string of comma separated
## values form the Dialogic editor.
##
## Saves the glossary resource file.
func _on_entry_alternatives_text_changed(new_alternatives: String) -> void:
	var current_alternatives: Array = current_glossary.get_entry(current_entry_name).get(DialogicGlossary.ALTERNATIVE_PROPERTY, [])

	for current_alternative: String in current_alternatives:
		current_glossary.remove_entry_key(current_alternative)

	var alternatives := []

	for new_alternative: String in new_alternatives.split(',', false):
		var stripped_alternative := new_alternative.strip_edges()
		alternatives.append(stripped_alternative)
		current_glossary.add_entry_key_alias(current_entry_name, stripped_alternative)

	current_glossary.get_entry(current_entry_name)[DialogicGlossary.ALTERNATIVE_PROPERTY] = alternatives
	ResourceSaver.save(current_glossary)


func _on_entry_title_text_changed(new_text:String) -> void:
	current_glossary.get_entry(current_entry_name)['title'] = new_text
	ResourceSaver.save(current_glossary)


func _on_entry_text_text_changed() -> void:
	current_glossary.get_entry(current_entry_name)['text'] = %EntryText.text
	ResourceSaver.save(current_glossary)


func _on_entry_extra_text_changed() -> void:
	current_glossary.get_entry(current_entry_name)['extra'] = %EntryExtra.text
	ResourceSaver.save(current_glossary)


func _on_entry_enabled_toggled(button_pressed:bool) -> void:
	current_glossary.get_entry(current_entry_name)['enabled'] = button_pressed
	ResourceSaver.save(current_glossary)


func _on_entry_custom_color_toggled(button_pressed:bool) -> void:
	%EntryColor.disabled = !button_pressed

	if !button_pressed:
		current_glossary.get_entry(current_entry_name).erase('color')
		%EntryList.set_item_icon_modulate(%EntryList.get_selected_items()[0], %DefaultColor.color)
	else:
		current_glossary.get_entry(current_entry_name)['color'] = %EntryColor.color
		%EntryList.set_item_icon_modulate(%EntryList.get_selected_items()[0], %EntryColor.color)


func _on_entry_color_color_changed(color:Color) -> void:
	current_glossary.get_entry(current_entry_name)['color'] = color
	%EntryList.set_item_icon_modulate(%EntryList.get_selected_items()[0], color)
	ResourceSaver.save(current_glossary)
