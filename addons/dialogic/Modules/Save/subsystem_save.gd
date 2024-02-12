extends DialogicSubsystem

### Subsystem that manages saving and loading data.


## Emitted when a save was done.
signal saved(slot_name: String, is_autosave: bool)


## The directory that will be saved to.
const SAVE_SLOTS_DIR := "user://dialogic/saves/"

## Temporarily stores a taken screen capture when using [take_slot_image()].
enum ThumbnailMode {NONE, TAKE_AND_STORE, STORE_ONLY}
var latest_thumbnail : Image = null


enum AutoSaveMode {
	# Includes timeline start, end, and jump events.
	ON_TIMELINE_JUMPS = 0,
	# Saves after a certain time interval.
	ON_TIMER = 1,
	# Saves after every text event.
	ON_TEXT_EVENT = 2
}

const AUTO_SAVE_DEFAULT := AutoSaveMode.ON_TIMELINE_JUMPS
const AUTO_SAVE_DEFAULT_DELAY := 60

#region STATE
####################################################################################################

## Built-in, called by DialogicGameHandler.
func clear_game_state(_clear_flag := DialogicGameHandler.ClearFlags.FULL_CLEAR) -> void:
	_make_sure_slot_dir_exists()

#endregion


#region MAIN METHODS
####################################################################################################

## Saves the current state to the given slot.
## If no slot is given, the default slot is used. You can change this name in
## the Dialogic editor.
## If you want to save to the last used slot, you can get its slot name with the
## [method get_latest_slot()] method.
func save(slot_name := "", is_autosave := false, thumbnail_mode := ThumbnailMode.TAKE_AND_STORE, slot_info := {}) -> void:
	# check if to save (if this is an autosave)
	if is_autosave and !ProjectSettings.get_setting('dialogic/save/autosave', false):
		return

	if slot_name.is_empty():
		slot_name = get_default_slot()

	set_latest_slot(slot_name)

	save_file(slot_name, 'state.txt', dialogic.get_full_state())

	if thumbnail_mode == ThumbnailMode.TAKE_AND_STORE:
		take_thumbnail()
		save_slot_thumbnail(slot_name)
	elif thumbnail_mode == ThumbnailMode.STORE_ONLY:
		save_slot_thumbnail(slot_name)

	if slot_info:
		set_slot_info(slot_name, slot_info)

	saved.emit(slot_name, is_autosave)
	print('[Dialogic] Saved to slot "'+slot_name+'".')


## Loads all info from the given slot in the DialogicGameHandler (Dialogic Autoload).
## If no slot is given, the default slot is used.
## To check if something is saved in that slot use has_slot().
## If the slot does not exist, this method will fail.
func load(slot_name := "") -> void:
	if slot_name.is_empty(): slot_name = get_default_slot()

	if !has_slot(slot_name):
		printerr("[Dialogic Error] Tried loading from invalid save slot '"+slot_name+"'.")
		return
	set_latest_slot(slot_name)

	var state: Dictionary = load_file(slot_name, 'state.txt', {})
	dialogic.load_full_state(state)


## Saves a variable to a file in the given slot.
##
## Be aware, the [param slot_name] will be used a filesystem folder name.
## Some operating systems do not support every character in folder names.
## It is recommended to use only letters, numbers, and underscores.
func save_file(slot_name: String, file_name: String, data: Variant) -> void:
	if slot_name.is_empty():
		slot_name = get_default_slot()

	if not slot_name.is_empty():

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
		else:
			push_error(FileAccess.get_open_error())


## Loads a file from a given list and returns the contained info as a variable.
func load_file(slot_name:String, file_name:String, default:Variant) -> Variant:
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
## Information such as the player name can be saved here.
func set_global_info(key:String, value:Variant) -> void:
	var global_info := ConfigFile.new()
	var encryption_password := get_encryption_password()

	if encryption_password.is_empty():

		if global_info.load(SAVE_SLOTS_DIR.path_join('global_info.txt')) == OK:
			global_info.set_value('main', key, value)
			var _save_result := global_info.save(SAVE_SLOTS_DIR.path_join('global_info.txt'))

		else:
			printerr("[Dialogic Error]: Couldn't access global saved info file.")

	else:

		if global_info.load_encrypted_pass(SAVE_SLOTS_DIR.path_join('global_info.txt'), encryption_password) == OK:
			global_info.set_value('main', key, value)
			var _save_result := global_info.save_encrypted_pass(SAVE_SLOTS_DIR.path_join('global_info.txt'), encryption_password)

		else:
			printerr("[Dialogic Error]: Couldn't access global saved info file.")


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
func get_slot_names() -> Array:
	var save_folders := []

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
func delete_slot(slot_name: String) -> void:
	var path := SAVE_SLOTS_DIR.path_join(slot_name)

	if DirAccess.dir_exists_absolute(path):
		var directory := DirAccess.open(path)
		var _list_dir := directory.list_dir_begin()
		var file_name := directory.get_next()

		while not file_name.is_empty():
			var _result := directory.remove(file_name)
			file_name = directory.get_next()

		# Delete the folder.
		var _remove_result := directory.remove(SAVE_SLOTS_DIR.path_join(slot_name))


