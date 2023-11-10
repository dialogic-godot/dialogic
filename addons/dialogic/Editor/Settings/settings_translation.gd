@tool
extends DialogicSettingsPage

## Settings tab that allows enabeling and updating translation csv-files.


enum TranslationModes {PER_PROJECT, PER_TIMELINE}
enum SaveLocationModes {INSIDE_TRANSLATION_FOLDER, NEXT_TO_TIMELINE}

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

	%SaveLocationMode.item_selected.connect(store_changes)
	%TransMode.item_selected.connect(store_changes)

	%UpdateCsvFiles.pressed.connect(update_csv_files)
	%CollectTranslations.pressed.connect(collect_translations)
	%TransRemove.pressed.connect(_on_erase_translations_pressed)

	_verify_translation_file()

func _refresh() -> void:
	loading = true

	%TransEnabled.button_pressed = ProjectSettings.get_setting('dialogic/translation/enabled', false)
	%TranslationSettings.visible = %TransEnabled.button_pressed
	%OrigLocale.set_value(ProjectSettings.get_setting('dialogic/translation/original_locale', TranslationServer.get_tool_locale()))
	%TransMode.select(ProjectSettings.get_setting('dialogic/translation/file_mode', 1))
	%TransFolderPicker.set_value(ProjectSettings.get_setting('dialogic/translation/translation_folder', ''))
	%TestingLocale.set_value(ProjectSettings.get_setting('internationalization/locale/test', ''))

	_verify_translation_file()

	loading = false


func store_changes(fake_arg = "", fake_arg2 = "") -> void:
	if loading:
		return

	_verify_translation_file()

	ProjectSettings.set_setting('dialogic/translation/enabled', %TransEnabled.button_pressed)
	%TranslationSettings.visible = %TransEnabled.button_pressed
	ProjectSettings.set_setting('dialogic/translation/original_locale', %OrigLocale.current_value)
	ProjectSettings.set_setting('dialogic/translation/file_mode', %TransMode.selected)
	ProjectSettings.set_setting('dialogic/translation/translation_folder', %TransFolderPicker.current_value)
	ProjectSettings.set_setting('internationalization/locale/test', %TestingLocale.current_value)
	ProjectSettings.set_setting('internationalization/save_mode', %SaveLocationMode.selected)
	ProjectSettings.save()

## Checks whether the translation folder path is required.
## If it is, disables the "Update CSV files" button and shows a warning.
##
## The translation folder path is required when either of the following is true:
## - The translation mode is set to "Per Project".
## - The save location mode is set to "Inside Translation Folder".
func _verify_translation_file() -> void:
	var translation_folder: String = %TransFolderPicker.current_value
	var save_location_mode: SaveLocationModes = %SaveLocationMode.selected
	var file_mode: TranslationModes = %TransMode.selected

	if file_mode == TranslationModes.PER_PROJECT:
		%SaveLocationMode.disabled = true
	else:
		%SaveLocationMode.disabled = false

	if (save_location_mode == SaveLocationModes.INSIDE_TRANSLATION_FOLDER
	or file_mode == TranslationModes.PER_PROJECT):
		var valid_translation_folder = (!translation_folder.is_empty()
			and DirAccess.dir_exists_absolute(translation_folder))

		%UpdateCsvFiles.disabled = !valid_translation_folder

		if not valid_translation_folder:
			%StatusMessage.text = "Invalid translation folder!"
		else:
			%StatusMessage.text = ""

	else:
		%StatusMessage.text = ""

func get_locales(filter:String) -> Dictionary:
	var suggestions := {}
	suggestions['Default'] = {'value':'', 'tooltip':"Will use the fallback locale set in the project settings."}
	suggestions[TranslationServer.get_tool_locale()] = {'value':TranslationServer.get_tool_locale()}
	for locale in TranslationServer.get_all_languages():
		suggestions[locale] = {'value':locale, 'tooltip':TranslationServer.get_language_name(locale)}
	return suggestions


