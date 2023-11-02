@tool
extends DialogicSettingsPage

## Settings tab that allows enabeling and updating translation csv-files.


enum TranslationModes {PER_PROJECT, PER_TIMELINE}
var loading := false
@onready var settings_editor :Control = find_parent('Settings')


func _get_icon():
	return get_theme_icon("Translation", "EditorIcons")

func _get_info_section() -> Control:
	return $InfoSection

func _is_feature_tab() -> bool:
	return true


func _ready() -> void:
	%TransEnabled.toggled.connect(store_changes)
	%OrigLocale.get_suggestions_func = get_locales
	%OrigLocale.resource_icon = get_theme_icon("Translation", "EditorIcons")
	%OrigLocale.value_changed.connect(store_changes)
	%TestingLocale.get_suggestions_func = get_locales
	%TestingLocale.resource_icon = get_theme_icon("Translation", "EditorIcons")
	%TestingLocale.value_changed.connect(store_changes)
	%TransFolderPicker.value_changed.connect(store_changes)

	%UpdateCsvFiles.pressed.connect(update_csv_files)
	%CollectTranslations.pressed.connect(collect_translations)
	%TransRemove.pressed.connect(_on_erase_translations_pressed)



func _refresh() -> void:
	loading = true
	%TransEnabled.button_pressed = ProjectSettings.get_setting('dialogic/translation/enabled', false)
	%TranslationSettings.visible = %TransEnabled.button_pressed
	%OrigLocale.set_value(ProjectSettings.get_setting('dialogic/translation/original_locale', TranslationServer.get_tool_locale()))
	%TransMode.select(ProjectSettings.get_setting('dialogic/translation/file_mode', 1))
	%TransFolderPicker.set_value(ProjectSettings.get_setting('dialogic/translation/translation_folder', ''))
	%TestingLocale.set_value(ProjectSettings.get_setting('internationalization/locale/test', ''))
	loading = false


func store_changes(fake_arg = "", fake_arg2 = "") -> void:
	if loading: return
	ProjectSettings.set_setting('dialogic/translation/enabled', %TransEnabled.button_pressed)
	%TranslationSettings.visible = %TransEnabled.button_pressed
	ProjectSettings.set_setting('dialogic/translation/original_locale', %OrigLocale.current_value)
	ProjectSettings.set_setting('dialogic/translation/file_mode', %TransMode.selected)
	ProjectSettings.set_setting('dialogic/translation/translation_folder', %TransFolderPicker.current_value)
	ProjectSettings.set_setting('internationalization/locale/test', %TestingLocale.current_value)
	ProjectSettings.save()


func get_locales(filter:String) -> Dictionary:
	var suggestions := {}
	suggestions['Default'] = {'value':'', 'tooltip':"Will use the fallback locale set in the project settings."}
	suggestions[TranslationServer.get_tool_locale()] = {'value':TranslationServer.get_tool_locale()}
	for locale in TranslationServer.get_all_languages():
		suggestions[locale] = {'value':locale, 'tooltip':TranslationServer.get_language_name(locale)}
	return suggestions



