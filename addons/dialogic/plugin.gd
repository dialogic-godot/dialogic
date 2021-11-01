tool
extends EditorPlugin

var _editor_view
var _parts_inspector
var _export_plugin


func _init():
	if Engine.editor_hint:
		# Make sure the core files exist 
		DialogicResources.init_dialogic_files()

	## Remove after 2.0
	if Engine.editor_hint:
		DialogicUtil.resource_fixer()
	

func _enter_tree() -> void:
	_parts_inspector = load("res://addons/dialogic/Other/inspector_timeline_picker.gd").new()
	add_inspector_plugin(_parts_inspector)
	_export_plugin = load("res://addons/dialogic/Other/export_plugin.gd").new()
	add_export_plugin(_export_plugin)
	_add_custom_editor_view()
	get_editor_interface().get_editor_viewport().add_child(_editor_view)
	_editor_view.editor_interface = get_editor_interface()
	make_visible(false)
	_parts_inspector.dialogic_editor_plugin = self
	_parts_inspector.dialogic_editor_view = _editor_view


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
	#_editor_view.plugin_reference = self


func _remove_custom_editor_view():
	if _editor_view:
		remove_control_from_bottom_panel(_editor_view)
		_editor_view.queue_free()

