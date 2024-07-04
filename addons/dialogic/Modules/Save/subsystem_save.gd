extends DialogicSubsystem
## Subsystem to save and load game states.
##
## This subsystem has many different helper methods to save Dialogic or custom
## game data to named save slots.
##
## You can listen to saves via [signal saved]. \
## If you want to save, you can call [method save]. \


## Emitted when a save happened with the following info:
## [br]
## Key           |   Value Type  | Value [br]
## -----------   | ------------- | ----- [br]
## `slot_name`   | [type String] | The name of the slot that the game state was saved to. [br]
## `is_autosave` | [type bool]   | `true`, if the save was an autosave. [br]
signal saved(info: Dictionary)


## The directory that will be saved to.
const SAVE_SLOTS_DIR := "user://dialogic/saves/"

## The project settings key for the auto-save enabled settings.
const AUTO_SAVE_SETTINGS := "dialogic/save/autosave"

## The project settings key for the auto-save mode settings.
const AUTO_SAVE_MODE_SETTINGS := "dialogic/save/autosave_mode"

## The project settings key for the auto-save delay settings.
const AUTO_SAVE_TIME_SETTINGS := "dialogic/save/autosave_delay"

## Temporarily stores a taken screen capture when using [take_slot_image()].
enum ThumbnailMode {NONE, TAKE_AND_STORE, STORE_ONLY}
var latest_thumbnail: Image = null


## The different types of auto-save triggers.
## If one of these occurs in the game, an auto-save may happen
## if [member autosave_enabled] is `true`.
enum AutoSaveMode {
	## Includes timeline start, end, and jump events.
	ON_TIMELINE_JUMPS = 0,
	## Saves after a certain time interval.
	ON_TIMER = 1,
	## Saves after every text event.
	ON_TEXT_EVENT = 2
}

## Whether the auto-save feature is enabled.
## The initial value can be set in the project settings via th Dialogic editor.
##
## This can be toggled during the game.
var autosave_enabled := false:
	set(enabled):
		autosave_enabled = enabled

		if enabled:
			autosave_timer.start()
		else:
			autosave_timer.stop()


## Under what conditions the auto-save feature will trigger if
## [member autosave_enabled] is `true`.
var autosave_mode := AutoSaveMode.ON_TIMELINE_JUMPS

## After what time interval the auto-save feature will trigger if
## [member autosave_enabled] is `true` and [member autosave_mode] is
## `AutoSaveMode.ON_TIMER`.
var autosave_time := 60:
	set(timer_time):
		autosave_time = timer_time
		autosave_timer.wait_time = timer_time


#region STATE
####################################################################################################

## Built-in, called by DialogicGameHandler.
func clear_game_state(_clear_flag := DialogicGameHandler.ClearFlags.FULL_CLEAR) -> void:
	_make_sure_slot_dir_exists()


## Built-in, called by DialogicGameHandler.
func pause() -> void:
	autosave_timer.paused = true


## Built-in, called by DialogicGameHandler.
func resume() -> void:
	autosave_timer.paused = false

#endregion


#region MAIN METHODS
####################################################################################################

## Saves the current state to the given slot.
## If no slot is given, the default slot is used. You can change this name in
## the Dialogic editor.
## If you want to save to the last used slot, you can get its slot name with the
## [method get_latest_slot()] method.
func save(slot_name := "", is_autosave := false, thumbnail_mode := ThumbnailMode.TAKE_AND_STORE, slot_info := {}) -> Error:
	# check if to save (if this is an autosave)
	if is_autosave and !autosave_enabled:
		return OK

	if slot_name.is_empty():
		slot_name = get_default_slot()

	set_latest_slot(slot_name)

	var save_error := save_file(slot_name, 'state.txt', dialogic.get_full_state())

	if save_error:
		return save_error

	if thumbnail_mode == ThumbnailMode.TAKE_AND_STORE:
		take_thumbnail()
		save_slot_thumbnail(slot_name)
	elif thumbnail_mode == ThumbnailMode.STORE_ONLY:
		save_slot_thumbnail(slot_name)

	if slot_info:
		set_slot_info(slot_name, slot_info)

	saved.emit({"slot_name": slot_name, "is_autosave": is_autosave})
	print('[Dialogic] Saved to slot "'+slot_name+'".')
	return OK


