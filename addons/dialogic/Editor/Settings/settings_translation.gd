@tool
extends DialogicSettingsPage

## Settings tab that allows enabeling and updating translation csv-files.


enum TranslationModes {PER_PROJECT, PER_TIMELINE, NONE}
enum SaveLocationModes {INSIDE_TRANSLATION_FOLDER, NEXT_TO_TIMELINE, NONE}

var loading := false
@onready var settings_editor :Control = find_parent('Settings')

## The default CSV filename that contains the translations for character
## properties.
const DEFAULT_CHARACTER_CSV_NAME := "dialogic_character_translations.csv"
## The default CSV filename that contains the translations for timelines.
## Only used when all timelines are supposed to be translated in one file.
const DEFAULT_TIMELINE_CSV_NAME := "dialogic_timeline_translations.csv"


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

	%UpdateCsvFiles.pressed.connect(_on_update_translations_pressed)
	%UpdateCsvFiles.icon = get_theme_icon("Add", "EditorIcons")

	%CollectTranslations.pressed.connect(collect_translations)
	%CollectTranslations.icon = get_theme_icon("File", "EditorIcons")

	%TransRemove.pressed.connect(_on_erase_translations_pressed)
	%TransRemove.icon = get_theme_icon("Remove", "EditorIcons")

	%UpdateConfirmationDialog.add_button("Keep old & Generate new", false, "generate_new")

	%UpdateConfirmationDialog.custom_action.connect(_on_custom_action)

	_verify_translation_file()


func _on_custom_action(action: String) -> void:
	if action == "generate_new":
		update_csv_files()


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
	ProjectSettings.set_setting('dialogic/translation/save_mode', %SaveLocationMode.selected)
	ProjectSettings.save()

## Checks whether the translation folder path is required.
## If it is, disables the "Update CSV files" button and shows a warning.
##
## The translation folder path is required when either of the following is true:
## - The translation mode is set to "Per Project".
## - The save location mode is set to "Inside Translation Folder".
func _verify_translation_file() -> void:
	var translation_folder: String = %TransFolderPicker.current_value
	var file_mode: TranslationModes = %TransMode.selected

	if file_mode == TranslationModes.PER_PROJECT:
		%SaveLocationMode.disabled = true
	else:
		%SaveLocationMode.disabled = false

	var valid_translation_folder := (!translation_folder.is_empty()
		and DirAccess.dir_exists_absolute(translation_folder))

	%UpdateCsvFiles.disabled = not valid_translation_folder

	var status_message := ""

	if not valid_translation_folder:
		status_message += "⛔ Requires valid translation folder to translate character names"

		if file_mode == TranslationModes.PER_PROJECT:
			status_message += " and the project CSV file."
		else:
			status_message += "."

	%StatusMessage.text = status_message


func get_locales(filter:String) -> Dictionary:
	var suggestions := {}
	suggestions['Default'] = {'value':'', 'tooltip':"Will use the fallback locale set in the project settings."}
	suggestions[TranslationServer.get_tool_locale()] = {'value':TranslationServer.get_tool_locale()}
	for locale in TranslationServer.get_all_languages():
		suggestions[locale] = {'value':locale, 'tooltip':TranslationServer.get_language_name(locale)}
	return suggestions


func _on_update_translations_pressed() -> void:
	var save_mode: SaveLocationModes = %SaveLocationMode.selected
	var file_mode: TranslationModes = %TransMode.selected
	var translation_folder: String = %TransFolderPicker.current_value

	var old_save_mode: SaveLocationModes = ProjectSettings.get_setting('dialogic/translation/intern/save_mode', save_mode)
	var old_file_mode: TranslationModes = ProjectSettings.get_setting('dialogic/translation/intern/file_mode', file_mode)
	var old_translation_folder: String = ProjectSettings.get_setting('dialogic/translation/intern/translation_folder', translation_folder)

	if (old_save_mode == save_mode
	and old_file_mode == file_mode
	and old_translation_folder == translation_folder):
		update_csv_files()
		return

	%UpdateConfirmationDialog.popup_centered()


## Used by the dialog to inform that the settings were changed.
func _delete_and_update() -> void:
	erase_translations()
	update_csv_files()


