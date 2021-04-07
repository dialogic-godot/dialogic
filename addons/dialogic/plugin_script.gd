tool
extends EditorPlugin

const EditorView_Scene = preload("res://addons/dialogic/Editor/EditorView.tscn")

var _editor_view
var _parts_inspector

func _enter_tree() -> void:
	_parts_inspector = load("res://addons/dialogic/Core/DialogicInspector.gd").new()
	_editor_view = EditorView_Scene.instance()
	
	add_inspector_plugin(_parts_inspector)
	
	get_editor_interface().get_editor_viewport().add_child(_editor_view)
	
	make_visible(false)


func _exit_tree() -> void:
	if _editor_view:
		_editor_view.queue_free()
	pass


func has_main_screen() -> bool:
	return true

func get_plugin_name() -> String:
	return "Dialogic"

func make_visible(visible: bool) -> void:
	if _editor_view:
		_editor_view.visible = visible
