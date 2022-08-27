@tool
extends Control

var plugin_reference = null

var editor_file_dialog:EditorFileDialog

var _last_timeline_opened

var event_script_cache: Array = []
var character_directory: Dictionary = {}

signal continue_opening_resource

func _ready():
	print(str(Time.get_ticks_msec()) + ": Starting EditorView.ready()")
	rebuild_event_script_cache()
	rebuild_character_directory()
	$MarginContainer/VBoxContainer/Toolbar/Settings.button_up.connect(settings_pressed)
	
	# File dialog
	editor_file_dialog = EditorFileDialog.new()
	add_child(editor_file_dialog)
	
	# Open the last edited scene
	open_last_resource()
	
	# Hide the character editor by default and connect its signals
	%CharacterEditor.hide()
	%CharacterEditor.set_resource_unsaved.connect(%Toolbar.set_resource_unsaved)
	%CharacterEditor.set_resource_saved.connect(%Toolbar.set_resource_saved)
	%CharacterEditor.character_loaded.connect(%Toolbar.load_character)
	
	# Connecting the toolbar editor mode signal
	%Toolbar.toggle_editor_view.connect(_on_toggle_editor_view)
	%Toolbar.create_timeline.connect(_on_create_timeline)
	%Toolbar.play_timeline.connect(_on_play_timeline)
	
	$SaveConfirmationDialog.add_button('No Saving Please!', true, 'nosave')
	$SaveConfirmationDialog.hide()

func open_last_resource():
	print(str(Time.get_ticks_msec()) + ": Starting EditorView.open_last_resource()")
	if ProjectSettings.has_setting('dialogic/editor/last_resources'):
		var directory := Directory.new();
		var path :String= ProjectSettings.get_setting('dialogic/editor/last_resources')[0]
		if directory.file_exists(path):
			DialogicUtil.get_dialogic_plugin().editor_interface.inspect_object(load(path))
	

func edit_timeline(object):
	print(str(Time.get_ticks_msec()) + ": Starting EditorView.edit_timeline()")
	if %Toolbar.is_current_unsaved():
		save_current_resource()
		await continue_opening_resource
	_load_timeline(object)
	show_timeline_editor()
	%CharacterEditor.hide()
	%SettingsEditor.close()


func edit_character(object):
	if %Toolbar.is_current_unsaved():
		save_current_resource()
		await continue_opening_resource
	%CharacterEditor.load_character(object)
	_hide_timeline_editor()
	%CharacterEditor.show()
	%SettingsEditor.close()


func settings_pressed():
	if %SettingsEditor.visible:
		open_last_resource()
	else:
		if %Toolbar.is_current_unsaved():
			save_current_resource()
			await continue_opening_resource
		%SettingsEditor.show()
		_hide_timeline_editor()
		%Toolbar.hide_timeline_tool_buttons()
		%CharacterEditor.hide()

func save_current_resource():
	$SaveConfirmationDialog.popup_centered()
	$SaveConfirmationDialog.title = "Unsaved changes!"
	$SaveConfirmationDialog.dialog_text = "Save before changing resource?"


func _on_SaveConfirmationDialog_confirmed():
	print(str(Time.get_ticks_msec()) + ": Starting EditorView._saveconfirmation_confirmed()")
	if _is_timeline_editor_visible:
		%TimelineEditor.save_timeline()
	elif %CharacterEditor.visible:
		%CharacterEditor.save_character()
	emit_signal("continue_opening_resource")


func _on_SaveConfirmationDialog_custom_action(action):
	$SaveConfirmationDialog.hide()
	emit_signal("continue_opening_resource")
	
func rebuild_event_script_cache():
	event_script_cache = []
	for script in DialogicUtil.get_event_scripts():
		var x = load(script).new()
		x.set_meta("script_path", script)
		if script != "res://addons/dialogic/Events/End Branch/event.gd":
			event_script_cache.push_back(x)

				

	# Events are checked in order while testing them. EndBranch needs to be first, Text needs to be last
	var x = load("res://addons/dialogic/Events/End Branch/event.gd").new()
	x.set_meta("script_path", "res://addons/dialogic/Events/End Branch/event.gd")
	event_script_cache.push_front(x)
			
	for i in event_script_cache.size():
		if event_script_cache[i].get_meta("script_path") == "res://addons/dialogic/Events/Text/event.gd":
			event_script_cache.push_back(event_script_cache[i])
			event_script_cache.remove_at(i)
			break
			
	print(event_script_cache)
	print(event_script_cache.size())

func rebuild_character_directory() -> void:
	var characters: Array = DialogicUtil.list_resources_of_type(".dch")
		
	for character in characters:
		var charfile: DialogicCharacter= load(character)
		character_directory[character] = charfile


func godot_file_dialog(callable, filter, mode = EditorFileDialog.FILE_MODE_OPEN_FILE, window_title = "Save", current_file_name = 'New_File', saving_something = false):
	for connection in editor_file_dialog.file_selected.get_connections():
		editor_file_dialog.file_selected.disconnect(connection.callable)
	for connection in editor_file_dialog.dir_selected.get_connections():
		editor_file_dialog.dir_selected.disconnect(connection.callable)
	editor_file_dialog.file_mode = mode
	editor_file_dialog.clear_filters()
	editor_file_dialog.popup_centered_ratio(0.75)
	editor_file_dialog.add_filter(filter)
	editor_file_dialog.title = window_title
	editor_file_dialog.current_file = current_file_name
	editor_file_dialog.disable_overwrite_warning = !saving_something
	if mode == EditorFileDialog.FILE_MODE_OPEN_FILE or mode == EditorFileDialog.FILE_MODE_SAVE_FILE:
		editor_file_dialog.file_selected.connect(callable)
	elif mode == EditorFileDialog.FILE_MODE_OPEN_DIR:
		editor_file_dialog.dir_selected.connect(callable)
	elif mode == EditorFileDialog.FILE_MODE_OPEN_ANY:
		editor_file_dialog.dir_selected.connect(callable)
		editor_file_dialog.file_selected.connect(callable)
	return editor_file_dialog


