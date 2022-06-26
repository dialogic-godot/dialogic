tool
extends WindowDialog


func _ready():
	connect("about_to_show", self, 'update')
	
	get_node('%TransEnabled').connect('toggled', self, 'set_project_setting', ['dialogic/translation_enabled'])
	get_node('%TransFileFolder').connect('text_changed', self, 'set_project_setting', ['dialogic/translation_path'])
	get_node('%TransFileFolderChanger').connect('pressed', self, 'open_file_folder_dialog')
	
	if not Engine.editor_hint:
		popup()
	update()

func set_project_setting(value, setting):
	ProjectSettings.set_setting(setting, value)
	update()

func update():
	
	## TRANSLATIONS
	# update language selector
	get_node('%TransOrigLanguage').text = ProjectSettings.get_setting('locale/fallback')
	get_node('%TransFileMode').select(0)
	
	
	get_node('%TransEnabled').pressed = DialogicUtil.get_project_setting('dialogic/translation_enabled', false)
	get_node('%TransFileFolder').text = DialogicUtil.get_project_setting('dialogic/translation_path', '')
	get_node('%TransFileFolderChanger').icon = get_icon("Folder", "EditorIcons")

	get_node('%TransOrigLanguage').editable = !get_node('%TransEnabled').pressed
	get_node('%TransFileMode').disabled = get_node('%TransEnabled').pressed
	get_node('%TransInitialize').disabled = get_node('%TransEnabled').pressed
	get_node('%TransFileFolder').editable = get_node('%TransEnabled').pressed
	get_node('%TransFileFolderChanger').disabled = !get_node('%TransEnabled').pressed
	get_node('%TransRemove').disabled = !get_node('%TransEnabled').pressed

func open_file_folder_dialog():
	find_parent('EditorView').godot_file_dialog(self, 'file_folder_selected', '*.po, *.csv', EditorFileDialog.MODE_OPEN_ANY, 'Select folder or translation file')

func file_folder_selected(path):
	get_node('%TransFileFolder').text = path
	ProjectSettings.set_setting('dialogic/translation_path', path)
	update()


func _on_TransInitialize_pressed():
	
	var trans_files = ProjectSettings.get_setting('locale/translations')
	if get_node('%TransOrigLanguage').text.empty():
		get_node('%TransOrigLanguage').text = ProjectSettings.get_setting('locale/fallback')
	var orig_locale = get_node('%TransOrigLanguage').text.strip_edges()
	var file = File.new()
	
	if get_node('%TransFileMode').selected == 0:
		file.open('res://dialogic_translation.csv', File.WRITE)
		ProjectSettings.set_setting('dialogic/translation_path', 'res://dialogic_translation.csv')
		file.store_csv_line(['keys', orig_locale])
	else:
		ProjectSettings.set_setting('dialogic/translation_path', '')
		
	
	for timeline_path in DialogicUtil.list_resources_of_type('.dtl'):
		if get_node('%TransFileMode').selected == 1:
			file.open(timeline_path.trim_suffix('.dtl')+'_translation.csv', File.WRITE)
			file.store_csv_line(['keys', orig_locale])
		
		var tml:DialogicTimeline = load(timeline_path)
		for event in tml.get_events():
			#if event.
			if event.can_be_translated():
				file.store_csv_line([event.add_translation_id(), event.get_original_translation_text()])
		
		ResourceSaver.save(timeline_path, tml)
		
		if get_node('%TransFileMode').selected == 1:
			trans_files.append(file.get_path())
			file.close()
	
	if get_node('%TransFileMode').selected == 0:
		trans_files.append(file.get_path())
		file.close()
	
	
	ProjectSettings.set_setting('dialogic/translation_enabled', true)
	ProjectSettings.set_setting('locale/translations', PoolStringArray(trans_files))
	update()

func _on_TransRemove_pressed():
	erase_translations()

func erase_translations():
	ProjectSettings.set_setting('dialogic/translation_enabled', false)
	var file = File.new()
	var dir = Directory.new()
	var trans_files = Array(ProjectSettings.get_setting('locale/translations'))
	if DialogicUtil.get_project_setting('dialogic/translation_path', '').ends_with('.csv'):
		trans_files.erase(DialogicUtil.get_project_setting('dialogic/translation_path', ''))
		dir.remove(DialogicUtil.get_project_setting('dialogic/translation_path', ''))
	
	ProjectSettings.set_setting('dialogic/translation_path', null)
	
	for timeline_path in DialogicUtil.list_resources_of_type('.dtl'):
		if get_node('%TransFileMode').selected == 1:
			dir.remove(timeline_path.trim_suffix('.dtl')+'_translation.csv')
			trans_files.erase(timeline_path.trim_suffix('.dtl')+'_translation.csv')
		
		var tml:DialogicTimeline = load(timeline_path)
		for event in tml.get_events():
			#if event.
			if event.translation_id:
				event.translation_id = null
		
		ResourceSaver.save(timeline_path, tml)

	
	ProjectSettings.set_setting('locale/translations', PoolStringArray(trans_files))
	
	update()
