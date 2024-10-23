@tool
extends DialogicSettingsPage

## Settings tab that allows enabeling and updating translation files.


enum TranslationModes {PER_PROJECT, PER_TIMELINE, NONE}
enum SaveLocationModes {INSIDE_TRANSLATION_FOLDER, NEXT_TO_TIMELINE, NONE}
enum FileFormat {CSV, GETTEXT}

var loading := false
@onready var settings_editor: Control = find_parent('Settings')

## The default filename without extension that contains the translations for
## character properties.
const DEFAULT_CHARACTER_FILE_NAME := "dialogic_character_translations"
## The default filename without extension that contains the translations for
## timelines.
## Only used when all timelines are supposed to be translated in one file.
const DEFAULT_TIMELINE_TRANSLATION_FILE_NAME := "dialogic_timeline_translations"

const DEFAULT_GLOSSARY_TRANSLATION_FILE_NAME := "dialogic_glossary_translations"

const _USED_LOCALES_SETTING := "dialogic/translation/locales"

## Contains translation changes that were made during the last update.

## Unique locales that will be set after updating the files.
var _unique_locales := []

func _get_icon() -> Texture2D:
	return get_theme_icon("Translation", "EditorIcons")


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
	%AddSeparatorEnabled.toggled.connect(store_changes)

	%SaveLocationMode.item_selected.connect(store_changes)
	%TransMode.item_selected.connect(store_changes)
	%FileFormat.item_selected.connect(store_changes)

	%UpdateTranslationFiles.pressed.connect(_on_update_translations_pressed)
	%UpdateTranslationFiles.icon = get_theme_icon("Add", "EditorIcons")

	%CollectTranslations.pressed.connect(collect_translations)
	%CollectTranslations.icon = get_theme_icon("File", "EditorIcons")

	%TransRemove.pressed.connect(_on_erase_translations_pressed)
	%TransRemove.icon = get_theme_icon("Remove", "EditorIcons")

	%UpdateConfirmationDialog.add_button("Keep old & Generate new", false, "keep_old_add_new")

	%UpdateConfirmationDialog.custom_action.connect(_on_custom_action)

	_verify_translation_file()


func _on_custom_action(action: String) -> void:
	if action == "keep_old_add_new":
		update_translation_files()
		%UpdateConfirmationDialog.hide()


func _refresh() -> void:
	loading = true

	%TransEnabled.button_pressed = ProjectSettings.get_setting('dialogic/translation/enabled', false)
	%TranslationSettings.visible = %TransEnabled.button_pressed
	%OrigLocale.set_value(ProjectSettings.get_setting('dialogic/translation/original_locale', TranslationServer.get_tool_locale()))
	%TransMode.select(ProjectSettings.get_setting('dialogic/translation/file_mode', 1))
	%FileFormat.select(ProjectSettings.get_setting('dialogic/translation/file_format', FileFormat.CSV))
	%TransFolderPicker.set_value(ProjectSettings.get_setting('dialogic/translation/translation_folder', ''))
	%TestingLocale.set_value(ProjectSettings.get_setting('internationalization/locale/test', ''))
	%AddSeparatorEnabled.button_pressed = ProjectSettings.get_setting('dialogic/translation/add_separator', false)

	_verify_translation_file()

	loading = false


func store_changes(_fake_arg: Variant = null, _fake_arg2: Variant = null) -> void:
	if loading:
		return

	_verify_translation_file()

	ProjectSettings.set_setting('dialogic/translation/enabled', %TransEnabled.button_pressed)
	%TranslationSettings.visible = %TransEnabled.button_pressed
	ProjectSettings.set_setting('dialogic/translation/original_locale', %OrigLocale.current_value)
	ProjectSettings.set_setting('dialogic/translation/file_mode', %TransMode.selected)
	ProjectSettings.set_setting('dialogic/translation/file_format', %FileFormat.selected)
	ProjectSettings.set_setting('dialogic/translation/translation_folder', %TransFolderPicker.current_value)
	ProjectSettings.set_setting('internationalization/locale/test', %TestingLocale.current_value)
	ProjectSettings.set_setting('dialogic/translation/save_mode', %SaveLocationMode.selected)
	ProjectSettings.set_setting('dialogic/translation/add_separator', %AddSeparatorEnabled.button_pressed)
	ProjectSettings.save()


## Checks whether the translation folder path is required.
## If it is, disables the "Update translation files" button and shows a warning.
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

	%UpdateTranslationFiles.disabled = not valid_translation_folder

	var status_message := ""

	if not valid_translation_folder:
		status_message += "⛔ Requires valid translation folder to translate character names"

		if file_mode == TranslationModes.PER_PROJECT:
			status_message += " and the translation file."
		else:
			status_message += "."

	%StatusMessage.text = status_message