## Loads all info from the given slot in the DialogicGameHandler (Dialogic Autoload).
## If no slot is given, the default slot is used.
## To check if something is saved in that slot use has_slot().
## If the slot does not exist, this method will fail.
func load(slot_name := "") -> Error:
	if slot_name.is_empty(): slot_name = get_default_slot()

	if !has_slot(slot_name):
		printerr("[Dialogic Error] Tried loading from invalid save slot '"+slot_name+"'.")
		return ERR_FILE_NOT_FOUND

	var set_latest_error := set_latest_slot(slot_name)
	if set_latest_error:
		push_error("[Dialogic Error]: Failed to store latest slot to global info. Error %d '%s'" % [set_latest_error, error_string(set_latest_error)])

	var state: Dictionary = load_file(slot_name, 'state.txt', {})
	dialogic.load_full_state(state)

	if state.is_empty():
		return FAILED
	else:
		return OK


## Saves a variable to a file in the given slot.
##
## Be aware, the [param slot_name] will be used as a filesystem folder name.
## Some operating systems do not support every character in folder names.
## It is recommended to use only letters, numbers, and underscores.
##
## This method allows you to build your own save and load system.
## You may be looking for the simple [method save] method to save the game state.
func save_file(slot_name: String, file_name: String, data: Variant) -> Error:
	if slot_name.is_empty():
		slot_name = get_default_slot()

	if slot_name.is_empty():
		push_error("[Dialogic Error]: No fallback slot name set.")
		return ERR_FILE_NOT_FOUND

	if !has_slot(slot_name):
		add_empty_slot(slot_name)

	var encryption_password := get_encryption_password()
	var file: FileAccess

	if encryption_password.is_empty():
		file = FileAccess.open(SAVE_SLOTS_DIR.path_join(slot_name).path_join(file_name), FileAccess.WRITE)
	else:
		file = FileAccess.open_encrypted_with_pass(SAVE_SLOTS_DIR.path_join(slot_name).path_join(file_name), FileAccess.WRITE, encryption_password)

	if file:
		file.store_var(data)
		return OK
	else:
		var error := FileAccess.get_open_error()
		push_error("[Dialogic Error]: Could not save slot to file. Error: %d '%s'" % [error, error_string(error)])
		return error


## Loads a file using [param slot_name] and returns the contained info.
##
## This method allows you to build your own save and load system.
## You may be looking for the simple [method load] method to load the game state.
func load_file(slot_name: String, file_name: String, default: Variant) -> Variant:
	if slot_name.is_empty(): slot_name = get_default_slot()

	var path := get_slot_path(slot_name).path_join(file_name)
	if FileAccess.file_exists(path):
		var encryption_password := get_encryption_password()
		var file: FileAccess

		if encryption_password.is_empty():
			file = FileAccess.open(path, FileAccess.READ)
		else:
			file = FileAccess.open_encrypted_with_pass(path, FileAccess.READ, encryption_password)

		if file:
			return file.get_var()
		else:
			push_error(FileAccess.get_open_error())
	return default


## Data set in global info can be accessed unrelated to the save slots.
## For instance, you may want to store game settings in here, as they
## affect the game globally unrelated to the slot used.
func set_global_info(key: String, value: Variant) -> Error:
	var global_info := ConfigFile.new()
	var encryption_password := get_encryption_password()

	if encryption_password.is_empty():
		var load_error := global_info.load(SAVE_SLOTS_DIR.path_join('global_info.txt'))
		if load_error:
			printerr("[Dialogic Error]: Couldn't access global saved info file.")
			return load_error

		else:
			global_info.set_value('main', key, value)
			return global_info.save(SAVE_SLOTS_DIR.path_join('global_info.txt'))

	else:
		var load_error := global_info.load_encrypted_pass(SAVE_SLOTS_DIR.path_join('global_info.txt'), encryption_password)
		if load_error:
			printerr("[Dialogic Error]: Couldn't access global saved info file.")
			return load_error

		else:
			global_info.set_value('main', key, value)
			return global_info.save_encrypted_pass(SAVE_SLOTS_DIR.path_join('global_info.txt'), encryption_password)


