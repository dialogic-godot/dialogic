@tool
extends EditorPlugin

## Main plugin script. Handles communication with the rest of godot. 
## Most methods are overridables called by godot. 


const MainPanel := preload("res://addons/dialogic/Editor/editor_main.tscn")

### References
# used by various other scripts to quickly reference these things

# the root of the dialogic editor
var editor_view: Control

# emitted if godot wants us to save
signal dialogic_save


################################################################################
## 					INITIALIZING
################################################################################

func _init() -> void:
	self.name = 'DialogicPlugin'


################################################################################
## 					ACTIVATION & EDITOR SETUP
################################################################################

func _enable_plugin():
	add_autoload_singleton("Dialogic", "res://addons/dialogic/Other/DialogicGameHandler.gd")
	add_dialogic_default_action()


func _disable_plugin():
	remove_autoload_singleton("Dialogic")


func _enter_tree() -> void:
	editor_view = MainPanel.instantiate()
	editor_view.plugin_reference = self
	editor_view.hide()
	get_editor_interface().get_editor_main_screen().add_child(editor_view)
	_make_visible(false)


func _exit_tree() -> void:
	if editor_view:
		remove_control_from_bottom_panel(editor_view)
		editor_view.queue_free()


func _has_main_screen() -> bool:
	return true


func _get_plugin_name() -> String:
	return "Dialogic"


func _get_plugin_icon():
	return load("res://addons/dialogic/Editor/Images/plugin-icon.svg")


################################################################################
## 					EDITOR INTERACTION
################################################################################

func _make_visible(visible:bool) -> void:
	if editor_view:
		editor_view.visible = visible


func _save_external_data() -> void:
	if editor_view and editor_view.editors_manager:
		editor_view.editors_manager.save_current_resource()


func _handles(object) -> bool:
	if editor_view != null and editor_view.editors_manager != null and object is Resource:
		return editor_view.editors_manager.can_edit_resource(object)
	return false


func _edit(object) -> void:
	if object == null:
		return
	_make_visible(true)
	if editor_view and editor_view.editors_manager:
		editor_view.editors_manager.edit_resource(object)



################################################################################
## 					SPECIAL SETUP/UPDATES
################################################################################

# methods that adds a dialogic_default_action if non exists
func add_dialogic_default_action() -> void:
	if !ProjectSettings.has_setting('input/dialogic_default_action'):
		var input_enter : InputEventKey = InputEventKey.new()
		input_enter.keycode = KEY_ENTER
		var input_left_click : InputEventMouseButton = InputEventMouseButton.new()
		input_left_click.button_index = MOUSE_BUTTON_LEFT
		input_left_click.pressed = true
		var input_space : InputEventKey = InputEventKey.new()
		input_space.keycode = KEY_SPACE
		var input_x : InputEventKey = InputEventKey.new()
		input_x.keycode = KEY_X
		var input_controller : InputEventJoypadButton = InputEventJoypadButton.new()
		input_controller.button_index = JOY_BUTTON_A

		ProjectSettings.set_setting('input/dialogic_default_action', {'deadzone':0.5, 'events':[input_enter, input_left_click, input_space, input_x, input_controller]})
		ProjectSettings.save()