func get_locales(_filter: String) -> Dictionary:
	var suggestions := {}
	suggestions['Default'] = {'value':'', 'tooltip':"Will use the fallback locale set in the project settings."}
	suggestions[TranslationServer.get_tool_locale()] = {'value':TranslationServer.get_tool_locale()}

	var used_locales: Array = ProjectSettings.get_setting(_USED_LOCALES_SETTING, TranslationServer.get_all_languages())

	for locale: String in used_locales:
		var language_name := TranslationServer.get_language_name(locale)

		# Invalid locales return an empty String.
		if language_name.is_empty():
			continue

		suggestions[locale] = { 'value': locale, 'tooltip': language_name }

	return suggestions


func _on_update_translations_pressed() -> void:
	var save_mode: SaveLocationModes = %SaveLocationMode.selected
	var file_mode: TranslationModes = %TransMode.selected
	var file_format: FileFormat = %FileFormat.selected
	var translation_folder: String = %TransFolderPicker.current_value

	var old_save_mode: SaveLocationModes = ProjectSettings.get_setting('dialogic/translation/intern/save_mode', save_mode)
	var old_file_mode: TranslationModes = ProjectSettings.get_setting('dialogic/translation/intern/file_mode', file_mode)
	var old_file_format: FileFormat = ProjectSettings.get_setting('dialogic/translation/intern/file_format', file_format)
	var old_translation_folder: String = ProjectSettings.get_setting('dialogic/translation/intern/translation_folder', translation_folder)

	if (old_save_mode == save_mode
	and old_file_mode == file_mode
	and old_file_format == file_format
	and old_translation_folder == translation_folder):
		update_translation_files()
		return

	%UpdateConfirmationDialog.popup_centered()


## Used by the dialog to inform that the settings were changed.
func _delete_and_update() -> void:
	erase_translations()
	update_translation_files()


## Creates or updates the glossary translation files.
func _handle_glossary_translation(
	translation_data: TranslationUpdateData,
	save_location_mode: SaveLocationModes,
	translation_mode: TranslationModes,
	translation_folder_path: String,
	orig_locale: String) -> void:

	var translation_file: DialogicTranslationFile = null
	var glossary_paths: Array = ProjectSettings.get_setting('dialogic/glossary/glossary_files', [])
	glossary_paths.sort()
	for glossary_path: String in glossary_paths:

		if translation_file == null:
			var file_name := ""

			# Get glossary translation file name.
			match translation_mode:
				TranslationModes.PER_PROJECT:
					file_name = DEFAULT_GLOSSARY_TRANSLATION_FILE_NAME

				TranslationModes.PER_TIMELINE:
					var glossary_name: String = glossary_path.trim_suffix('.tres')
					var path_parts := glossary_name.split("/")
					file_name = "dialogic_" + path_parts[-1] + '_translation'

			var translation_file_path := ""
			# Get glossary translation file path.
			match save_location_mode:
				SaveLocationModes.INSIDE_TRANSLATION_FOLDER:
					translation_file_path = translation_folder_path.path_join(file_name)

				SaveLocationModes.NEXT_TO_TIMELINE:
					translation_file_path = glossary_path.get_base_dir().path_join(file_name)

			# Create or update glossary translation file.
			translation_file = _open_translation_file(translation_file_path, orig_locale)

			if (translation_file.is_new_file):
				translation_data.new_glossaries += 1
			else:
				translation_data.updated_glossaries += 1

		var glossary: DialogicGlossary = load(glossary_path)
		translation_file.collect_lines_from_glossary(glossary)
		ResourceSaver.save(glossary)

		#If per-file mode is used, save this file and begin a new one.
		if translation_mode == TranslationModes.PER_TIMELINE:
			translation_file.update_file_on_disk()
			translation_file = null

	# If a Per-Project glossary is still open, we need to save it.
	if translation_file != null:
		translation_file.update_file_on_disk()
		translation_file = null


## Keeps information about the amount of new and updated translation entries
## and what resources were populated with translation IDs.
## The final data can be used to display a status message.
class TranslationUpdateData:
	var new_events := 0
	var updated_events := 0

	var new_timelines := 0
	var updated_timelines := 0

	var new_names := 0
	var updated_names := 0

	var new_glossaries := 0
	var updated_glossaries := 0

	var new_glossary_entries := 0
	var updated_glossary_entries := 0


