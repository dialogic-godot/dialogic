@tool
extends Control

## Node that manages editors, the toolbar and  the sidebar.

signal resource_opened(resource)
signal editor_changed(previous, current)

### References
@onready var hsplit := $HSplit
@onready var sidebar := $HSplit/Sidebar
@onready var editors_holder := $HSplit/VBox/Editors
@onready var toolbar := $HSplit/VBox/Toolbar
@onready var tabbar := $HSplit/VBox/Toolbar/EditorTabBar

var reference_manager: Node:
	get:
		return get_node("../ReferenceManager")

## Information on supported resource extensions and registered editors
var current_editor: DialogicEditor = null
var previous_editor: DialogicEditor = null
var editors := {}
var supported_file_extensions := []
var used_resources_cache: Array = []
enum ButtonPlacement {TOOLBAR_MAIN, SIDEBAR_LEFT_OF_FILTER, SIDEBAR_RIGHT_OF_FILTER}


################################################################################
## 						REGISTERING EDITORS
################################################################################

## Asks all childs of the editor holder to register
func _ready() -> void:
	if owner.get_parent() is SubViewport:
		return

	tabbar.clear_tabs()

	# Load base editors
	_add_editor("res://addons/dialogic/Editor/HomePage/home_page.tscn")
	_add_editor("res://addons/dialogic/Editor/TimelineEditor/timeline_editor.tscn")
	_add_editor("res://addons/dialogic/Editor/CharacterEditor/character_editor.tscn")

	# Load custom editors
	for indexer in DialogicUtil.get_indexers():
		for editor_path in indexer._get_editors():
			_add_editor(editor_path)
	_add_editor("res://addons/dialogic/Editor/Settings/settings_editor.tscn")

	tabbar.tab_clicked.connect(_on_editors_tab_changed)

	# Needs to be done here to make sure this node is ready when doing the register calls
	for editor in editors_holder.get_children():
		editor.editors_manager = self
		editor._register()

	DialogicResourceUtil.update()

	await get_parent().ready
	await get_tree().process_frame

	load_saved_state()
	used_resources_cache = DialogicUtil.get_editor_setting('last_resources', [])
	sidebar.update_resource_list(used_resources_cache)

	EditorInterface.get_file_system_dock().files_moved.connect(_on_file_moved)
	EditorInterface.get_file_system_dock().file_removed.connect(_on_file_removed)

	hsplit.set("theme_override_constants/separation", get_theme_constant("base_margin", "Editor") * DialogicUtil.get_editor_scale())


func _add_editor(path:String) -> void:
	var editor: DialogicEditor = load(path).instantiate()
	editors_holder.add_child(editor)
	editor.hide()
	tabbar.add_tab(editor._get_title(), editor._get_icon())


## Call to register an editor/tab that edits a resource with a custom ending.
func register_resource_editor(resource_extension:String, editor:DialogicEditor) -> void:
	editors[editor.name] = {'node':editor, 'buttons':[], 'extension': resource_extension}
	supported_file_extensions.append(resource_extension)
	editor.resource_saved.connect(_on_resource_saved.bind(editor))
	editor.resource_unsaved.connect(_on_resource_unsaved.bind(editor))


## Call to register an editor/tab that doesn't edit a resource
func register_simple_editor(editor:DialogicEditor) -> void:
	editors[editor.name] = {'node': editor,  'buttons':[]}


## Call to add a button.
func add_button(icon:Texture, label:String, tooltip:String, editor:DialogicEditor=null, placement = ButtonPlacement.TOOLBAR_MAIN) -> Node:
	var button: Button
	match placement:
		ButtonPlacement.TOOLBAR_MAIN:
			button = toolbar.add_button(icon, label, tooltip, placement)
		ButtonPlacement.SIDEBAR_LEFT_OF_FILTER, ButtonPlacement.SIDEBAR_RIGHT_OF_FILTER:
			button = sidebar.add_button(icon, label, tooltip, placement)
	
	if editor != null:
		editors[editor.name]['buttons'].append(button)
	return button


func can_edit_resource(resource:Resource) -> bool:
	return resource.resource_path.get_extension() in supported_file_extensions


################################################################################
## 						OPENING/CLOSING
################################################################################


func _on_editors_tab_changed(tab:int) -> void:
	open_editor(editors_holder.get_child(tab))


func edit_resource(resource:Resource, save_previous:bool = true, silent:= false) -> void:
	if not resource:
		# The resource doesn't exists, show an error
		print("[Dialogic] The resource you are trying to edit doesn't exist any more.")
		return

	if current_editor and save_previous:
		current_editor._save()

	if !resource.resource_path in used_resources_cache:
		used_resources_cache.append(resource.resource_path)
		sidebar.update_resource_list(used_resources_cache)

	## Open the correct editor
	var extension: String = resource.resource_path.get_extension()
	for editor in editors.values():
		if editor.get('extension', '') == extension:
			editor['node']._open_resource(resource)
			if !silent:
				open_editor(editor['node'], false)
	if !silent:
		resource_opened.emit(resource)