func update_csv_files() -> void:
	var orig_locale: String = ProjectSettings.get_setting('dialogic/translation/original_locale', '').strip_edges()
	var save_location_mode: SaveLocationModes = ProjectSettings.get_setting('dialogic/translation/save_mode', SaveLocationModes.NEXT_TO_TIMELINE)
	var translation_mode: TranslationModes = ProjectSettings.get_setting('dialogic/translation/file_mode', TranslationModes.PER_PROJECT)
	var translation_folder_path: String = ProjectSettings.get_setting('dialogic/translation/translation_folder', 'res://')

	if orig_locale.is_empty():
		orig_locale = ProjectSettings.get_setting('internationalization/locale/fallback')

	ProjectSettings.set_setting('dialogic/translation/intern/save_mode', save_location_mode)
	ProjectSettings.set_setting('dialogic/translation/intern/file_mode', translation_mode)
	ProjectSettings.set_setting('dialogic/translation/intern/translation_folder', translation_folder_path)

	var new_events := 0
	var new_timelines := 0
	var updated_events := 0
	var updated_timelines := 0
	var new_names := 0
	var updated_names := 0

	var current_timeline := _close_active_timeline()

	var csv_per_project: DialogicCsvFile = null
	var per_project_csv_path := translation_folder_path.path_join(DEFAULT_TIMELINE_CSV_NAME)

	if translation_mode == TranslationModes.PER_PROJECT:
		csv_per_project = DialogicCsvFile.new(per_project_csv_path, orig_locale)

		if (csv_per_project.is_new_file):
			new_timelines += 1
		else:
			updated_timelines += 1

	var names_csv_path := translation_folder_path.path_join(DEFAULT_CHARACTER_CSV_NAME)
	var character_name_csv: DialogicCsvFile = DialogicCsvFile.new(names_csv_path, orig_locale)

	if (character_name_csv.is_new_file):
		new_timelines += 1
	else:
		updated_timelines += 1

	# Iterate over all timelines.
	# Create or update CSV files.
	# Transform the timeline into translatable lines and collect into the CSV file.
	for timeline_path in DialogicResourceUtil.list_resources_of_type('.dtl'):
		var csv_file: DialogicCsvFile = csv_per_project

		# Swap the CSV file to the Per Timeline one.
		if translation_mode == TranslationModes.PER_TIMELINE:
			var per_timeline_path: String = timeline_path.trim_suffix('.dtl')
			var path_parts := per_timeline_path.split("/")
			var timeline_name: String = path_parts[-1]

			# Adjust the file path to the translation location mode.
			if save_location_mode == SaveLocationModes.INSIDE_TRANSLATION_FOLDER:
				var prefixed_timeline_name := "dialogic_" + timeline_name
				per_timeline_path = translation_folder_path.path_join(prefixed_timeline_name)


			per_timeline_path += '_translation.csv'
			csv_file = DialogicCsvFile.new(per_timeline_path, orig_locale)
			new_timelines += 1

		# Load and process timeline, turn events into resources.
		var timeline: DialogicTimeline = load(timeline_path)
		timeline.process()

		# Collect timeline into CSV.
		csv_file.collect_lines_from_timeline(timeline)
		var characters := csv_file.collected_characters
		character_name_csv.collect_lines_from_characters(characters)

		# in case new translation_id's were added, we save the timeline again
		timeline.set_meta("timeline_not_saved", true)
		ResourceSaver.save(timeline, timeline_path)

		if translation_mode == TranslationModes.PER_TIMELINE:
			csv_file.update_csv_file_on_disk()

		new_events += csv_file.new_rows
		updated_events += csv_file.updated_rows

	character_name_csv.update_csv_file_on_disk()

	if translation_mode == TranslationModes.PER_PROJECT:
		csv_per_project.update_csv_file_on_disk()

	if character_name_csv.is_new_file:
		new_timelines += 1
	else:
		updated_timelines += 1

	new_names += character_name_csv.new_rows
	updated_names += character_name_csv.updated_rows

	_silently_open_timeline(current_timeline)

	# Trigger reimport.
	find_parent('EditorView').plugin_reference.get_editor_interface().get_resource_filesystem().scan_sources()

	var status_message := "Events   created {new_events}   updated {updated_events}
		Names  created {new_names}   updated {updated_names}
		CSVs      created {new_timelines}   updated {updated_timelines}"

	var status_message_args := {
		'new_events': new_events,
		'updated_events': updated_events,
		'new_timelines': new_timelines,
		'updated_timelines': updated_timelines,
		'new_names': new_names,
		'updated_names': updated_names,
	}

	%StatusMessage.text = status_message.format(status_message_args)


func collect_translations() -> void:
	var translation_files := []
	var translation_mode: TranslationModes = ProjectSettings.get_setting('dialogic/translation/file_mode', TranslationModes.PER_PROJECT)

	if translation_mode == TranslationModes.PER_TIMELINE:

		for timeline_path in DialogicResourceUtil.list_resources_of_type('.translation'):

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
	%EraseConfirmationDialog.popup_centered()


## Deletes the Per-Project CSV file and the character name CSV file.
## Returns `true` on success.
func delete_per_project_csv(translation_folder: String) -> bool:
	var per_project_csv := translation_folder.path_join(DEFAULT_TIMELINE_CSV_NAME)

	if FileAccess.file_exists(per_project_csv):

		if OK == DirAccess.remove_absolute(per_project_csv):
			print_rich("[color=green]Deleted Per-Project timeline CSV file: " + per_project_csv + "[/color]")

			# Delete the timeline CSV import file.
			DirAccess.remove_absolute(per_project_csv + '.import')
			return true

		else:
			print_rich("[color=yellow]Failed to delete Per-Project timeline CSV file: " + per_project_csv + "[/color]")

	return false


