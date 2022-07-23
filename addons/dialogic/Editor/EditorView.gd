tool
extends Control

var editor_file_dialog:EditorFileDialog

signal continue_opening_resource

func _ready():
	$MarginContainer/VBoxContainer/Toolbar/Settings.connect("button_up", self, "show_settings")
	set_current_margin($MarginContainer, get_constant("separation", "BoxContainer") - 1)
	
	# File dialog
	editor_file_dialog = EditorFileDialog.new()
	add_child(editor_file_dialog)
	
	# Open the last edited scene
	if ProjectSettings.has_setting('dialogic/editor/last_resources'):
		var path = ProjectSettings.get_setting('dialogic/editor/last_resources')[0]
		var dialogic_plugin = get_tree().root.get_node('EditorNode/DialogicPlugin')
		dialogic_plugin._editor_interface.inspect_object(load(path))
	
	$SaveConfirmationDialog.add_button('No Saving Please!', true, 'nosave')

func edit_timeline(object):
	if $'%Toolbar'.is_current_unsaved():
		save_current_resource()
		yield(self, 'continue_opening_resource')
	get_node("%TimelineEditor").load_timeline(object)
	get_node("%TimelineEditor").show()
	get_node("%CharacterEditor").hide()

func edit_character(object):
	if $'%Toolbar'.is_current_unsaved():
		save_current_resource()
		yield(self, 'continue_opening_resource')
	get_node("%CharacterEditor").load_character(object)
	get_node("%TimelineEditor").hide()
	get_node("%CharacterEditor").show()


func set_current_margin(node, separation):
	node.margin_top = separation
	node.margin_left = separation
	node.margin_right = separation * -1
	node.margin_bottom = separation * -1

func show_settings():
	$SettingsEditor.popup_centered()

func save_current_resource():
	$SaveConfirmationDialog.popup_centered()
	$SaveConfirmationDialog.window_title = "Unsaved changes!"
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

func godot_file_dialog(object, method, filter, mode = EditorFileDialog.MODE_OPEN_FILE, window_title = "Save", current_file_name = 'New_File'):
	for connection in editor_file_dialog.get_signal_connection_list('file_selected')+editor_file_dialog.get_signal_connection_list('dir_selected'):
		editor_file_dialog.disconnect('file_selected', connection.target, connection.method)
	editor_file_dialog.mode = mode
	editor_file_dialog.clear_filters()
	editor_file_dialog.popup_centered_ratio(0.75)
	editor_file_dialog.add_filter(filter)
	editor_file_dialog.window_title = window_title
	editor_file_dialog.current_file = current_file_name
	if mode == EditorFileDialog.MODE_OPEN_FILE or mode == EditorFileDialog.MODE_SAVE_FILE:
		editor_file_dialog.connect('file_selected', object, method, [], CONNECT_ONESHOT)
	elif mode == EditorFileDialog.MODE_OPEN_DIR:
		editor_file_dialog.connect('dir_selected', object, method, [], CONNECT_ONESHOT)
	elif mode == EditorFileDialog.MODE_OPEN_ANY:
		editor_file_dialog.connect('dir_selected', object, method, [], CONNECT_ONESHOT)
		editor_file_dialog.connect('file_selected', object, method, [], CONNECT_ONESHOT)
	return editor_file_dialog