func update_csv_files() -> void:
	var orig_locale: String = %OrigLocale.current_value.strip_edges()

	if orig_locale.is_empty():
		orig_locale = ProjectSettings.get_setting('internationalization/locale/fallback')
		%OrigLocale.set_value(orig_locale)

	var translation_mode: int = %TransMode.selected

	# [new events, new_timelines, updated_events, updated_timelines]
	var counts := [0,0,0,0]
	var file : FileAccess
	var csv_lines := []
	# Contains already existing csv_lines as [key] = [value, value, ...] dict
	var old_csv_lines := {}

	var csv_columns := 0

	var timeline_node: DialogicEditor = settings_editor.editors_manager.editors['Timeline']['node']
	# We will close this timeline to ensure it will properly update.
	# By saving this reference, we can open it again.
	var current_timeline := timeline_node.current_resource
	# Clean the current editor, this will also close the timeline.
	settings_editor.editors_manager.clear_editor(timeline_node)

	# Collect old lines in per project mode.
	if translation_mode == TranslationModes.PER_PROJECT:
		var file_path: String = ProjectSettings.get_setting('dialogic/translation/translation_folder', 'res://').path_join('dialogic_translations.csv')

		if FileAccess.file_exists(file_path):
			file = FileAccess.open(file_path, FileAccess.READ_WRITE)
			counts[3] += 1

			var locale_csv_row := file.get_csv_line()
			csv_columns = locale_csv_row.size()
			old_csv_lines[locale_csv_row[0]] = locale_csv_row

			while !file.eof_reached():
				var line := file.get_csv_line()
				old_csv_lines[line[0]] = line

		else:
			counts[1] += 1

		csv_lines.append(['keys', orig_locale])

	for timeline_path in DialogicUtil.list_resources_of_type('.dtl'):
		var file_path: String = timeline_path.trim_suffix('.dtl')+'_translation.csv'

		# Collect old lines in per timeline mode.
		if translation_mode == TranslationModes.PER_TIMELINE:

			if FileAccess.file_exists(file_path):
				file = FileAccess.open(file_path, FileAccess.READ_WRITE)

				var locale_csv_row := file.get_csv_line()
				csv_columns = locale_csv_row.size()
				old_csv_lines[locale_csv_row[0]] = locale_csv_row

				while !file.eof_reached():
					var line := file.get_csv_line()
					old_csv_lines[line[0]] = line

			csv_lines.append(['keys', orig_locale])

		# load and process timeline (make events to resources)
		var tml : DialogicTimeline = load(timeline_path)
		await tml.process()

		# now collect all the current csv_lines from timeline
		for event in tml.events:

			if event.can_be_translated():

				if event._translation_id.is_empty():
					event.add_translation_id()
					event.update_text_version()

				for property in event._get_translatable_properties():
					csv_lines.append([event.get_property_translation_key(property), event._get_property_original_translation(property)])

		# in case new translation_id's were added, we save the timeline again
		tml.set_meta("timeline_not_saved", true)
		ResourceSaver.save(tml, timeline_path)

		# for per_timeline mode save the file now, then reset for next timeline
		if translation_mode == TranslationModes.PER_TIMELINE:
			if !FileAccess.file_exists(file_path):
				pass#counts[1] += 1

			elif len(csv_lines):
				counts[3] += 1

			file = FileAccess.open(file_path, FileAccess.WRITE)

			for line in csv_lines:

				# In case there might be translations for this line already,
				# add them at the end again (orig locale text is replaced).
				if line[0] in old_csv_lines:
					var old_line = old_csv_lines[line[0]]
					var updated_line: PackedStringArray = line + Array(old_line).slice(2)

					var line_columns: int = updated_line.size()
					var line_columns_to_add := csv_columns - line_columns

					# Add trailing commas to match the amount of columns.
					for _i in range(line_columns_to_add):
						updated_line.append("")

					file.store_csv_line(updated_line)
					counts[2] += 1

				else:
					var line_columns: int = line.size()
					var line_columns_to_add := csv_columns - line_columns

					# Add trailing commas to match the amount of columns.
					for _i in range(line_columns_to_add):
						line.append("")


					file.store_csv_line(line)
					counts[0] += 1

			csv_lines.clear()
			old_csv_lines.clear()

	if translation_mode == TranslationModes.PER_PROJECT:
		var file_path: String = ProjectSettings.get_setting('dialogic/translation/translation_folder', 'res://').path_join('dialogic_translations.csv')

		if FileAccess.file_exists(file_path):
			counts[3] += 1
		else:
			counts[1] += 1

		file = FileAccess.open(file_path, FileAccess.WRITE)

		for line in csv_lines:
			# in case there might be translations for this line already,
			# add them at the end again (orig locale text is replaced).
			if line[0] in old_csv_lines:
				var old_line: PackedStringArray = old_csv_lines[line[0]]
				var updated_line: PackedStringArray = PackedStringArray(line)+old_line.slice(2)

				var line_columns: int = updated_line.size()
				var line_columns_to_add := csv_columns - line_columns

				# Add trailing commas to match the amount of columns.
				for _i in range(line_columns_to_add):
					updated_line.append("")

				file.store_csv_line(updated_line)
				counts[2] += 1

			else:
				var line_columns: int = line.size()
				var line_columns_to_add := csv_columns - line_columns

				# Add trailing commas to match the amount of columns.
				for _i in range(line_columns_to_add):
					line.append("")

				file.store_csv_line(line)
				counts[0] += 1

	## ADD CREATION/UPDATE OF CHARACTER NAMES FILE HERE!

	# Silently open the closed timeline.
	settings_editor.editors_manager.edit_resource(current_timeline, true, true)

	# Trigger reimport.
	find_parent('EditorView').plugin_reference.get_editor_interface().get_resource_filesystem().scan_sources()
	%StatusMessage.text = "Indexed " +str(counts[0])+ " new events ("+str(counts[2])+" were updated). \nAdded "+str(counts[1])+" new csv files ("+str(counts[3])+" were updated)."