## Deletes translation files generated by [param csv_name].
## The [param csv_name] may not contain the file extension (.csv).
##
## Returns a vector, value 1 is amount of deleted translation files.
## Value
func delete_translations_files(translation_files: Array, csv_name: String) -> int:
	var deleted_files := 0

	for file_path in DialogicResourceUtil.list_resources_of_type('.translation'):
		var base_name: String = file_path.get_basename()
		var path_parts := base_name.split("/")
		var translation_name: String = path_parts[-1]

		if translation_name.begins_with(csv_name):

			if OK == DirAccess.remove_absolute(file_path):
				var project_translation_file_index := translation_files.find(file_path)

				if project_translation_file_index > -1:
					translation_files.remove_at(project_translation_file_index)

				deleted_files += 1
				print_rich("[color=green]Deleted translation file: " + file_path + "[/color]")
			else:
				print_rich("[color=yellow]Failed to delete translation file: " + file_path + "[/color]")


	return deleted_files


## Iterates over all timelines and deletes their CSVs and timeline
## translation IDs.
## Deletes the Per-Project CSV file and the character name CSV file.
func erase_translations() -> void:
	var translation_files := Array(ProjectSettings.get_setting('internationalization/locale/translations', []))

	var deleted_csv_files := 0
	var deleted_translation_files := 0
	var cleaned_timelines := 0
	var cleaned_characters := 0
	var cleaned_events := 0

	var current_timeline := _close_active_timeline()

	# Delete all Dialogic CSV files and their translation files.
	for csv_path in DialogicResourceUtil.list_resources_of_type(".csv"):
		var csv_path_parts: PackedStringArray = csv_path.split("/")
		var csv_name: String = csv_path_parts[-1].trim_suffix(".csv")

		# Handle Dialogic CSVs only.
		if not csv_name.begins_with("dialogic_"):
			continue

		# Delete the CSV file.
		if OK == DirAccess.remove_absolute(csv_path):
			deleted_csv_files += 1
			print_rich("[color=green]Deleted CSV file: " + csv_path + "[/color]")

			deleted_translation_files += delete_translations_files(translation_files, csv_name)
		else:
			print_rich("[color=yellow]Failed to delete CSV file: " + csv_path + "[/color]")

	# Clean timelines.
	for timeline_path in DialogicResourceUtil.list_resources_of_type(".dtl"):

		# Process the timeline.
		var timeline: DialogicTimeline = load(timeline_path)
		timeline.process()
		cleaned_timelines += 1

		# Remove event translation IDs.
		for event in timeline.events:

			if event._translation_id and not event._translation_id.is_empty():
				event.remove_translation_id()
				event.update_text_version()
				cleaned_events += 1

				if "character" in event:
					# Remove character translation IDs.
					var character: DialogicCharacter = event.character

					if character != null and not character._translation_id.is_empty():
						character.remove_translation_id()
						cleaned_characters += 1

		timeline.set_meta("timeline_not_saved", true)
		ResourceSaver.save(timeline, timeline_path)

	ProjectSettings.set_setting('dialogic/translation/id_counter', 16)
	ProjectSettings.set_setting('internationalization/locale/translations', PackedStringArray(translation_files))
	ProjectSettings.save()

	find_parent('EditorView').plugin_reference.get_editor_interface().get_resource_filesystem().scan_sources()

	var status_message := "Timelines found {cleaned_timelines}
		Events cleaned {cleaned_events}
		Characters cleaned {cleaned_characters}

		CSVs erased {erased_csv_files}
		Translations erased {erased_translation_files}"

	var status_message_args := {
		'cleaned_timelines': cleaned_timelines,
		'cleaned_characters': cleaned_characters,
		'cleaned_events': cleaned_events,
		'erased_csv_files': deleted_csv_files,
		'erased_translation_files': deleted_translation_files,
	}

	_silently_open_timeline(current_timeline)

	# Trigger reimport.
	find_parent('EditorView').plugin_reference.get_editor_interface().get_resource_filesystem().scan_sources()

	# Clear the internal settings.
	ProjectSettings.clear('dialogic/translation/intern/save_mode')
	ProjectSettings.clear('dialogic/translation/intern/file_mode')
	ProjectSettings.clear('dialogic/translation/intern/translation_folder')

	_verify_translation_file()
	%StatusMessage.text = status_message.format(status_message_args)


## Closes the current timeline in the Dialogic Editor and returns the timeline
## as a resource.
## If no timeline has been opened, returns null.
func _close_active_timeline() -> Resource:
	var timeline_node: DialogicEditor = settings_editor.editors_manager.editors['Timeline']['node']
	# We will close this timeline to ensure it will properly update.
	# By saving this reference, we can open it again.
	var current_timeline := timeline_node.current_resource
	# Clean the current editor, this will also close the timeline.
	settings_editor.editors_manager.clear_editor(timeline_node)

	return current_timeline


## Opens the timeline resource into the Dialogic Editor.
## If the timeline is null, does nothing.
func _silently_open_timeline(timeline_to_open: Resource) -> void:
	if timeline_to_open != null:
		settings_editor.editors_manager.edit_resource(timeline_to_open, true, true)