########################################
#		Timeline editor 
########################################

func _load_timeline(object) -> void:
	print(str(Time.get_ticks_msec()) + ": Starting EditorView._load_timeline()")
	_last_timeline_opened = object
	object = process_timeline(object)
	_get_timeline_editor().load_timeline(object)


func show_timeline_editor() -> void:
	print(str(Time.get_ticks_msec()) + ": Starting EditorView.show_timeline_editor()")
	if DialogicUtil.get_project_setting('dialogic/editor_mode', 'visual') == 'visual':
		%TextEditor.hide()
		%TimelineEditor.show()
	else:
		%TimelineEditor.hide()
		%TextEditor.show()


func _hide_timeline_editor() -> void:
	%TimelineEditor.hide()
	%TextEditor.hide()


func _is_timeline_editor_visible() -> bool:
	if _get_timeline_editor().visible:
		return true
	return false


func _get_timeline_editor() -> Node:
	if DialogicUtil.get_project_setting('dialogic/editor_mode', 'visual') == 'visual':
		return %TimelineEditor
	else:
		return %TextEditor
	

func _on_toggle_editor_view(mode:String) -> void:
	print(str(Time.get_ticks_msec()) + ": Starting EditorView._on_toggle_editor_view()")
	%CharacterEditor.visible = false
	
	if mode == 'visual':
		%TextEditor.save_timeline()
		%TextEditor.hide()
		%TextEditor.clear_timeline()
		%TimelineEditor.show()
	else:
		%TimelineEditor.save_timeline()
		%TimelineEditor.hide()
		%TimelineEditor.clear_timeline()
		%TextEditor.show()
	
	# After showing the proper timeline, open it to edit
	_load_timeline(_last_timeline_opened)
	
	
func _on_create_timeline():
	print(str(Time.get_ticks_msec()) + ": Starting EditorView._on_create_timeline()")
	_get_timeline_editor().new_timeline()


func _on_play_timeline():
	if _get_timeline_editor().current_timeline:
		var dialogic_plugin = DialogicUtil.get_dialogic_plugin()
		# Save the current opened timeline
		ProjectSettings.set_setting('dialogic/editor/current_timeline_path', _get_timeline_editor().current_timeline.resource_path)
		ProjectSettings.save()
		DialogicUtil.get_dialogic_plugin().editor_interface.play_custom_scene("res://addons/dialogic/Other/TestTimelineScene.tscn")


#########################################################
###				TIMELINE PROCESSOR
########################################################

func process_timeline(timeline: DialogicTimeline) -> DialogicTimeline:


	if timeline._events_processed:
		print(str(Time.get_ticks_msec()) + ": Timeline is already processed")
		return timeline
	else:
		print(str(Time.get_ticks_msec()) + ": Starting process unloaded timeline")
		var end_event: DialogicEndBranchEvent 
		for i in event_script_cache:
			if i.get_meta("script_path") == "res://addons/dialogic/Events/End Branch/event.gd":
					end_event = i.duplicate()
					break
		
		var prev_indent := ""
		var events := []
		
		# this is needed to add a end branch event even to empty conditions/choices
		var prev_was_opener := false
		
		var lines := timeline._events
		var idx := -1
		
		while idx < len(lines)-1:
			idx += 1
			var line :String = lines[idx]
			
			
			var line_stripped :String = line.strip_edges(true, false)
			if line_stripped.is_empty():
				continue
			var indent :String= line.substr(0,len(line)-len(line_stripped))
			
			if len(indent) < len(prev_indent):
				for i in range(len(prev_indent)-len(indent)):
					events.append(end_event.duplicate())
			
			elif prev_was_opener and len(indent) == len(prev_indent):
				events.append(end_event.duplicate())
			prev_indent = indent
			var event_content :String = line_stripped

			var event :Variant
			for i in event_script_cache:
				if i._test_event_string(event_content):
					event = i.duplicate()
					break

			# add the following lines until the event says it's full there is an empty line or the indent changes
			while !event.is_string_full_event(event_content):
				idx += 1
				if idx == len(lines):
					break
				var following_line :String = lines[idx]
				var following_line_stripped :String = following_line.strip_edges(true, false)
				var following_line_indent :String = following_line.substr(0,len(following_line)-len(following_line_stripped))
				if following_line_stripped.is_empty():
					break
				if following_line_indent != indent:
					idx -= 1
					break
				event_content += "\n"+following_line_stripped
			
			event_content = event_content.replace("\n"+indent, "\n")
			

			# Unlike at runtime, for some reason here the event scripts can't access the scene tree to get to the character directory, so we will need to pass it to it before processing
			
			if event['event_name'] == 'Character' || event['event_name'] == 'Text':
				event.set_meta('editor_character_directory', character_directory)

			event._load_from_string(event_content)
			event['event_node_as_text'] = event_content
			
			events.append(event)
			prev_was_opener = event.can_contain_events
			
		

		if !prev_indent.is_empty():
			for i in range(len(prev_indent)):
				events.append(end_event.duplicate())
		
		timeline._events = events	
		timeline._events_processed = true
		print(str(Time.get_ticks_msec()) + ": Finished process unloaded timeline")	
		return timeline
