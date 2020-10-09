tool
extends EditorPlugin

var _editor_view # This is the plugin Scene
var _panel_button: Button
var _editor_selection: EditorSelection

func _enter_tree():
	_add_custom_editor_view()
	
	get_editor_interface().get_editor_viewport().add_child(_editor_view)
	# Hide the main panel. Very much required.
	make_visible(false)
	
func _exit_tree():
	_remove_custom_editor_view()

func has_main_screen():
	return true

func get_plugin_name():
	return "Dialogic"

func make_visible(visible):
	if _editor_view:
		_editor_view.visible = visible

func get_plugin_icon():
	return preload("res://addons/dialogic/Images/plugin-editor-icon.svg")
	
func _add_custom_editor_view():
	_editor_view = preload("res://addons/dialogic/Editor/EditorView.tscn").instance()
	_editor_view.plugin_reference = self
	_editor_view.undo_redo = get_undo_redo()
	#_panel_button = add_control_to_bottom_panel(_editor_view, "Dialog Editor")
	#_panel_button.visible = true


func _remove_custom_editor_view():
	if _editor_view:
		remove_control_from_bottom_panel(_editor_view)
		_editor_view.queue_free()
