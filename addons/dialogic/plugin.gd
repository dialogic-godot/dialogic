tool
extends EditorPlugin

var _editor_view
var _parts_inspector
var _export_plugin
var _editor_interface

signal dialogic_save

func _init():
	self.name = 'DialogicPlugin'
	

func _enter_tree() -> void:
	_add_custom_editor_view()
	_editor_interface = get_editor_interface()
	get_editor_interface().get_editor_viewport().add_child(_editor_view)
	make_visible(false)


func _ready():
	if Engine.editor_hint:
		# Force Godot to show the dialogic folder
		get_editor_interface().get_resource_filesystem().scan()
	

func _exit_tree() -> void:
	_remove_custom_editor_view()
	remove_inspector_plugin(_parts_inspector)
	remove_export_plugin(_export_plugin)


func has_main_screen():
	return true


func get_plugin_name():
	return "Dialogic"


func make_visible(visible):
	if _editor_view:
		_editor_view.visible = visible


func get_plugin_icon():
	var _scale = get_editor_interface().get_editor_scale()
	var _theme = 'dark'
	# https://github.com/godotengine/godot-proposals/issues/572
	if get_editor_interface().get_editor_settings().get_setting("interface/theme/base_color").v > 0.5:
		_theme = 'light'
	return load("res://addons/dialogic/Images/Plugin/plugin-editor-icon-" + _theme + "-theme-" + str(_scale) + ".svg")


func _add_custom_editor_view():
	_editor_view = preload("res://addons/dialogic/Editor/EditorView.tscn").instance()


func _remove_custom_editor_view():
	if _editor_view:
		remove_control_from_bottom_panel(_editor_view)
		_editor_view.queue_free()


func save_external_data():
	emit_signal('dialogic_save')


func handles(object):
	if object is DialogicTimeline:
		return true


func edit(object):
	make_visible(true)
	if object is DialogicTimeline:
		_editor_view.edit_timeline(object)


#func enable_plugin():
#	add_autoload_singleton("Dialogic", "res://addons/dialogic/Other/DialogicGameHandler.gd")

#func disable_plugin():
#	remove_autoload_singleton("Dialogic")