func collect_translations() -> void:
	var trans_files := []
	var translation_mode: int = %TransMode.selected

	if translation_mode == TranslationModes.PER_TIMELINE:
		for timeline_path in DialogicUtil.list_resources_of_type('.dtl'):
			for file in DialogicUtil.listdir(timeline_path.get_base_dir()):
				file = timeline_path.get_base_dir().path_join(file)
				if file.ends_with('.translation'):
					if not file in trans_files:
						trans_files.append(file)

	if translation_mode == TranslationModes.PER_PROJECT:
		var trans_folder :String = ProjectSettings.get_setting('dialogic/translation/translation_folder', 'res://')
		for file in DialogicUtil.listdir(trans_folder):
			file = trans_folder.path_join(file)
			if file.ends_with('.translation'):
				if not file in trans_files:
					trans_files.append(file)

	var all_trans_files : Array = ProjectSettings.get_setting('internationalization/locale/translations', [])
	var orig_file_amount := len(all_trans_files)
	for file in trans_files:
		if not file in all_trans_files:
			all_trans_files.append(file)

	ProjectSettings.set_setting('internationalization/locale/translations', PackedStringArray(all_trans_files))
	ProjectSettings.save()

	%StatusMessage.text = "Collected "+str(len(all_trans_files)-orig_file_amount) + " new translation files."


func _on_erase_translations_pressed():
	$EraseConfirmationDialog.popup_centered()


func erase_translations() -> void:
	var trans_files := Array(ProjectSettings.get_setting('internationalization/locale/translations', []))
	var translation_mode : int = %TransMode.selected

	var counts := [0,0] # csv files, translation files

	if translation_mode == TranslationModes.PER_PROJECT:
		var trans_path :String = ProjectSettings.get_setting('dialogic/translation/translation_folder', 'res://')
		DirAccess.remove_absolute(trans_path+'dialogic_translations.csv')
		DirAccess.remove_absolute(trans_path+'dialogic_translations.csv.import')
		counts[0] += 1
		for x_file in DialogicUtil.listdir(trans_path):
			if x_file.ends_with('.translation'):
				trans_files.erase(trans_path.get_base_dir().path_join(x_file))
				DirAccess.remove_absolute(trans_path.get_base_dir().path_join(x_file))
				counts[1] += 1

	for timeline_path in DialogicUtil.list_resources_of_type('.dtl'):
		# in per project mode, remove all translation files/resources next to the timelines
		if translation_mode == TranslationModes.PER_TIMELINE:
			DirAccess.remove_absolute(timeline_path.trim_suffix('.dtl')+'_translation.csv')
			DirAccess.remove_absolute(timeline_path.trim_suffix('.dtl')+'_translation.csv.import')
			counts[0] += 1
			for x_file in DialogicUtil.listdir(timeline_path.get_base_dir()):
				if x_file.ends_with('.translation'):
					trans_files.erase(timeline_path.get_base_dir().path_join(x_file))
					DirAccess.remove_absolute(timeline_path.get_base_dir().path_join(x_file))
					counts[1] += 1

		# clear the timeline events of their translation_id's
		var tml:DialogicTimeline = load(timeline_path)
		await tml.process()

		for event in tml.events:
			if event._translation_id:
				event.remove_translation_id()
				event.update_text_version()

		tml.set_meta("timeline_not_saved", true)
		ResourceSaver.save(tml, timeline_path)

	ProjectSettings.set_setting('dialogic/translation/id_counter', 16)
	ProjectSettings.set_setting('internationalization/locale/translations', PackedStringArray(trans_files))
	ProjectSettings.save()

	find_parent('EditorView').plugin_reference.get_editor_interface().get_resource_filesystem().scan_sources()

	%StatusMessage.text = "Removed "+str(counts[0])+" csv files, "+str(counts[1])+" translations and all translation id's."
	_refresh()