## Access the data unrelated to a save slot.
## First, the data must have been set with [method set_global_info].
func get_global_info(key: String, default: Variant) -> Variant:
	var global_info := ConfigFile.new()
	var encryption_password := get_encryption_password()

	if encryption_password.is_empty():

		if global_info.load(SAVE_SLOTS_DIR.path_join('global_info.txt')) == OK:
			return global_info.get_value('main', key, default)

		printerr("[Dialogic Error]: Couldn't access global saved info file.")

	elif global_info.load_encrypted_pass(SAVE_SLOTS_DIR.path_join('global_info.txt'), encryption_password) == OK:
		return global_info.get_value('main', key, default)

	return default


## Gets the encryption password from the project settings if it has been set.
## If no password has been set, an empty string is returned.
func get_encryption_password() -> String:
	if OS.is_debug_build() and ProjectSettings.get_setting('dialogic/save/encryption_on_exports_only', true):
		return ""
	return ProjectSettings.get_setting("dialogic/save/encryption_password", "")

#endregion


#region SLOT HELPERS
####################################################################################################
## Returns a list of all available slots. Useful for iterating over all slots,
## e.g., when building a UI with all save slots.
func get_slot_names() -> Array[String]:
	var save_folders: Array[String] = []

	if DirAccess.dir_exists_absolute(SAVE_SLOTS_DIR):
		var directory := DirAccess.open(SAVE_SLOTS_DIR)
		var _list_dir := directory.list_dir_begin()
		var file_name := directory.get_next()

		while not file_name.is_empty():

			if directory.current_is_dir() and not file_name.begins_with("."):
				save_folders.append(file_name)

			file_name = directory.get_next()

		return save_folders

	return []


## Returns true if the given slot exists.
func has_slot(slot_name: String) -> bool:
	if slot_name.is_empty():
		slot_name = get_default_slot()

	return slot_name in get_slot_names()


## Removes all the given slot along with all it's info/files.
func delete_slot(slot_name: String) -> Error:
	var path := SAVE_SLOTS_DIR.path_join(slot_name)

	if DirAccess.dir_exists_absolute(path):
		var directory := DirAccess.open(path)
		if not directory:
			return DirAccess.get_open_error()
		var _list_dir := directory.list_dir_begin()
		var file_name := directory.get_next()

		while not file_name.is_empty():
			var remove_error := directory.remove(file_name)
			if remove_error:
				push_warning("[Dialogic Error]: Encountered error while removing '%s': %d\t%s" % [path.path_join(file_name), remove_error, error_string(remove_error)])
			file_name = directory.get_next()

		# Delete the folder.
		return directory.remove(SAVE_SLOTS_DIR.path_join(slot_name))

	push_warning("[Dialogic Warning]: Save slot '%s' has already been deleted." % path)
	return OK


## This adds a new save folder with the given name
func add_empty_slot(slot_name: String) -> Error:
	if DirAccess.dir_exists_absolute(SAVE_SLOTS_DIR):
		var directory := DirAccess.open(SAVE_SLOTS_DIR)
		if directory:
			return directory.make_dir(slot_name)
		return DirAccess.get_open_error()

	push_error("[Dialogic Error]: Path to '%s' does not exist." % SAVE_SLOTS_DIR)
	return ERR_FILE_BAD_PATH


## Reset the state of the given save folder (or default)
func reset_slot(slot_name := "") -> Error:
	if slot_name.is_empty():
		slot_name = get_default_slot()

	return save_file(slot_name, 'state.txt', {})


## Returns the full path to the given slot folder
func get_slot_path(slot_name: String) -> String:
	return SAVE_SLOTS_DIR.path_join(slot_name)


## Returns the default slot name defined in the dialogic settings
func get_default_slot() -> String:
	return ProjectSettings.get_setting('dialogic/save/default_slot', 'Default')


## Returns the latest slot or empty if nothing was saved yet
func get_latest_slot() -> String:
	var latest_slot := ""

	if Engine.get_main_loop().has_meta('dialogic_latest_saved_slot'):
		latest_slot = Engine.get_main_loop().get_meta('dialogic_latest_saved_slot', '')

	else:
		latest_slot = get_global_info('latest_save_slot', '')
		Engine.get_main_loop().set_meta('dialogic_latest_saved_slot', latest_slot)


	if !has_slot(latest_slot):
		return ''

	return latest_slot


func set_latest_slot(slot_name:String) -> Error:
	Engine.get_main_loop().set_meta('dialogic_latest_saved_slot', slot_name)
	return set_global_info('latest_save_slot', slot_name)


