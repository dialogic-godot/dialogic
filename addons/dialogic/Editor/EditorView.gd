tool
extends Control

var editor_file_dialog:EditorFileDialog

func _ready():
	$MarginContainer/VBoxContainer/Toolbar/Settings.connect("button_up", self, "show_settings")
	set_current_margin($MarginContainer, get_constant("separation", "BoxContainer") - 1)
	
	# File dialog
	editor_file_dialog = EditorFileDialog.new()
	add_child(editor_file_dialog)
	
	# Open the last edited scene
	if ProjectSettings.has_setting('dialogic/editor/current_timeline_path'):
		var timeline_path = ProjectSettings.get_setting('dialogic/editor/current_timeline_path')
		var file = File.new()
		if file.file_exists(timeline_path):
			edit_timeline(load(timeline_path))
		else:
			ProjectSettings.clear('dialogic/editor/current_timeline_path')


func edit_timeline(object):
	get_node("%TimelineEditor").load_timeline(object)
	get_node("%TimelineEditor").show()
	get_node("%CharacterEditor").hide()

func edit_character(object):
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
	