func update_translation_files() -> void:
	_unique_locales = []
	var orig_locale: String = ProjectSettings.get_setting('dialogic/translation/original_locale', '').strip_edges()
	var save_location_mode: SaveLocationModes = ProjectSettings.get_setting('dialogic/translation/save_mode', SaveLocationModes.NEXT_TO_TIMELINE)
	var translation_mode: TranslationModes = ProjectSettings.get_setting('dialogic/translation/file_mode', TranslationModes.PER_PROJECT)
	var file_format: FileFormat = ProjectSettings.get_setting('dialogic/translation/file_format', FileFormat.CSV)
	var translation_folder_path: String = ProjectSettings.get_setting('dialogic/translation/translation_folder', 'res://')

	var translation_data := TranslationUpdateData.new()

	if orig_locale.is_empty():
		orig_locale = ProjectSettings.get_setting('internationalization/locale/fallback')

	ProjectSettings.set_setting('dialogic/translation/intern/save_mode', save_location_mode)
	ProjectSettings.set_setting('dialogic/translation/intern/file_mode', translation_mode)
	ProjectSettings.set_setting('dialogic/translation/intern/file_format', file_format)
	ProjectSettings.set_setting('dialogic/translation/intern/translation_folder', translation_folder_path)

	var current_timeline := _close_active_timeline()

	var file_per_project: DialogicTranslationFile = null
	var per_project_file_path := translation_folder_path.path_join(DEFAULT_TIMELINE_TRANSLATION_FILE_NAME)

	if translation_mode == TranslationModes.PER_PROJECT:
		file_per_project = _open_translation_file(per_project_file_path, orig_locale)

		if (file_per_project.is_new_file):
			translation_data.new_timelines += 1
		else:
			translation_data.updated_timelines += 1

	# Iterate over all timelines.
	# Create or update translation files.
	# Transform the timeline into translatable lines and collect into the translation file.
	var timeline_paths := DialogicResourceUtil.list_resources_of_type('.dtl')
	timeline_paths.sort()
	for timeline_path: String in timeline_paths:
		var translation_file: DialogicTranslationFile = file_per_project

		# Swap the translation file to the Per Timeline one.
		if translation_mode == TranslationModes.PER_TIMELINE:
			var per_timeline_path: String = timeline_path.trim_suffix('.dtl')
			var path_parts := per_timeline_path.split("/")
			var timeline_name: String = path_parts[-1]

			# Adjust the file path to the translation location mode.
			if save_location_mode == SaveLocationModes.INSIDE_TRANSLATION_FOLDER:
				var prefixed_timeline_name := "dialogic_" + timeline_name
				per_timeline_path = translation_folder_path.path_join(prefixed_timeline_name)


			per_timeline_path += '_translation'
			translation_file = _open_translation_file(per_timeline_path, orig_locale)
			translation_data.new_timelines += 1

		# Load and process timeline, turn events into resources.
		var timeline: DialogicTimeline = load(timeline_path)

		if timeline.events.size() == 0:
			print_rich("[color=yellow]Empty timeline, skipping: " + timeline_path + "[/color]")
			continue

		timeline.process()

		# Collect timeline into translation file.
		translation_file.collect_lines_from_timeline(timeline)

		# in case new translation_id's were added, we save the timeline again
		timeline.set_meta("timeline_not_saved", true)
		ResourceSaver.save(timeline, timeline_path)

		if translation_mode == TranslationModes.PER_TIMELINE:
			translation_file.update_file_on_disk()

		translation_data.new_events += translation_file.new_rows
		translation_data.updated_events += translation_file.updated_rows

	_handle_glossary_translation(
		translation_data,
		save_location_mode,
		translation_mode,
		translation_folder_path,
		orig_locale
	)

	_handle_character_names(
		translation_data,
		orig_locale,
		translation_folder_path
	)

	if translation_mode == TranslationModes.PER_PROJECT:
		file_per_project.update_file_on_disk()

	_silently_open_timeline(current_timeline)

	# Trigger reimport.
	find_parent('EditorView').plugin_reference.get_editor_interface().get_resource_filesystem().scan_sources()

	var status_message := "Events   created {new_events}   found {updated_events}
		Names  created {new_names}   found {updated_names}
		Files     created {new_timelines}   found {updated_timelines}
		Glossary  created {new_glossaries}   found {updated_glossaries}
		Entries   created {new_glossary_entries}   found {updated_glossary_entries}"

	var status_message_args := {
		'new_events': translation_data.new_events,
		'updated_events': translation_data.updated_events,
		'new_timelines': translation_data.new_timelines,
		'updated_timelines': translation_data.updated_timelines,
		'new_glossaries': translation_data.new_glossaries,
		'updated_glossaries': translation_data.updated_glossaries,
		'new_names': translation_data.new_names,
		'updated_names': translation_data.updated_names,
		'new_glossary_entries': translation_data.new_glossary_entries,
		'updated_glossary_entries': translation_data.updated_glossary_entries,
	}

	%StatusMessage.text = status_message.format(status_message_args)
	ProjectSettings.set_setting(_USED_LOCALES_SETTING, _unique_locales)