func update_csv_files() -> void:
	var orig_locale: String = ProjectSettings.get_setting('dialogic/translation/original_locale', '').strip_edges()
	var save_location_mode: SaveLocationModes = ProjectSettings.get_setting('internationalization/save_mode', SaveLocationModes.NEXT_TO_TIMELINE)

	if orig_locale.is_empty():
		orig_locale = ProjectSettings.get_setting('internationalization/locale/fallback')

	var translation_mode: TranslationModes = ProjectSettings.get_setting('dialogic/translation/file_mode', TranslationModes.PER_PROJECT)

	# [new events, new_timelines, updated_events, updated_timelines]
	var new_events := 0
	var new_timelines := 0
	var updated_events := 0
	var updated_timelines := 0

	var timeline_node: DialogicEditor = settings_editor.editors_manager.editors['Timeline']['node']
	# We will close this timeline to ensure it will properly update.
	# By saving this reference, we can open it again.
	var current_timeline := timeline_node.current_resource
	# Clean the current editor, this will also close the timeline.
	settings_editor.editors_manager.clear_editor(timeline_node)

	var csv_per_project: DialogicCsvFile = null

	# Collect old lines from the Per Project CSV.
	if translation_mode == TranslationModes.PER_PROJECT:
		var file_path: String = ProjectSettings.get_setting('dialogic/translation/translation_folder', 'res://').path_join('dialogic_translations.csv')

		csv_per_project = DialogicCsvFile.new(file_path, orig_locale)

		if (csv_per_project.is_new_file):
			new_timelines += 1
		else:
			updated_timelines += 1

	# Iterate over all timelines.
	# Swap CSV file.
	# Transform the timeline into translatable lines and collect into the CSV file.
	for timeline_path in DialogicUtil.list_resources_of_type('.dtl'):
		var csv_file: DialogicCsvFile = csv_per_project

		# Swap the CSV file to the Per Timeline one.
		if translation_mode == TranslationModes.PER_TIMELINE:
			var file_path: String = timeline_path.trim_suffix('.dtl')

			if save_location_mode == SaveLocationModes.INSIDE_TRANSLATION_FOLDER:
				var path_parts := file_path.split("/")
				var timeline_name: String = path_parts[-1]
				var translation_folder: String = ProjectSettings.get_setting('dialogic/translation/translation_folder', 'res://')

				file_path = translation_folder.path_join(timeline_name)

			file_path += '_translation.csv'
			csv_file = DialogicCsvFile.new(file_path, orig_locale)

			if csv_file.is_new_file:
				new_timelines += 1
			else:
				updated_timelines += 1

		# Load and process timeline, turn events into resources.
		var timeline: DialogicTimeline = load(timeline_path)
		await timeline.process()

		# Collect timeline into CSV.
		csv_file.collect_lines_from_timeline(timeline)

		# in case new translation_id's were added, we save the timeline again
		timeline.set_meta("timeline_not_saved", true)
		ResourceSaver.save(timeline, timeline_path)

		csv_file.update_csv_file_on_disk()

		new_events += csv_file.new_events
		updated_events += csv_file.updated_events

	## ADD CREATION/UPDATE OF CHARACTER NAMES FILE HERE!

	# Silently open the closed timeline.
	# May be null, if no timeline was open.
	if current_timeline != null:
		settings_editor.editors_manager.edit_resource(current_timeline, true, true)

	# Trigger reimport.
	find_parent('EditorView').plugin_reference.get_editor_interface().get_resource_filesystem().scan_sources()
	%StatusMessage.text = ("Indexed " + str(new_events)
		+ " new events ("+ str(updated_events) + " were updated).\n
		Added " + str(new_timelines)+ " new CSV files ("
		+ str(updated_timelines) + " were updated).")


func collect_translations() -> void:
	var translation_files := []
	var translation_mode: TranslationModes = ProjectSettings.get_setting('dialogic/translation/file_mode', TranslationModes.PER_PROJECT)

	if translation_mode == TranslationModes.PER_TIMELINE:

		for timeline_path in DialogicUtil.list_resources_of_type('.translation'):

			for file in DialogicUtil.listdir(timeline_path.get_base_dir()):
				file = timeline_path.get_base_dir().path_join(file)

				if file.ends_with('.translation'):

					if not file in translation_files:
						translation_files.append(file)

	if translation_mode == TranslationModes.PER_PROJECT:
		var translation_folder: String = ProjectSettings.get_setting('dialogic/translation/translation_folder', 'res://')

		for file in DialogicUtil.listdir(translation_folder):
			file = translation_folder.path_join(file)

			if file.ends_with('.translation'):

				if not file in translation_files:
					translation_files.append(file)

	var all_translation_files: Array = ProjectSettings.get_setting('internationalization/locale/translations', [])
	var orig_file_amount := len(all_translation_files)

	# This array keeps track of valid translation file paths.
	var found_file_paths := []
	var removed_translation_files := 0

	for file_path in translation_files:
		# If the file path is not valid, we must clean it up.
		if FileAccess.file_exists(file_path):
			found_file_paths.append(file_path)
		else:
			removed_translation_files += 1
			continue

		if not file_path in all_translation_files:
			all_translation_files.append(file_path)

	var valid_translation_files := PackedStringArray(all_translation_files)
	ProjectSettings.set_setting('internationalization/locale/translations', valid_translation_files)
	ProjectSettings.save()

	%StatusMessage.text = (
		"Added translation files: " + str(len(all_translation_files)-orig_file_amount)
		+ "\nRemoved translation files: " + str(removed_translation_files)
		+ "\nTotal translation files: " + str(len(all_translation_files)))


func _on_erase_translations_pressed() -> void:
	$EraseConfirmationDialog.popup_centered()


func erase_translations() -> void:
	var trans_files := Array(ProjectSettings.get_setting('internationalization/locale/translations', []))
	var translation_mode : int = %TransMode.selected

	var deleted_csv_files := 0
	var deleted_translation_files := 0

	if translation_mode == TranslationModes.PER_PROJECT:
		var trans_path :String = ProjectSettings.get_setting('dialogic/translation/translation_folder', 'res://')
		DirAccess.remove_absolute(trans_path+'dialogic_translations.csv')
		DirAccess.remove_absolute(trans_path+'dialogic_translations.csv.import')
		deleted_csv_files += 1

		for x_file in DialogicUtil.listdir(trans_path):
			if x_file.ends_with('.translation'):
				trans_files.erase(trans_path.get_base_dir().path_join(x_file))
				DirAccess.remove_absolute(trans_path.get_base_dir().path_join(x_file))
				deleted_translation_files += 1

	for timeline_path in DialogicUtil.list_resources_of_type('.dtl'):
		# in per project mode, remove all translation files/resources next to the timelines
		if translation_mode == TranslationModes.PER_TIMELINE:
			DirAccess.remove_absolute(timeline_path.trim_suffix('.dtl')+'_translation.csv')
			DirAccess.remove_absolute(timeline_path.trim_suffix('.dtl')+'_translation.csv.import')
			deleted_csv_files += 1

			for x_file in DialogicUtil.listdir(timeline_path.get_base_dir()):

				if x_file.ends_with('.translation'):
					trans_files.erase(timeline_path.get_base_dir().path_join(x_file))
					DirAccess.remove_absolute(timeline_path.get_base_dir().path_join(x_file))
					deleted_translation_files += 1

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

	%StatusMessage.text = ("Erased " +str(deleted_csv_files)+ " CSV files, "
		+ str(deleted_translation_files) + " translations and all translation ID's.")
	_refresh()

