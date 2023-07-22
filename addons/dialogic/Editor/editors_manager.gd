@tool
extends Control

## Node that manages editors, the toolbar and  the sidebar.

signal resource_opened(resource)
signal editor_changed(previous, current)

### References
@onready var sidebar = $HSplit/Sidebar
@onready var editors_holder = $HSplit/VBox/Editors
@onready var toolbar = $HSplit/VBox/Toolbar
var resource_helper: Node:
	get:
		return get_node("ResourceHelper")

## Information on supported resources and registered editors
var current_editor: DialogicEditor = null
var previous_editor: DialogicEditor = null
var editors := {}
var resources := []
var used_resources_cache : Array = []

################################################################################
## 						REGISTERING EDITORS
################################################################################

## Asks all childs of the editor holder to register
func _ready() -> void:
	
	# Load custom editors
	for indexer in DialogicUtil.get_indexers():
		for editor in indexer._get_editors():
			editors_holder.add_child(load(editor).instantiate())
	
	# Needs to be done here to make sure this node is ready when doing the register calls
	for editor in editors_holder.get_children():
		editor.editors_manager = self
		editor._register()
	
	await get_parent().get_parent().ready
	await get_tree().process_frame
	load_saved_state()
	used_resources_cache = DialogicUtil.get_editor_setting('last_resources', [])
	for res in used_resources_cache:
		if !FileAccess.file_exists(res):
			used_resources_cache.erase(res)
	sidebar.update_resource_list(used_resources_cache)


## Call to register an editor/tab that edits a resource with a custom ending.
func register_resource_editor(resource_extension:String, editor:DialogicEditor) -> void:
	editors[editor.name] = {'node':editor, 'buttons':[], 'extension': resource_extension}
	resources.append(resource_extension)
	editor.resource_saved.connect(_on_resource_saved.bind(editor))
	editor.resource_unsaved.connect(_on_resource_unsaved.bind(editor))


## Call to register an editor/tab that doesn't edit a resource
func register_simple_editor(editor:DialogicEditor) -> void:
	editors[editor.name] = {'node': editor,  'buttons':[]}


## Call to add an icon button. These buttons are always visible.
func add_icon_button(icon:Texture, tooltip:String, editor:DialogicEditor) -> Node:
	var button: Button = sidebar.add_icon_button(icon, tooltip)
	editors[editor.name]['buttons'].append(button)
	button.pressed.connect(_on_sidebar_button_pressed.bind(button, editor.name))
	return button


## Call to add a custom action button. Only visible if editor is visible.
func add_custom_button(label:String, icon:Texture, editor:DialogicEditor) -> Node:
	var button: Button = toolbar.add_custom_button(label, icon)
	editors[editor.name]['buttons'].append(button)
	button.pressed.connect(_on_sidebar_button_pressed.bind(button, editor.name))
	button.hide()
	return button


func can_edit_resource(resource:Resource) -> bool:
	return resource.resource_path.get_extension() in resources


################################################################################
## 						OPENING/CLOSING
################################################################################

func _on_editors_tab_changed(tab:int) -> void:
	open_editor(editors_holder.get_child(tab))


func edit_resource(resource:Resource, save_previous:bool = true) -> void:
	if resource:
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
				open_editor(editor['node'], false)
		
		resource_opened.emit(resource)
	else: 
		# The resource doesn't exists, show an error
		print('[Dialogic] The resource you are trying to edit doesn\'t exists any more.')


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
	
	if current_editor != previous_editor:
		previous_editor = current_editor
	
	editors_holder.current_tab = editor.get_index()
	editor._open(extra_info)
	current_editor = editor
	
	if editor.current_resource:
		var text:String = editor.current_resource.resource_path.get_file()
		if editor.current_resource_state == DialogicEditor.ResourceStates.Unsaved:
			text += "(*)"
		toolbar.set_current_resource_text(text)
	else:
		toolbar.set_current_resource_text(current_editor.alternative_text)
	
	toolbar.hide_all_custom_buttons()
	for button in editors[current_editor.name]['buttons']:
		button.show()
	
	save_current_state()
	editor_changed.emit(previous_editor, current_editor)


## Rarely used to completely clear a editor.
func clear_editor(editor:DialogicEditor, save:bool = false) -> void:
	if save:
		editor._save()
	
	editor._clear()

## Shows a file selector. Calls [accept_callable] once accepted
func show_add_resource_dialog(accept_callable:Callable, filter:String = "*", title = "New resource", default_name = "new_character", mode = EditorFileDialog.FILE_MODE_SAVE_FILE) -> void:
	find_parent('EditorView').godot_file_dialog(
		accept_callable,
		filter,
		mode,
		title,
		default_name,
		true,
		"Do not use \"'()!;:/\\*# in character or timeline names!"
	)


## Called by the plugin.gd script on CTRL+S or Debug Game start
func save_current_resource() -> void: 
	current_editor._save()


## Change the resource state
func _on_resource_saved(editor:DialogicEditor):
	toolbar.set_unsaved_indicator(true)


## Change the resource state
func _on_resource_unsaved(editor:DialogicEditor):
	toolbar.set_unsaved_indicator(false)


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


################################################################################
## 						HELPERS
################################################################################

func _on_sidebar_button_pressed(button:Button, editor_name:String) -> void:
	pass


func get_current_editor() -> DialogicEditor:
	return current_editor


func _exit_tree():
	DialogicUtil.set_editor_setting('last_resources', used_resources_cache)