## Iterates over all character resource files and creates or updates translation files
## that contain the translations for character properties.
## This will save each character resource file to disk.
func _handle_character_names(
		translation_data: TranslationUpdateData,
		original_locale: String,
		translation_folder_path: String) -> void:
	var names_translation_path := translation_folder_path.path_join(DEFAULT_CHARACTER_FILE_NAME)
	var character_name_file: DialogicTranslationFile = _open_translation_file(names_translation_path, original_locale)

	var character_paths := DialogicResourceUtil.list_resources_of_type('.dch')
	character_paths.sort()
	for character_path: String in character_paths:
		var character: DialogicCharacter = load(character_path)

		if character._translation_id.is_empty():
			translation_data.new_names += 1

		else:
			translation_data.updated_names += 1

		ResourceSaver.save(character)
		character_name_file.collect_lines_from_character(character)

	character_name_file.update_file_on_disk()


func collect_translations() -> void:
	var translation_files := []
	var all_translation_files: Array = ProjectSettings.get_setting('internationalization/locale/translations', [])
	var added_translation_files := 0
	var removed_translation_files := 0

	var save_location: SaveLocationModes = ProjectSettings.get_setting('dialogic/translation/file_mode', SaveLocationModes.INSIDE_TRANSLATION_FOLDER)

	_collect_translation_files(".translation", translation_files)
	_collect_translation_files(".po", translation_files)

	for file_path: String in translation_files:
		if not file_path in all_translation_files:
			all_translation_files.append(file_path)
			added_translation_files += 1

	# This array keeps track of valid translation file paths.
	var found_file_paths := []

	for file_path: String in all_translation_files:
		# If the file path is not valid, we must clean it up.
		if ResourceLoader.exists(file_path):
			found_file_paths.append(file_path)
		else:
			removed_translation_files += 1
			continue

		var path_without_suffix := file_path.trim_suffix('.translation').trim_suffix(".po")
		var locale_part := path_without_suffix.split(".")[-1]
		_collect_locale(locale_part)


	var valid_translation_files := PackedStringArray(found_file_paths)
	ProjectSettings.set_setting('internationalization/locale/translations', valid_translation_files)
	ProjectSettings.save()

	%StatusMessage.text = (
		"Added translation files: " + str(added_translation_files)
		+ "\nRemoved translation files: " + str(removed_translation_files)
		+ "\nTotal translation files: " + str(len(valid_translation_files)))


func _collect_translation_files(extension: String, translation_files: Array) -> void:
	for path: String in DialogicResourceUtil.list_resources_of_type(extension):
		# Handle Dialogic files only.
		if _is_dialogic_file(path):
			translation_files.append(path)


func _is_dialogic_file(path: String) -> bool:
	var path_parts: PackedStringArray = path.split("/")
	var file_name: String = path_parts[-1]

	# Some file types have two dots after the base name.
	var  dots_after_base_name = 1
	if file_name.ends_with(".translation") or file_name.ends_with(".po") or file_name.ends_with(".import"):
		dots_after_base_name = 2

	if file_name.begins_with("dialogic_"):
		return true
	# Special case for timelines in PER_TIMELINE + NEXT_TO_TIMELINE mode:
	elif FileAccess.file_exists(path.rsplit(".", true, dots_after_base_name)[0].trim_suffix("_translation") + ".dtl"):
		return true
	else:
		return false


func _on_erase_translations_pressed() -> void:
	%EraseConfirmationDialog.popup_centered()


## Delete all files starting with dialogic_ and ending in [param extension].
## [param dots_after_base_name] is the number of dots to remove from the full name
## to get the base name.
func _delete_files(extension: String, translation_files: Array) -> int:
	var deleted_files: int = 0
	for path: String in DialogicResourceUtil.list_resources_of_type(extension):
		# Handle Dialogic files only.
		if not _is_dialogic_file(path):
			continue

		# Delete the file.
		if OK == DirAccess.remove_absolute(path):
			var idx = translation_files.find(path)
			if idx >= 0:
				translation_files.remove_at(idx)

			deleted_files += 1
			print_rich("[color=green]Deleted file: " + path + "[/color]")
		else:
			print_rich("[color=yellow]Failed to delete file: " + path + "[/color]")

	return deleted_files