## This adds a new save folder with the given name
func add_empty_slot(slot_name: String) -> void:
	if DirAccess.dir_exists_absolute(SAVE_SLOTS_DIR):
		var directory := DirAccess.open(SAVE_SLOTS_DIR)
		var _make_dir_result := directory.make_dir(slot_name)


## Reset the state of the given save folder (or default)
func reset_slot(slot_name := "") -> void:
	if slot_name.is_empty():
		slot_name = get_default_slot()

	save_file(slot_name, 'state.txt', {})


## Returns the full path to the given slot folder
func get_slot_path(slot_name: String) -> String:
	return SAVE_SLOTS_DIR.path_join(slot_name)


## Returns the default slot name defined in the dialogic settings
func get_default_slot() -> String:
	return ProjectSettings.get_setting('dialogic/save/default_slot', 'Default')


## Returns the latest slot or empty if nothing was saved yet
func get_latest_slot() -> String:
	var latest_slot: String = ""

	if Engine.get_main_loop().has_meta('dialogic_latest_saved_slot'):
		latest_slot = Engine.get_main_loop().get_meta('dialogic_latest_saved_slot', '')

	else:
		latest_slot = get_global_info('latest_save_slot', '')
		Engine.get_main_loop().set_meta('dialogic_latest_saved_slot', latest_slot)


	if !has_slot(latest_slot):
		return ''

	return latest_slot


func set_latest_slot(slot_name:String) -> void:
	Engine.get_main_loop().set_meta('dialogic_latest_saved_slot', slot_name)
	set_global_info('latest_save_slot', slot_name)


func _make_sure_slot_dir_exists() -> void:
	if not DirAccess.dir_exists_absolute(SAVE_SLOTS_DIR):
		var _make_dir_result := DirAccess.make_dir_recursive_absolute(SAVE_SLOTS_DIR)

	var global_info_path := SAVE_SLOTS_DIR.path_join('global_info.txt')

	if not FileAccess.file_exists(global_info_path):
		var config := ConfigFile.new()
		var password := get_encryption_password()

		if password.is_empty():
			var _save_result := config.save(global_info_path)

		else:
			var _save_result := config.save_encrypted_pass(global_info_path, password)

#endregion


#region SLOT INFO
####################################################################################################

func set_slot_info(slot_name:String, info: Dictionary) -> void:
	if slot_name.is_empty():
		slot_name = get_default_slot()

	save_file(slot_name, 'info.txt', info)


func get_slot_info(slot_name := "") -> Dictionary:
	if slot_name.is_empty():
		slot_name = get_default_slot()

	return load_file(slot_name, 'info.txt', {})

#endregion


#region SLOT IMAGE
####################################################################################################

## Can be called manually to create a thumbnail.
## Then, call [method save] with ThumbnailMode.STORE_ONLY to save the game
## use the thumbnail prepared with this method.
func take_thumbnail() -> void:
	latest_thumbnail = get_viewport().get_texture().get_image()


## No need to call from outside.
## Used to store the latest thumbnail to the given slot.
func save_slot_thumbnail(slot_name: String) -> void:
	if latest_thumbnail:
		var path := get_slot_path(slot_name).path_join('thumbnail.png')
		var _save_result := latest_thumbnail.save_png(path)


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

	_result = dialogic.event_handled.connect(_on_dialogic_event_handled)
	_result = dialogic.timeline_started.connect(_on_start_or_end_autosave)
	_result = dialogic.timeline_ended.connect(_on_start_or_end_autosave)

	_on_autosave_timer_timeout()


func _get_auto_save_mode() -> AutoSaveMode:
	return ProjectSettings.get_setting('dialogic/save/autosave_mode', AUTO_SAVE_DEFAULT)


func _on_autosave_timer_timeout() -> void:
	if _get_auto_save_mode() == AutoSaveMode.ON_TIMER:
		perform_autosave()

	var auto_save_time: float = ProjectSettings.get_setting('dialogic/save/autosave_delay', AUTO_SAVE_DEFAULT_DELAY)
	autosave_timer.start(auto_save_time)


func _on_dialogic_event_handled(event: DialogicEvent) -> void:
	if event is DialogicJumpEvent:

		if _get_auto_save_mode() == AutoSaveMode.ON_TIMELINE_JUMPS:
			perform_autosave()

	if event is DialogicTextEvent:

		if _get_auto_save_mode() == AutoSaveMode.ON_TEXT_EVENT:
			perform_autosave()


func _on_start_or_end_autosave() -> void:
	if _get_auto_save_mode() == AutoSaveMode.ON_TIMELINE_JUMPS:
		perform_autosave()


## Perform an autosave.
## This method will be called automatically if the auto-save mode is enabled.
func perform_autosave() -> void:
	save("", true)
	DialogicUtil.autoload().History.save_already_seen_history()

#endregion
