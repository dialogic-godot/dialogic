@tool
extends Control

enum TranslationModes {PerProject, PerTimeline}
var loading := false
func _ready():
	%TransEnabled.toggled.connect(store_changes)
	%OrigLocale.get_suggestions_func = get_locales
	%OrigLocale.resource_icon = get_theme_icon("Translation", "EditorIcons")
	%OrigLocale.value_changed.connect(store_changes)
	%TransFolderPicker.value_changed.connect(store_changes)
	
	%UpdateCsvFiles.pressed.connect(update_csv_files)
	%CollectTranslations.pressed.connect(collect_translations)
	%TransRemove.pressed.connect(erase_translations)

func refresh():
	loading = true
	%TransEnabled.button_pressed = DialogicUtil.get_project_setting('dialogic/translation/enabled', false)
	
	%OrigLocale.set_value(DialogicUtil.get_project_setting('dialogic/translation/original_locale', TranslationServer.get_tool_locale()))
	%TransMode.select(DialogicUtil.get_project_setting('dialogic/translation/file_mode', 1))
	
	%TransFolderPicker.set_value(DialogicUtil.get_project_setting('dialogic/translation/translation_folder', ''))
	loading = false

func store_changes(fake_arg = "", fake_arg2 = ""):
	if loading: return
	ProjectSettings.set_setting('dialogic/translation/enabled', %TransEnabled.button_pressed)
	ProjectSettings.set_setting('dialogic/translation/original_locale', %OrigLocale.current_value)
	ProjectSettings.set_setting('dialogic/translation/transation_folder', %TransFolderPicker.current_value)
	ProjectSettings.set_setting('dialogic/translation/file_mode', %TransMode.selected)
	ProjectSettings.save()

func get_locales(filter:String) -> Dictionary:
	var suggestions = {}
	suggestions[TranslationServer.get_tool_locale()] = {'value':TranslationServer.get_tool_locale()}
	for locale in TranslationServer.get_all_languages():
		suggestions[locale] = {'value':locale, 'tooltip':TranslationServer.get_language_name(locale)}
	return suggestions


func update_csv_files():
	var orig_locale = %OrigLocale.current_value.strip_edges()
	if orig_locale.is_empty():
		orig_locale = ProjectSettings.get_setting('internationalization/locale/fallback')
		%OrigLocale.set_value(orig_locale)
	
	var translation_mode = %TransMode.selected
	
	var file : FileAccess
	var files : = [] # collected to trigger reimport at the end
	var csv_lines := [] # collects all current lines
	var old_csv_lines := {} # contains already existing csv_lines as [key] = [value, value, ...] dict
	
	# collect old lines in per project mode 
	if translation_mode == TranslationModes.PerProject:
		var file_path = DialogicUtil.get_project_setting('dialogic/translation/translation_folder', 'res://')+'dialogic_translations.csv'
		files.append(file_path)
		if FileAccess.file_exists(file_path):
			file = FileAccess.open(file_path,FileAccess.READ_WRITE)
			
			while !file.eof_reached():
				var line := file.get_csv_line()
				old_csv_lines[line[0]] = line.slice(1)
		csv_lines.append(['keys', orig_locale])
	
	for timeline_path in  DialogicUtil.list_resources_of_type('.dtl'):
		
		# collect old lines in per timeline mode
		var file_path = timeline_path.trim_suffix('.dtl')+'_translation.csv'
		if translation_mode == TranslationModes.PerTimeline:
			files.append(file_path)
			if FileAccess.file_exists(file_path):
				file = FileAccess.open(file_path,FileAccess.READ_WRITE)
				while !file.eof_reached():
					var line := file.get_csv_line()
					old_csv_lines[line[0]] = line.slice(1)
			csv_lines.append(['keys', orig_locale])
		
		# load and process timeline (make events to resources)
		var tml : DialogicTimeline = load(timeline_path)
		tml = find_parent('EditorView').process_timeline(tml)
		
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
		tml.events_processed = false
		ResourceSaver.save(tml, timeline_path)
		
		# for per_timeline mode save the file now, then reset for next timeline
		if translation_mode == TranslationModes.PerTimeline:
			file = FileAccess.open(file_path, FileAccess.WRITE)
			
			for line in csv_lines:
				# in case there might be translations for this line already, 
				# add them at the end again (orig locale text is replaced).
				if line[0] in old_csv_lines:
					line.append_array(old_csv_lines[line[0]].slice(2))
				file.store_csv_line(line)
			
			csv_lines.clear()
			old_csv_lines.clear()
	
	if translation_mode == TranslationModes.PerProject:
		var file_path = DialogicUtil.get_project_setting('dialogic/translation/translation_folder', 'res://')+'dialogic_translations.csv'
		file = FileAccess.open(file_path, FileAccess.WRITE)
		
		for line in csv_lines:
			# in case there might be translations for this line already, 
			# add them at the end again (orig locale text is replaced).
			if line[0] in old_csv_lines:
				file.store_csv_line(line+old_csv_lines[line[0]].slice(2))
			else:
				file.store_csv_line(line)
	
	
	## ADD CREATION/UPDATE OF CHARACTER NAMES FILE HERE!
	
	# trigger reimport
