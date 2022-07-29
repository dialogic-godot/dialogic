@tool
extends Control

var plugin_reference = null

var editor_file_dialog:EditorFileDialog

signal continue_opening_resource

func _ready():
	$MarginContainer/VBoxContainer/Toolbar/Settings.button_up.connect(show_settings)
	set_current_margin($MarginContainer, get_theme_constant("separation", "BoxContainer") - 1)
	
	# File dialog
	editor_file_dialog = EditorFileDialog.new()
	add_child(editor_file_dialog)
	
	# Open the last edited scene
	if ProjectSettings.has_setting('dialogic/editor/last_resources'):
		var path = ProjectSettings.get_setting('dialogic/editor/last_resources')[0]
		DialogicUtil.get_dialogic_plugin()._editor_interface.inspect_object(load(path))
	
	$SaveConfirmationDialog.add_button('No Saving Please!', true, 'nosave')
	$SaveConfirmationDialog.hide()

func edit_timeline(object):
	if $'%Toolbar'.is_current_unsaved():
		save_current_resource()
		await continue_opening_resource
	get_node("%TimelineEditor").load_timeline(object)
	get_node("%TimelineEditor").show()
	get_node("%CharacterEditor").hide()

func edit_character(object):
	if $'%Toolbar'.is_current_unsaved():
		save_current_resource()
		await continue_opening_resource
	get_node("%CharacterEditor").load_character(object)
	get_node("%TimelineEditor").hide()
	get_node("%CharacterEditor").show()


func set_current_margin(node, separation):
	# TODO (No idea how this works in godot 4)
	pass
	#node.margin_top = separation
	#node.margin_left = separation
	#node.margin_right = separation * -1
	#node.margin_bottom = separation * -1

func show_settings():
	$SettingsEditor.popup_centered()

func save_current_resource():
	$SaveConfirmationDialog.popup_centered()
	$SaveConfirmationDialog.title = "Unsaved changes!"
	$SaveConfirmationDialog.dialog_text = "Save before changing resource?"

func _on_SaveConfirmationDialog_confirmed():
	if $'%TimelineEditor'.visible:
		$'%TimelineEditor'.save_timeline()
	elif $'%CharacterEditor'.visible:
		$'%CharacterEditor'.save_character()
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
