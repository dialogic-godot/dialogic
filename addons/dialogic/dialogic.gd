tool
extends EditorPlugin

var _editor_view
var _parts_inspector

func _init():
	# This functions makes sure that the needed files and folders
	# exists when the plugin is loaded. If they don't, we create 
	# them.
	var directory = Directory.new()
	
	# Create directories
	var paths = DialogicResources.working_dirs
	
	for dir in paths:
		if not directory.dir_exists(paths[dir]):
			directory.make_dir_recursive(paths[dir])
	
	# Create empty files
	var files = DialogicResources.cfg_files
	
	for f in files:
		if not directory.file_exists(files[f]):
			DialogicResources.create_empty_file(files[f])
		
	add_autoload_singleton('DialogicSingleton', "res://addons/dialogic/Other/DialogicSingleton.gd")
	
	## Remove after 2.0
	if Engine.editor_hint:
		DialogicUtil.resource_fixer()


func _enter_tree() -> void:
	_parts_inspector = load("res://addons/dialogic/Other/inspector_timeline_picker.gd").new()
	add_inspector_plugin(_parts_inspector)
	_add_custom_editor_view()
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


func has_main_screen():
	return true


func get_plugin_name():
	return "Dialogic"


func make_visible(visible):
	if _editor_view:
		_editor_view.visible = visible


func get_plugin_icon():
	# https://github.com/godotengine/godot-proposals/issues/572
	if get_editor_interface().get_editor_settings().get_setting("interface/theme/base_color").v > 0.5:
		return preload("res://addons/dialogic/Images/Plugin/plugin-editor-icon-light-theme.svg")
	return preload("res://addons/dialogic/Images/Plugin/plugin-editor-icon-dark-theme.svg")


func _add_custom_editor_view():
	_editor_view = preload("res://addons/dialogic/Editor/EditorView.tscn").instance()
	get_editor_interface().get_editor_viewport().add_child(_editor_view)
	_editor_view.editor_interface = get_editor_interface()
	#_editor_view.plugin_reference = self


func _remove_custom_editor_view():
	if _editor_view:
		remove_control_from_bottom_panel(_editor_view)
		_editor_view.queue_free()
