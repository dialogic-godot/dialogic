extends DialogicSubsystem

### Subsystem that manages saving and loading data.


## Emitted when a save was done. Keys of the info dictionary are "slot_name" and "is_autosave".
signal saved(info:Dictionary)

## The directory that will be saved to.
const SAVE_SLOTS_DIR := "user://dialogic/saves/"

## Temporarily stores a taken screen capture when using [take_slot_image()].
enum THUMBNAIL_MODE {NONE, TAKE_AND_STORE, STORE_ONLY}
var latest_thumbnail : Image = null


####################################################################################################
##					STATE
####################################################################################################

## Built-in, called by DialogicGameHandler.
func clear_game_state():
	_make_sure_slot_dir_exists()


####################################################################################################
##					MAIN METHODS
####################################################################################################

## Saves the current state to the given slot. 
## If no slot is given the default slot is used (name can be set in the dialogic settings)
## If you want to change to the current slot use save(Dialogic.Save.get_latest_slot())
func save(slot_name:String = '', is_autosave:bool = false, thumbnail_mode:THUMBNAIL_MODE=THUMBNAIL_MODE.TAKE_AND_STORE, slot_info :Dictionary = {}):
	# check if to save (if this is an autosave)
	if is_autosave and !DialogicUtil.get_project_setting('dialogic/save/autosave', false):
		return
	
	if slot_name.is_empty():
		slot_name = get_default_slot()
	
	set_latest_slot(slot_name)
	
	save_file(slot_name, 'state.txt', dialogic.get_full_state())
	
	if thumbnail_mode == THUMBNAIL_MODE.TAKE_AND_STORE:
		take_thumbnail()
		save_slot_thumbnail(slot_name)
	elif thumbnail_mode == THUMBNAIL_MODE.STORE_ONLY:
		save_slot_thumbnail(slot_name)
	
	if slot_info:
		store_slot_info(slot_name, slot_info)
	
	saved.emit({"slot_name":slot_name, "is_autosave": is_autosave})
	print('[Dialogic] Saved to slot "'+slot_name+'".')


## Loads all info from the given slot in the DialogicGameHandler (Dialogic Autoload).
## If no slot is given, the default slot is used.
## To check if something is saved in that slot use has_slot(). 
## If the slot does not exist, this method will fail. 
func load(slot_name:String):
	if slot_name.is_empty(): slot_name = get_default_slot()
	
	if !has_slot(slot_name):
		printerr("[Dialogic Error] Tried loading from invalid save slot '"+slot_name+"'.")
		return
	set_latest_slot(slot_name)
	dialogic.load_full_state(load_file(slot_name, 'state.txt', {}))


# Saves a variable to a file in the given slot.
func save_file(slot_name:String, file_name:String, data:Variant) -> void:
	if slot_name.is_empty(): slot_name = get_default_slot()
	if not slot_name.is_empty():
		if !has_slot(slot_name):
			add_empty_slot(slot_name)
		
		var file = FileAccess.open(SAVE_SLOTS_DIR.path_join(slot_name).path_join(file_name), FileAccess.WRITE)
		file.store_var(data, true)


## Loads a file from a given list and returns the contained info as a variable.
func load_file(slot_name:String, file_name:String, default:Variant) -> Variant:
	if slot_name.is_empty(): slot_name = get_default_slot()
	
	var path := get_slot_path(slot_name).path_join(file_name)
	
	if FileAccess.file_exists(path):
		var data = FileAccess.open(path, FileAccess.READ).get_var(true)
		return data
	return default



func set_global_info(key:String, value:Variant) -> void:
	var global_info := ConfigFile.new()
	if global_info.load(SAVE_SLOTS_DIR.path_join('global_info.txt')) == OK:
		global_info.set_value('main', key, value)
		global_info.save(SAVE_SLOTS_DIR.path_join('global_info.txt'))
	else:
		printerr("[Dialogic Error]: Couldn't access global saved info file.")


func get_global_info(key:String, default:Variant) -> Variant:
	var global_info := ConfigFile.new()
	if global_info.load(SAVE_SLOTS_DIR.path_join('global_info.txt')) == OK:
		return global_info.get_value('main', key, default)
	printerr("[Dialogic Error]: Couldn't access global saved info file.")
	return default


####################################################################################################
##					SLOT HELPERS
####################################################################################################
## Returns a list of all available slots. Usefull for iterating over all slots 
## (for example to build a UI list). 
func get_slot_names() -> Array:
	var save_folders := []

	if DirAccess.dir_exists_absolute(SAVE_SLOTS_DIR):
		var directory := DirAccess.open(SAVE_SLOTS_DIR)
		directory.list_dir_begin()
		var file_name := directory.get_next()
		while file_name != "":
			if directory.current_is_dir() and not file_name.begins_with("."):
				save_folders.append(file_name)
			file_name = directory.get_next()
		return save_folders
	return []