## Only works if there was a different editor opened previously
func toggle_editor(editor) -> void:
	if editor.visible:
		open_editor(previous_editor, true)
	else:
		open_editor(editor, true)


## Shows the given editor
func open_editor(editor:DialogicEditor, save_previous: bool = true, extra_info:Variant = null) -> void:
	if current_editor and save_previous:
		current_editor._save()

	if current_editor:
		current_editor._close()
		current_editor.hide()

	if current_editor != previous_editor:
		previous_editor = current_editor

	editor._open(extra_info)
	editor.opened.emit()
	current_editor = editor
	editor.show()
	tabbar.current_tab = editor.get_index()

	if editor.current_resource:
		var text: String = editor.current_resource.resource_path.get_file()
		if editor.current_resource_state == DialogicEditor.ResourceStates.UNSAVED:
			text += "(*)"

	## This makes custom button editor-specific
	## I think it's better without.

	save_current_state()
	editor_changed.emit(previous_editor, current_editor)


## Rarely used to completely clear an editor.
func clear_editor(editor:DialogicEditor, save:bool = false) -> void:
	if save:
		editor._save()

	editor._clear()


## Shows a file selector. Calls [accept_callable] once accepted
func show_add_resource_dialog(accept_callable:Callable, filter:String = "*", title = "New resource", default_name = "new_character", mode = EditorFileDialog.FILE_MODE_SAVE_FILE) -> void:
	find_parent('EditorView').godot_file_dialog(
		_on_add_resource_dialog_accepted.bind(accept_callable),
		filter,
		mode,
		title,
		default_name,
		true,
		"Do not use \"'()!;:/\\*# in character or timeline names!"
	)


func _on_add_resource_dialog_accepted(path:String, callable:Callable) -> void:
	var file_name: String = path.get_file().trim_suffix('.'+path.get_extension())
	for i in ['#','&','+',';','(',')','!','*','*','"',"'",'%', '$', ':','.',',']:
		file_name = file_name.replace(i, '')
	callable.call(path.trim_suffix(path.get_file()).path_join(file_name)+'.'+path.get_extension())


## Called by the plugin.gd script on CTRL+S or Debug Game start
func save_current_resource() -> void:
	if current_editor:
		current_editor._save()


## Change the resource state
func _on_resource_saved(editor:DialogicEditor):
	sidebar.set_unsaved_indicator(true)


## Change the resource state
func _on_resource_unsaved(editor:DialogicEditor):
	sidebar.set_unsaved_indicator(false)


## Tries opening the last resource
func load_saved_state() -> void:
	var current_resources: Dictionary = DialogicUtil.get_editor_setting('current_resources', {})
	for editor in current_resources.keys():
		editors[editor]['node']._open_resource(load(current_resources[editor]))

	var current_editor: String = DialogicUtil.get_editor_setting('current_editor', 'HomePage')
	open_editor(editors[current_editor]['node'])


func save_current_state() -> void:
	DialogicUtil.set_editor_setting('current_editor', current_editor.name)
	var current_resources: Dictionary = {}
	for editor in editors.values():
		if editor['node'].current_resource != null:
			current_resources[editor['node'].name] = editor['node'].current_resource.resource_path
	DialogicUtil.set_editor_setting('current_resources', current_resources)


func _on_file_moved(old_name:String, new_name:String) -> void:
	if !old_name.get_extension() in supported_file_extensions:
		return

	used_resources_cache = DialogicUtil.get_editor_setting('last_resources', [])
	if old_name in used_resources_cache:
		used_resources_cache.insert(used_resources_cache.find(old_name), new_name)
		used_resources_cache.erase(old_name)

	sidebar.update_resource_list(used_resources_cache)

	for editor in editors:
		if editors[editor].node.current_resource != null and editors[editor].node.current_resource.resource_path == old_name:
			editors[editor].node.current_resource.take_over_path(new_name)
			edit_resource(load(new_name), true, true)

	save_current_state()


func _on_file_removed(file_name:String) -> void:
	var current_resources: Dictionary = DialogicUtil.get_editor_setting('current_resources', {})
	for editor_name in current_resources:
		if current_resources[editor_name] == file_name:
			clear_editor(editors[editor_name].node, false)
			sidebar.update_resource_list()
			save_current_state()



################################################################################
## 						HELPERS
################################################################################


func get_current_editor() -> DialogicEditor:
	return current_editor


func _exit_tree() -> void:
	DialogicUtil.set_editor_setting('last_resources', used_resources_cache)