## Iterates over all timelines and deletes their translation files and timeline
## translation IDs.
## Deletes the Per-Project translation file and the character name translation file.
func erase_translations() -> void:
	var files: PackedStringArray = ProjectSettings.get_setting('internationalization/locale/translations', [])
	var translation_files := Array(files)
	ProjectSettings.set_setting(_USED_LOCALES_SETTING, [])

	var deleted_files := 0
	var deleted_translation_files := 0
	var cleaned_timelines := 0
	var cleaned_characters := 0
	var cleaned_events := 0
	var cleaned_glossaries := 0

	var current_timeline := _close_active_timeline()

	# Delete main translation files.
	deleted_files += _delete_files(".csv", translation_files)
	deleted_files += _delete_files(".pot", translation_files)

	# Delete generated translation files.
	deleted_translation_files += _delete_files(".csv.import", translation_files)
	deleted_translation_files += _delete_files(".translation", translation_files)
	deleted_translation_files += _delete_files(".po", translation_files)

	# Clean timelines.
	for timeline_path: String in DialogicResourceUtil.list_resources_of_type(".dtl"):

		# Process the timeline.
		var timeline: DialogicTimeline = load(timeline_path)
		timeline.process()
		cleaned_timelines += 1

		# Remove event translation IDs.
		for event: DialogicEvent in timeline.events:

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

	_erase_glossary_translation_ids()
	_erase_character_name_translation_ids()

	ProjectSettings.set_setting('dialogic/translation/id_counter', 16)
	ProjectSettings.set_setting('internationalization/locale/translations', PackedStringArray(translation_files))
	ProjectSettings.save()

	find_parent('EditorView').plugin_reference.get_editor_interface().get_resource_filesystem().scan_sources()

	var status_message := "Timelines cleaned {cleaned_timelines}
		Events cleaned {cleaned_events}
		Characters cleaned {cleaned_characters}
		Glossaries cleaned {cleaned_glossaries}

		Files erased {erased_files}
		Translations erased {erased_translation_files}"

	var status_message_args := {
		'cleaned_timelines': cleaned_timelines,
		'cleaned_characters': cleaned_characters,
		'cleaned_events': cleaned_events,
		'cleaned_glossaries': cleaned_glossaries,
		'erased_files': deleted_files,
		'erased_translation_files': deleted_translation_files,
	}

	_silently_open_timeline(current_timeline)

	# Trigger reimport.
	find_parent('EditorView').plugin_reference.get_editor_interface().get_resource_filesystem().scan_sources()

	# Clear the internal settings.
	ProjectSettings.clear('dialogic/translation/intern/save_mode')
	ProjectSettings.clear('dialogic/translation/intern/file_mode')
	ProjectSettings.clear('dialogic/translation/intern/file_format')
	ProjectSettings.clear('dialogic/translation/intern/translation_folder')

	_verify_translation_file()
	%StatusMessage.text = status_message.format(status_message_args)


func _erase_glossary_translation_ids() -> void:
	# Clean glossary.
	var glossary_paths: Array = ProjectSettings.get_setting('dialogic/glossary/glossary_files', [])

	for glossary_path: String in glossary_paths:
		var glossary: DialogicGlossary = load(glossary_path)
		glossary.remove_translation_id()
		glossary.remove_entry_translation_ids()
		glossary.clear_translation_keys()
		ResourceSaver.save(glossary, glossary_path)
		print_rich("[color=green]Cleaned up glossary file: " + glossary_path + "[/color]")


func _erase_character_name_translation_ids() -> void:
	for character_path: String in DialogicResourceUtil.list_resources_of_type('.dch'):
		var character: DialogicCharacter = load(character_path)

		character.remove_translation_id()
		ResourceSaver.save(character)


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


## Checks [param locale] for unique locales that have not been added
## to the [_unique_locales] array yet.
func _collect_locale(locale: String) -> void:
	if _unique_locales.has(locale):
		return

	_unique_locales.append(locale)


func _open_translation_file(path: String, orig_locale: String) -> DialogicTranslationFile:
	match ProjectSettings.get_setting('dialogic/translation/file_format', FileFormat.CSV):
		FileFormat.CSV:
			var add_separator_lines: bool = ProjectSettings.get_setting('dialogic/translation/add_separator', false)
			return DialogicTranslationCsvFile.new(path + ".csv", orig_locale, add_separator_lines)
		FileFormat.GETTEXT:
			return DialogicTranslationGettextFile.new(path + ".pot", orig_locale)
		_:
			assert(false, "Invalid FileFormat")
			return null