## Returns true if the given slot exists.
func has_slot(slot_name:String) -> bool:
	if slot_name.is_empty(): slot_name = get_default_slot()
	return slot_name in get_slot_names()


## Removes all the given slot along with all it's info/files.
func delete_slot(slot_name:String) -> void:
	var path := SAVE_SLOTS_DIR.path_join(slot_name)
	
	if DirAccess.dir_exists_absolute(path):
		var directory := DirAccess.open(path)
		directory.list_dir_begin()
		var file_name := directory.get_next()
		while file_name != "":
			directory.remove(file_name)
			file_name = directory.get_next()
		# then delete folder
		directory.remove(SAVE_SLOTS_DIR.path_join(slot_name))


## this adds a new save folder with the given name
##
func add_empty_slot(slot_name: String) -> void:
	if DirAccess.dir_exists_absolute(SAVE_SLOTS_DIR):
		var directory := DirAccess.open(SAVE_SLOTS_DIR)
		directory.make_dir(slot_name)


## reset the state of the given save folder (or default)
func reset_slot(slot_name: String = '') -> void:
	if slot_name.is_empty(): slot_name = get_default_slot()

	save_file(slot_name, 'state.txt', {})


## Returns the full path to the given slot folder
func get_slot_path(slot_name:String) -> String:
	return SAVE_SLOTS_DIR.path_join(slot_name)


## Returns the default slot name defined in the dialogic settings
func get_default_slot() -> String:
	return DialogicUtil.get_project_setting('dialogic/save/default_slot', 'Default')


## Returns the latest slot or empty if nothing was saved yet
func get_latest_slot() -> String:
	var latest_slot :String = ""
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
		DirAccess.make_dir_recursive_absolute(SAVE_SLOTS_DIR)
	if not FileAccess.file_exists(SAVE_SLOTS_DIR.path_join('global_info.txt')):
		FileAccess.open(SAVE_SLOTS_DIR.path_join('global_info.txt'), FileAccess.WRITE)


####################################################################################################
##					SLOT INFO
####################################################################################################

func store_slot_info(slot_name:String, info: Dictionary) -> void:
	if slot_name.is_empty(): slot_name = get_default_slot()
	save_file(slot_name, 'info.txt', info)


func get_slot_info(slot_name:String = '') -> Dictionary:
	if slot_name.is_empty(): slot_name = get_default_slot()
	return load_file(slot_name, 'info.txt', {})


####################################################################################################
##					SLOT IMAGE
####################################################################################################

## Can be called manually to create a thumbnail. Then call save() with THUMBNAIL_MODE.STORE_ONLY
func take_thumbnail() -> void:
	latest_thumbnail = get_viewport().get_texture().get_image()


## No need to call from outside. Used to store the latest thumbnail to the given slot.
func save_slot_thumbnail(slot_name:String) -> void:
	if latest_thumbnail:
		latest_thumbnail.save_png(get_slot_path(slot_name).path_join('thumbnail.png'))


## Returns an ImageTexture containing the thumbnail of that slot.
func get_slot_thumbnail(slot_name:String) -> ImageTexture:
	if slot_name.is_empty(): slot_name = get_default_slot()
	
	var path := get_slot_path(slot_name).path_join('thumbnail.png')
	if FileAccess.file_exists(path):
		return ImageTexture.create_from_image(Image.load_from_file(path))
	return null


####################################################################################################
##					AUTOSAVE
####################################################################################################
## Reference to the autosave timer.
var autosave_timer := Timer.new()


func _ready() -> void:
	autosave_timer.one_shot = true
	DialogicUtil.update_timer_process_callback(autosave_timer)
	autosave_timer.name = "AutosaveTimer"
	autosave_timer.timeout.connect(_on_autosave_timer_timeout)
	add_child(autosave_timer)
	dialogic.event_handled.connect(_on_dialogic_event_handled)
	dialogic.timeline_started.connect(autosave_start_end)
	dialogic.timeline_ended.connect(autosave_start_end)
	_on_autosave_timer_timeout()


func _on_autosave_timer_timeout() -> void:
	if DialogicUtil.get_project_setting('dialogic/save/autosave_mode', 0) == 1:
		save('', true)
	autosave_timer.start(DialogicUtil.get_project_setting('dialogic/save/autosave_delay', 60))


func _on_dialogic_event_handled(event: DialogicEvent) -> void:
	if event is DialogicJumpEvent:
		if DialogicUtil.get_project_setting('dialogic/save/autosave_mode', 0) == 1:
			save('', true)
	if event is DialogicTextEvent:
		if DialogicUtil.get_project_setting('dialogic/save/autosave_mode', 0) == 1:
			save('', true)


func autosave_start_end() -> void:
	if DialogicUtil.get_project_setting('dialogic/save/autosave_mode', 0) == 1:
		save('', true)
