@tool
extends ColorRect

## Editor root node. Most editor functionality is handled by EditorsManager node!

var plugin_reference = null
var editors_manager : Control = null

var editor_file_dialog:EditorFileDialog

## Styling
@export var editor_tab_bg := StyleBoxFlat.new()


func _ready() -> void:
	## REFERENCES
	editors_manager = $Margin/EditorsManager
	
	## STYLING
	color = get_theme_color("base_color", "Editor")
	editor_tab_bg.border_color = get_theme_color("base_color", "Editor")
	editor_tab_bg.bg_color = get_theme_color("dark_color_2", "Editor")
	$Margin/EditorsManager.editors_holder.add_theme_stylebox_override('panel', editor_tab_bg)
	
	# File dialog
	editor_file_dialog = EditorFileDialog.new()
	add_child(editor_file_dialog)
	
	var info_message := Label.new()
	info_message.add_theme_color_override('font_color', get_theme_color("warning_color", "Editor"))
	editor_file_dialog.get_line_edit().get_parent().add_sibling(info_message)
	info_message.get_parent().move_child(info_message, info_message.get_index()-1)
	editor_file_dialog.set_meta('info_message_label', info_message)
	
	$SaveConfirmationDialog.add_button('No Saving Please!', true, 'nosave')
	$SaveConfirmationDialog.hide()


func godot_file_dialog(callable:Callable, filter:String, mode := EditorFileDialog.FILE_MODE_OPEN_FILE, window_title := "Save", current_file_name := 'New_File', saving_something := false, extra_message:String = "") -> EditorFileDialog:
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
	if extra_message:
		editor_file_dialog.get_meta('info_message_label').show()
		editor_file_dialog.get_meta('info_message_label').text = extra_message
	else:
		editor_file_dialog.get_meta('info_message_label').hide()

	if mode == EditorFileDialog.FILE_MODE_OPEN_FILE or mode == EditorFileDialog.FILE_MODE_SAVE_FILE:
		editor_file_dialog.file_selected.connect(callable)
	elif mode == EditorFileDialog.FILE_MODE_OPEN_DIR:
		editor_file_dialog.dir_selected.connect(callable)
	elif mode == EditorFileDialog.FILE_MODE_OPEN_ANY:
		editor_file_dialog.dir_selected.connect(callable)
		editor_file_dialog.file_selected.connect(callable)
	return editor_file_dialog