#	find_parent('EditorView').plugin_reference.editor_interface.get_resource_filesystem().reimport_files(files)
	find_parent('EditorView').plugin_reference.editor_interface.get_resource_filesystem().scan_sources()

func collect_translations():
	var trans_files := []
	var translation_mode = %TransMode.selected
	if translation_mode == TranslationModes.PerTimeline:
		for timeline_path in DialogicUtil.list_resources_of_type('.dtl'):
			for file in DialogicUtil.listdir(timeline_path.get_base_dir()):
				file = timeline_path.get_base_dir().path_join(file)
				if file.ends_with('.translation'):
					if not file in trans_files:
						trans_files.append(file)
	
	if translation_mode == TranslationModes.PerProject:
		var trans_folder = DialogicUtil.get_project_setting('dialogic/translation/translation_folder', 'res://')
		for file in DialogicUtil.listdir(trans_folder):
			file = trans_folder.path_join(file)
			if file.ends_with('.translation'):
				if not file in trans_files:
					trans_files.append(file)
	
	ProjectSettings.set_setting('internationalization/locale/translations', PackedStringArray(trans_files))
	ProjectSettings.save()

func erase_translations():
	var trans_files := Array(DialogicUtil.get_project_setting('internationalization/locale/translations', []))
	var translation_mode : int = %TransMode.selected
	
	if translation_mode == TranslationModes.PerProject:
		var trans_path :String = DialogicUtil.get_project_setting('dialogic/translation/translation_folder', 'res://')
		DirAccess.remove_absolute(trans_path+'dialogic_translations.csv')
		DirAccess.remove_absolute(trans_path+'dialogic_translations.csv.import')
		for x_file in DialogicUtil.listdir(trans_path):
			if x_file.ends_with('.translation'):
				trans_files.erase(trans_path.get_base_dir().path_join(x_file))
				DirAccess.remove_absolute(trans_path.get_base_dir().path_join(x_file))

	for timeline_path in DialogicUtil.list_resources_of_type('.dtl'):
		# in per project mode, remove all translation files/resources next to the timelines
		if translation_mode == TranslationModes.PerTimeline:
			DirAccess.remove_absolute(timeline_path.trim_suffix('.dtl')+'_translation.csv')
			DirAccess.remove_absolute(timeline_path.trim_suffix('.dtl')+'_translation.csv.import')
			for x_file in DialogicUtil.listdir(timeline_path.get_base_dir()):
				if x_file.ends_with('.translation'):
					trans_files.erase(timeline_path.get_base_dir().path_join(x_file))
					DirAccess.remove_absolute(timeline_path.get_base_dir().path_join(x_file))
		
		# clear the timeline events of their translation_id's
		var tml:DialogicTimeline = load(timeline_path)
		tml = await find_parent('EditorView').process_timeline(tml)
		for event in tml.get_events():
			if event._translation_id:
				event.remove_translation_id()
				event.update_text_version()
		tml.set_meta("timeline_not_saved", true)
		tml.events_processed = false
		ResourceSaver.save(tml, timeline_path)
	
	ProjectSettings.set_setting('dialogic/translation/id_counter', 16)
	ProjectSettings.set_setting('internationalization/locale/translations', PackedStringArray(trans_files))
	ProjectSettings.save()
	
	find_parent('EditorView').plugin_reference.editor_interface.get_resource_filesystem().scan_sources()
	
	refresh()

