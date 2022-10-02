@tool
extends Control


func _ready():
	%TransEnabled.toggled.connect(set_project_setting.bind('dialogic/translation_enabled'))
	%TransFileFolder.text_changed.connect(set_project_setting.bind('dialogic/translation_path'))
	%TransFileFolderChanger.button_up.connect(open_file_folder_dialog)


func set_project_setting(value, setting):
	ProjectSettings.set_setting(setting, value)
	ProjectSettings.save()
	
	refresh()

func refresh():
	# update language selector
	%TransOrigLanguage.text = TranslationServer.get_locale()
	%TransFileMode.select(0)
	
	
	%TransEnabled.button_pressed = DialogicUtil.get_project_setting('dialogic/translation_enabled', false)
	
	if %TransEnabled.button_pressed:
		if DialogicUtil.get_project_setting('dialogic/translation_path', ''):
			%TransFileFolder.editable = true
			%TransFileFolder.text = DialogicUtil.get_project_setting('dialogic/translation_path', '')
			%TransFileFolderChanger.disabled = false
		else:
			%TransFileFolder.editable = false
			%TransFileFolder.text = "Next to timeline"
			%TransFileFolderChanger.disabled = true
	
	%TransFileFolderChanger.icon = get_theme_icon("Folder", "EditorIcons")
	%TransOrigLanguage.editable = !%TransEnabled.button_pressed
	%TransFileMode.disabled = %TransEnabled.button_pressed
	%TransInitialize.disabled = %TransEnabled.button_pressed
	%TransFileFolder.editable = %TransEnabled.button_pressed
	%TransFileFolderChanger.disabled = !%TransEnabled.button_pressed
	%TransRemove.disabled = !%TransEnabled.button_pressed
	%TransUpdate.disabled = !%TransEnabled.button_pressed

func open_file_folder_dialog():
	find_parent('EditorView').godot_file_dialog(file_folder_selected, '*.po, *.csv', EditorFileDialog.FILE_MODE_OPEN_ANY, 'Select folder or translation file')

func file_folder_selected(path):
	%TransFileFolder.text = path
	ProjectSettings.set_setting('dialogic/translation_path', path)
	ProjectSettings.save()
	refresh()


func _on_TransInitialize_pressed():
	
	if %TransOrigLanguage.text.is_empty():
		%TransOrigLanguage.text = ProjectSettings.get_setting('locale/fallback')
	var orig_locale = %TransOrigLanguage.text.strip_edges()
	
	if %TransFileMode.selected == 0:
		var file := FileAccess.open('res://dialogic_translation.csv', FileAccess.WRITE)
		ProjectSettings.set_setting('dialogic/translation_path', 'res://dialogic_translation.csv')
		file.store_csv_line(['keys', orig_locale])
	else:
		ProjectSettings.set_setting('dialogic/translation_path', '')
	ProjectSettings.save()
		
	
	for timeline_path in DialogicUtil.list_resources_of_type('.dtl'):
		var file := FileAccess.open(timeline_path.trim_suffix('.dtl')+'_translation.csv', FileAccess.WRITE)
		if %TransFileMode.selected == 1:
			file.store_csv_line(['keys', orig_locale])
		
		var tml:DialogicTimeline = load(timeline_path)
		for event in tml.get_events():
			#if event.
			if event.can_be_translated():
				file.store_csv_line([event.add_translation_id(), event.get_original_translation_text()])

		ResourceSaver.save(tml, timeline_path)
	
	ProjectSettings.set_setting('dialogic/translation_enabled', true)
	ProjectSettings.save()
	refresh()

func _on_TransRemove_pressed():
	erase_translations()

func erase_translations():
	ProjectSettings.set_setting('dialogic/translation_enabled', false)
	var trans_files = Array(ProjectSettings.get_setting('locale/translations'))
	var trans_path = DialogicUtil.get_project_setting('dialogic/translation_path', '')
	if trans_path.ends_with('.csv'):
		for x_file in DialogicUtil.listdir(trans_path.get_base_dir()):
			if x_file.ends_with('.translation'):
				trans_files.erase(trans_path.get_base_dir().path_join(x_file))
				DirAccess.remove_absolute(trans_path.get_base_dir().path_join(x_file))
		DirAccess.remove_absolute(DialogicUtil.get_project_setting('dialogic/translation_path', ''))
	
	ProjectSettings.set_setting('dialogic/translation_path', null)
	
	for timeline_path in DialogicUtil.list_resources_of_type('.dtl'):
		if trans_path == '':
			DirAccess.remove_absolute(timeline_path.trim_suffix('.dtl')+'_translation.csv')
			for x_file in DialogicUtil.listdir(timeline_path.get_base_dir()):
				if x_file.ends_with('.translation'):
					trans_files.erase(timeline_path.get_base_dir().path_join(x_file))
					DirAccess.remove_absolute(timeline_path.get_base_dir().path_join(x_file))
		
		var tml:DialogicTimeline = load(timeline_path)
		for event in tml.get_events():
			#if event.
			if event.translation_id:
				event.translation_id = null
		
		ResourceSaver.save(tml, timeline_path)

	
	ProjectSettings.set_setting('locale/translations', PackedStringArray(trans_files))
	ProjectSettings.save()
	refresh()


func _on_TransUpdate_pressed():
	# true = ONE_FILE, false = MULTI_FILE, 
	var mode = false
	if DialogicUtil.get_project_setting('dialogic/translation_path', ''):
		mode = true
	
	var trans_files = ProjectSettings.get_setting('locale/translations')
	
	for timeline_path in DialogicUtil.list_resources_of_type('.dtl'):
		var tml:DialogicTimeline = load(timeline_path)
		ResourceSaver.save(tml, timeline_path)
		
		if !mode:
			for file in DialogicUtil.listdir(timeline_path.get_base_dir()):
				file = timeline_path.get_base_dir().path_join(file)
				if file.ends_with('.translation'):
					if not file in trans_files:
						trans_files.append(file)
	
	# in ONE_FILE mode, add all the dialogic_translations to the translation_list
	if mode:
		var trans_folder = DialogicUtil.get_project_setting('dialogic/translation_path', '').get_base_dir()
		for file in DialogicUtil.listdir(trans_folder):
			file = trans_folder.path_join(file)
			if file.ends_with('.translation'):
				if not file in trans_files:
					trans_files.append(file)
	
	ProjectSettings.set_setting('locale/translations', PackedStringArray(trans_files))
	ProjectSettings.save()
