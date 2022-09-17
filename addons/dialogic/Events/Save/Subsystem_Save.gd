extends DialogicSubsystem

const SAVE_SLOTS_DIR = "user://dialogic/saves/"
var saved_image = null
####################################################################################################
##					STATE
####################################################################################################

func clear_game_state():
	_make_sure_slot_dir_exists()

func load_game_state():
	pass

####################################################################################################
##					MAIN METHODS
####################################################################################################

func save(slot_name:String = '', is_autosave:bool = false, create_thumbnail:bool= true, slot_info :Dictionary = {}):
	# check if to save (if this is a autosave)
	if is_autosave and !DialogicUtil.get_project_setting('dialogic/save/autosave', false):
		return
	
	slot_name = this_or_current_slot(slot_name)
	if slot_name.is_empty(): return
	
	save_file(slot_name, 'state.txt', dialogic.get_full_state())
	
	if create_thumbnail:
		take_slot_image()
		store_slot_image(slot_name)
	if slot_info:
		store_slot_info(slot_name, slot_info)
	
	print('[Dialogic] Saved to slot "'+slot_name+'".')


func load(slot_name:String):
	set_latest_slot(slot_name)
	dialogic.load_full_state(load_file(slot_name, 'state.txt', {}))

func save_file(slot_name:String, file_name:String, data) -> int:
	slot_name = this_or_current_slot(slot_name)
	if slot_name.is_empty(): return ERR_BUG
	
	if slot_name.is_empty() in get_slot_names():
		add_empty_slot(slot_name)
	
	var file = File.new()
	var err = file.open(SAVE_SLOTS_DIR.path_join(slot_name).path_join(file_name), File.WRITE)
	if err == OK:
		file.store_var(data, true)
		file.close()
	return err

func load_file(slot_name:String, file_name:String, default):
	slot_name = this_or_current_slot(slot_name)
	if slot_name.is_empty(): return
	
	var file := File.new()
	if file.open(get_slot_path(slot_name).path_join(file_name), File.READ) != OK:
		file.close()
		return default
	
	var data = file.get_var(true)
	file.close()
	
	return data

####################################################################################################
##					SLOT HELPERS
####################################################################################################
func get_slot_names() -> Array:
	var save_folders = []
	var directory := Directory.new()
	if directory.open(SAVE_SLOTS_DIR) != OK:
		print("[Dialogic] Error: Failed to access save directory.")
		return []
	
	directory.list_dir_begin()
	var file_name = directory.get_next()
	while file_name != "":
		if directory.current_is_dir() and not file_name.begins_with("."):
			save_folders.append(file_name)
		file_name = directory.get_next()

	return save_folders

func has_slot(slot_name:String) -> bool:
	return slot_name in get_slot_names()

func remove_slot(slot_name:String) -> void:
	var directory := Directory.new()
	if directory.open(SAVE_SLOTS_DIR.path_join(slot_name)) != OK:
		print("[D] Error: Failed to access save folder '"+slot_name+"'.")
		return
	
	# first remove the content, becaus deleting filled folders isn't allowed
	directory.list_dir_begin()
	var file_name = directory.get_next()
	while file_name != "":
		directory.remove(file_name)
		file_name = directory.get_next()
	# then delete folder
	directory.remove(SAVE_SLOTS_DIR.path_join(slot_name))

# this adds a new save folder with the given name
func add_empty_slot(slot_name: String) -> void:
	var directory := Directory.new()
	if directory.open(SAVE_SLOTS_DIR) != OK:
		print("[D] Error: Failed to access working directory.")
		return 
	directory.make_dir(slot_name)

# reset the state of the given save folder (or default)
func reset_slot(slot_name: String = '') -> void:
	slot_name = this_or_current_slot(slot_name)
	if slot_name.is_empty(): return
	
	var file = File.new()
	file.store_var({})
	save_file(slot_name, 'state.txt', file)

func get_slot_path(slot_name:String) -> String:
	return SAVE_SLOTS_DIR.path_join(slot_name)


func get_latest_slot() -> String:
	return DialogicUtil.get_project_setting('dialogic/save/latest_save', DialogicUtil.get_project_setting('dialogic/save/default_slot', 'Default'))

func set_latest_slot(slot_name:String) -> void:
	ProjectSettings.set_setting('dialogic/save/latest_save', slot_name)
	ProjectSettings.save()


func _make_sure_slot_dir_exists() -> void:
	var directory := Directory.new()
	if not directory.dir_exists(SAVE_SLOTS_DIR):
		directory.make_dir_recursive(SAVE_SLOTS_DIR)

func this_or_current_slot(slot_name:String):
	if slot_name: set_latest_slot(slot_name)
	return slot_name if slot_name.is_empty() else get_latest_slot()

####################################################################################################
##					SLOT INFO
####################################################################################################
func store_slot_info(slot_name:String, info: Dictionary) -> void:
	slot_name = this_or_current_slot(slot_name)
	if slot_name.is_empty(): return
	save_file(slot_name, 'info.txt', info)

func get_slot_info(slot_name:String = '') -> Dictionary:
	slot_name = this_or_current_slot(slot_name)
	if slot_name.is_empty(): return {}
	return load_file(slot_name, 'info.txt', {})

####################################################################################################
##					SLOT IMAGE
####################################################################################################

func take_slot_image() -> void:
	saved_image = get_viewport().get_texture().get_image()
	saved_image.flip_y()

func store_slot_image(slot_name:String) -> void:
	if saved_image:
		saved_image.save_png(get_slot_path(slot_name).path_join('thumbnail.png'))

func get_slot_image(slot_name:String) -> ImageTexture:
	slot_name = this_or_current_slot(slot_name)
	if slot_name.is_empty(): return null
	var file = File.new()
	if file.open(get_slot_path(slot_name).path_join('thumbnail.png'), File.READ) == OK:
		var buffer = file.get_buffer(file.get_len())
		file.close()

		var image = Image.new()
		image.load_png_from_buffer(buffer)

		var image_texture = ImageTexture.new()
		image_texture.create_from_image(image)
		return image_texture
	return null

####################################################################################################
##					AUTOSAVE
####################################################################################################
var autosave_timer = Timer.new()

func _ready():
	autosave_timer.one_shot = true
	DialogicUtil.update_timer_process_callback(autosave_timer)
	autosave_timer.name = "AutosaveTimer"
	autosave_timer.timeout.connect(_on_autosave_timer_timeout)
	add_child(autosave_timer)
	dialogic.event_handled.connect(_on_dialogic_event_handled)
	dialogic.timeline_started.connect(autosave_start_end)
	dialogic.timeline_ended.connect(autosave_start_end)
	_on_autosave_timer_timeout()

func _on_autosave_timer_timeout():
	if DialogicUtil.get_project_setting('dialogic/save/autosave_mode', 0) == 1:
		save('', true)
	autosave_timer.start(DialogicUtil.get_project_setting('dialogic/save/autosave_delay', 60))

func _on_dialogic_event_handled(event):
	if event is DialogicJumpEvent:
		if DialogicUtil.get_project_setting('dialogic/save/autosave_mode', 0) == 1:
			save('', true)
	if event is DialogicTextEvent:
		if DialogicUtil.get_project_setting('dialogic/save/autosave_mode', 0) == 1:
			save('', true)

func autosave_start_end():
	if DialogicUtil.get_project_setting('dialogic/save/autosave_mode', 0) == 1:
		save('', true)