func _make_sure_slot_dir_exists() -> Error:
	if not DirAccess.dir_exists_absolute(SAVE_SLOTS_DIR):
		var make_dir_result := DirAccess.make_dir_recursive_absolute(SAVE_SLOTS_DIR)
		if make_dir_result:
			return make_dir_result

	var global_info_path := SAVE_SLOTS_DIR.path_join('global_info.txt')

	if not FileAccess.file_exists(global_info_path):
		var config := ConfigFile.new()
		var password := get_encryption_password()

		if password.is_empty():
			return config.save(global_info_path)

		else:
			return config.save_encrypted_pass(global_info_path, password)

	return OK

#endregion


#region SLOT INFO
####################################################################################################

func set_slot_info(slot_name:String, info: Dictionary) -> Error:
	if slot_name.is_empty():
		slot_name = get_default_slot()

	return save_file(slot_name, 'info.txt', info)


func get_slot_info(slot_name := "") -> Dictionary:
	if slot_name.is_empty():
		slot_name = get_default_slot()

	return load_file(slot_name, 'info.txt', {})

#endregion


#region SLOT IMAGE
####################################################################################################

## This method creates a thumbnail of the current game view, it allows to
## save the game without having the UI on the save slot image.
## The thumbnail will be stored in [member latest_thumbnail].
##
## Call this method before opening your save & load menu.
## After that, call [method save] with [constant ThumbnailMode.STORE_ONLY].
## The [method save] will automatically use the stored thumbnail.
func take_thumbnail() -> void:
	latest_thumbnail = get_viewport().get_texture().get_image()


## No need to call from outside.
## Used to store the latest thumbnail to the given slot.
func save_slot_thumbnail(slot_name: String) -> Error:
	if latest_thumbnail:
		var path := get_slot_path(slot_name).path_join('thumbnail.png')
		return latest_thumbnail.save_png(path)

	push_warning("[Dialogic Warning]: No thumbnail has been set yet.")
	return OK


## Returns the thumbnail of the given slot.
func get_slot_thumbnail(slot_name: String) -> ImageTexture:
	if slot_name.is_empty():
		slot_name = get_default_slot()

	var path := get_slot_path(slot_name).path_join('thumbnail.png')

	if FileAccess.file_exists(path):
		return ImageTexture.create_from_image(Image.load_from_file(path))

	return null

#endregion


#region AUTOSAVE
####################################################################################################
## Reference to the autosave timer.
var autosave_timer := Timer.new()


func _ready() -> void:
	autosave_timer.one_shot = true
	DialogicUtil.update_timer_process_callback(autosave_timer)
	autosave_timer.name = "AutosaveTimer"
	var _result := autosave_timer.timeout.connect(_on_autosave_timer_timeout)
	add_child(autosave_timer)

	autosave_enabled = ProjectSettings.get_setting(AUTO_SAVE_SETTINGS, autosave_enabled)
	autosave_mode = ProjectSettings.get_setting(AUTO_SAVE_MODE_SETTINGS, autosave_mode)
	autosave_time = ProjectSettings.get_setting(AUTO_SAVE_TIME_SETTINGS, autosave_time)

	_result = dialogic.event_handled.connect(_on_dialogic_event_handled)
	_result = dialogic.timeline_started.connect(_on_start_or_end_autosave)
	_result = dialogic.timeline_ended.connect(_on_start_or_end_autosave)

	if autosave_enabled:
		autosave_timer.start(autosave_time)


func _on_autosave_timer_timeout() -> void:
	if autosave_mode == AutoSaveMode.ON_TIMER:
		perform_autosave()

	autosave_timer.start(autosave_time)


func _on_dialogic_event_handled(event: DialogicEvent) -> void:
	if event is DialogicJumpEvent:

		if autosave_mode == AutoSaveMode.ON_TIMELINE_JUMPS:
			perform_autosave()

	if event is DialogicTextEvent:

		if autosave_mode == AutoSaveMode.ON_TEXT_EVENT:
			perform_autosave()


func _on_start_or_end_autosave() -> void:
	if autosave_mode == AutoSaveMode.ON_TIMELINE_JUMPS:
		perform_autosave()


## Perform an autosave.
## This method will be called automatically if the auto-save mode is enabled.
func perform_autosave() -> Error:
	return save("", true)

#endregion
