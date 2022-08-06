@tool
extends Control

var plugin_reference = null

var editor_file_dialog:EditorFileDialog

var _last_timeline_opened

signal continue_opening_resource

func _ready():
	$MarginContainer/VBoxContainer/Toolbar/Settings.button_up.connect(show_settings)
	
	# File dialog
	editor_file_dialog = EditorFileDialog.new()
	add_child(editor_file_dialog)
	
	# Open the last edited scene
	if ProjectSettings.has_setting('dialogic/editor/last_resources'):
		var directory = Directory.new();
		var path = ProjectSettings.get_setting('dialogic/editor/last_resources')[0]
		if directory.file_exists(path):
			DialogicUtil.get_dialogic_plugin()._editor_interface.inspect_object(load(path))
	
	
	# Connecting the toolbar editor mode signal
	%Toolbar.toggle_editor_view.connect(_on_toggle_editor_view)
	%Toolbar.create_timeline.connect(_on_create_timeline)
	
	$SaveConfirmationDialog.add_button('No Saving Please!', true, 'nosave')
	$SaveConfirmationDialog.hide()


func edit_timeline(object):
	if %Toolbar.is_current_unsaved():
		save_current_resource()
		await continue_opening_resource
	_load_timeline(object)
	show_timeline_editor()
	%CharacterEditor.hide()


func edit_character(object):
	if %Toolbar.is_current_unsaved():
		save_current_resource()
		await continue_opening_resource
	%CharacterEditor.load_character(object)
	_hide_timeline_editor()
	%CharacterEditor.show()


func show_settings():
	$SettingsEditor.popup_centered()
	$SettingsEditor.size = get_viewport().size/1.5
	$SettingsEditor.position -= $SettingsEditor.size / 2


func save_current_resource():
	$SaveConfirmationDialog.popup_centered()
	$SaveConfirmationDialog.title = "Unsaved changes!"
	$SaveConfirmationDialog.dialog_text = "Save before changing resource?"


func _on_SaveConfirmationDialog_confirmed():
	if _is_timeline_editor_visible:
		%TimelineEditor.save_timeline()
	elif %CharacterEditor.visible:
		%CharacterEditor.save_character()
	emit_signal("continue_opening_resource")


func _on_SaveConfirmationDialog_custom_action(action):
	$SaveConfirmationDialog.hide()
	emit_signal("continue_opening_resource")


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


func _on_settings_editor_close_requested():
	$SettingsEditor.hide()

########################################
#		Timeline editor 
########################################

func _load_timeline(object) -> void:
	_last_timeline_opened = object
	_get_timeline_editor().load_timeline(object)

func _save_timeline() -> void:
	_get_timeline_editor().save_timeline()


func show_timeline_editor() -> void:
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
	_get_timeline_editor().new_timeline()
