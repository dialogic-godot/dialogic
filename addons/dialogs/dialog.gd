tool
extends EditorPlugin

var _graph_editor_view
var _panel_button: Button
var _editor_selection: EditorSelection

func _enter_tree():
	_add_custom_editor_view()
	_connect_editor_signals()
	
func _exit_tree():
	_remove_custom_editor_view()
	_disconnect_editor_signals()


func _add_custom_editor_view():
	_graph_editor_view = preload("res://addons/dialogs/Editor/EditorView.tscn").instance()
	_graph_editor_view.undo_redo = get_undo_redo()
	_panel_button = add_control_to_bottom_panel(_graph_editor_view, "Dialog Editor")
	_panel_button.visible = true


func _remove_custom_editor_view():
	if _graph_editor_view:
		remove_control_from_bottom_panel(_graph_editor_view)
		_graph_editor_view.queue_free()

func _connect_editor_signals():
	_editor_selection = get_editor_interface().get_selection()
	_editor_selection.connect("selection_changed", self, "_on_selection_changed")
	connect("scene_changed", self, "_on_scene_changed")
	connect("scene_closed", self, "_on_scene_changed")
	_on_selection_changed()

func _disconnect_editor_signals():
	disconnect("scene_changed", self, "_on_scene_changed")
	disconnect("scene_closed", self, "_on_scene_changed")
	if _editor_selection:
		_editor_selection.disconnect("selection_changed", self, "_on_selection_changed")

"""
Notify the editor_view if a new DialogNode is selected. If it's another type of node, do nothing
and keep the editor open.
"""
func _on_selection_changed():
	_editor_selection = get_editor_interface().get_selection()
	var selected_nodes = _editor_selection.get_selected_nodes()
	
	print(selected_nodes)
	for node in selected_nodes:
		if node is DialogNode:
			_graph_editor_view.enable_template_editor_for(node)
			return
	_graph_editor_view.clear_template_editor()
	

func _on_scene_changed(_param):
	_graph_editor_view.clear_template_editor()
	_on_selection_changed()
