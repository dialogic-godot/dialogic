tool
extends Control

var editor_file_dialog:EditorFileDialog

func _ready():
	$MarginContainer/VBoxContainer/Toolbar/Settings.connect("button_up", self, "show_settings")
	set_current_margin($MarginContainer, get_constant("separation", "BoxContainer") - 1)
	
	# File dialog
	editor_file_dialog = EditorFileDialog.new()
	add_child(editor_file_dialog)


func edit_timeline(object):
	get_node("%TimelineEditor").load_timeline(object)


func set_current_margin(node, separation):
	node.margin_top = separation
	node.margin_left = separation
	node.margin_right = separation * -1
	node.margin_bottom = separation * -1

func show_settings():
	$SettingsEditor.popup_centered()


func godot_file_dialog(object, method, filter, mode = EditorFileDialog.MODE_OPEN_FILE):
	for connection in editor_file_dialog.get_signal_connection_list('file_selected'):
		editor_file_dialog.disconnect('file_selected', connection.target, connection.method)
	editor_file_dialog.mode = mode
	editor_file_dialog.clear_filters()
	editor_file_dialog.popup_centered_ratio(0.75)
	editor_file_dialog.add_filter(filter)
	editor_file_dialog.window_title = "Save new Timeline"
	editor_file_dialog.current_file = "New_Timeline"
	if mode == EditorFileDialog.MODE_OPEN_FILE or EditorFileDialog.MODE_SAVE_FILE:
		editor_file_dialog.connect('file_selected', object, method)
	elif mode == EditorFileDialog.MODE_OPEN_DIR:
		editor_file_dialog.connect('dir_selected', object, method)
	return editor_file_dialog
	
