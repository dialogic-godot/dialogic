@tool
extends EditorPlugin

## Preload the main panel scene
const MainPanel := preload("res://addons/dialogic/Editor/editor_main.tscn")
const PLUGIN_NAME := "Dialogic"
const PLUGIN_HANDLER_PATH := "res://addons/dialogic/Core/DialogicGameHandler.gd"
const PLUGIN_ICON_PATH := "res://addons/dialogic/Editor/Images/plugin-icon.svg"

## References used by various other scripts to quickly reference these things
var editor_view: Control  # the root of the dialogic editor
var inspector_plugin: EditorInspectorPlugin = null

## Initialization
func _init() -> void:
	self.name = "DialogicPlugin"


#region ACTIVATION & EDITOR SETUP
################################################################################

## Called when the plugin is activated in the editor.
## Sets up the main editor interface and inspector plugin.
func _enter_tree() -> void:
	# Add default input action for Dialogic
	add_dialogic_default_action()
	
	# Setup main editor view
	# Use call_deferred to ensure editor_main_screen is ready in Godot 4.5+
	editor_view = MainPanel.instantiate()
	editor_view.plugin_reference = self
	editor_view.hide()
	call_deferred("_add_main_panel_to_editor", editor_view)
	_make_visible(false)
	
	# Setup inspector plugin
	inspector_plugin = load("res://addons/dialogic/Editor/Inspector/inspector_plugin.gd").new()
	add_inspector_plugin(inspector_plugin)


## Helper function to safely add main panel to editor interface
## Deferred to ensure editor_main_screen is ready in Godot 4.5+
func _add_main_panel_to_editor(panel: Control) -> void:
	var main_screen := get_editor_interface().get_editor_main_screen()
	if main_screen:
		main_screen.add_child(panel)


## Called when the plugin is deactivated in the editor.
## Cleans up the editor interface.
func _exit_tree() -> void:
	if editor_view:
		if editor_view.get_parent():
			editor_view.get_parent().remove_child(editor_view)
		editor_view.queue_free()
	
	if inspector_plugin:
		remove_inspector_plugin(inspector_plugin)

#endregion

func _get_plugin_name() -> String:
	return PLUGIN_NAME


func _get_plugin_icon() -> Texture2D:
	return load(PLUGIN_ICON_PATH)

#endregion


#region EDITOR INTERACTION
################################################################################

## Editor Interaction
func _make_visible(visible:bool) -> void:
	if not editor_view:
		return

	if editor_view.get_parent() is Window:
		if visible:
			get_editor_interface().set_main_screen_editor("Script")
			editor_view.show()
			editor_view.get_parent().grab_focus()
	else:
		editor_view.visible = visible


func _save_external_data() -> void:
	if _editor_view_and_manager_exist():
		editor_view.editors_manager.save_current_resource()


func _get_unsaved_status(for_scene:String) -> String:
	if for_scene.is_empty():
		_save_external_data()
	return ""


func _handles(object) -> bool:
	if _editor_view_and_manager_exist() and object is Resource:
		return editor_view.editors_manager.can_edit_resource(object)
	return false


func _edit(object) -> void:
	if object == null:
		return
	_make_visible(true)
	if _editor_view_and_manager_exist():
		editor_view.editors_manager.edit_resource(object)


## Helper function to check if editor_view and its manager exist
func _editor_view_and_manager_exist() -> bool:
	return editor_view and editor_view.editors_manager

#endregion


#region PROJECT SETUP
################################################################################

## Special Setup/Updates
## Methods that adds a dialogic_default_action if non exists
func add_dialogic_default_action() -> void:
	if ProjectSettings.has_setting('input/dialogic_default_action'):
		return

	var input_enter: InputEventKey = InputEventKey.new()
	input_enter.keycode = KEY_ENTER
	var input_left_click: InputEventMouseButton = InputEventMouseButton.new()
	input_left_click.button_index = MOUSE_BUTTON_LEFT
	input_left_click.pressed = true
	input_left_click.device = -1
	var input_space: InputEventKey = InputEventKey.new()
	input_space.keycode = KEY_SPACE
	var input_x: InputEventKey = InputEventKey.new()
	input_x.keycode = KEY_X
	var input_controller: InputEventJoypadButton = InputEventJoypadButton.new()
	input_controller.button_index = JOY_BUTTON_A

	ProjectSettings.set_setting('input/dialogic_default_action', {'deadzone':0.5, 'events':[input_enter, input_left_click, input_space, input_x, input_controller]})
	ProjectSettings.save()

# Create cache when project is compiled
func _build() -> bool:
	DialogicResourceUtil.update()
	return true

#endregion
