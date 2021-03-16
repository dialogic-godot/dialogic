tool
extends EditorPlugin

var _editor_view
var _parts_inspector

func _enter_tree() -> void:
	_parts_inspector = load("res://addons/dialogic/Other/inspector_timeline_picker.gd").new()
	add_inspector_plugin(_parts_inspector)
	_add_custom_editor_view()
	get_editor_interface().get_editor_viewport().add_child(_editor_view)
	add_autoload_singleton('DialogicSingleton', "res://addons/dialogic/Other/DialogicSingleton.gd")
	make_visible(false)


func _ready():
	if Engine.editor_hint:
		# Make sure the core files exist 
		DialogicUtil.init_dialogic_files()
		# Force Godot to show the dialogic folder
		get_editor_interface().get_resource_filesystem().scan()


func _exit_tree() -> void:
	_remove_custom_editor_view()
	remove_inspector_plugin(_parts_inspector)


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


func _remove_custom_editor_view():
	if _editor_view:
		remove_control_from_bottom_panel(_editor_view)
		_editor_view.queue_free()
