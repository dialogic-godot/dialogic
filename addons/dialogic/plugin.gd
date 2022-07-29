@tool
extends EditorPlugin

var _editor_view
var _parts_inspector
var _export_plugin
var _editor_interface

signal dialogic_save

const MainPanel = preload("res://addons/dialogic/Editor/EditorView.tscn")

func _init():
	self.name = 'DialogicPlugin'
	

func _enter_tree():
	_editor_view = MainPanel.instantiate()
	_editor_view.plugin_reference = self
	_editor_view.hide()
	_editor_interface = get_editor_interface()
	get_editor_interface().get_editor_main_control().add_child(_editor_view)
	_make_visible(false)
	print(get_path())


func _ready():
	if Engine.is_editor_hint():
		# Force Godot to show the dialogic folder
		get_editor_interface().get_resource_filesystem().scan()
	

func _exit_tree():
	if _editor_view:
		_editor_view.queue_free()
	_remove_custom_editor_view()
	remove_inspector_plugin(_parts_inspector)
	remove_export_plugin(_export_plugin)


func _has_main_screen():
	return true


func _get_plugin_name():
	return "Dialogic"


func _make_visible(visible):
	if _editor_view:
		_editor_view.visible = visible


func _get_plugin_icon():
	var _scale = get_editor_interface().get_editor_scale()
	var _theme = 'dark'
	# https://github.com/godotengine/godot-proposals/issues/572
	if get_editor_interface().get_editor_settings().get_setting("interface/theme/base_color").v > 0.5:
		_theme = 'light'
	return load("res://addons/dialogic/Editor/Images/Plugin/plugin-editor-icon-" + _theme + "-theme-" + str(_scale) + ".svg")


func _remove_custom_editor_view():
	if _editor_view:
		remove_control_from_bottom_panel(_editor_view)
		_editor_view.queue_free()


func _save_external_data():
	emit_signal('dialogic_save')


func _handles(object):
	if object is DialogicTimeline:
		return true
	if object is DialogicCharacter:
		return true


func _edit(object):
	_make_visible(true)
	if object is DialogicTimeline:
		_editor_view.edit_timeline(object)
	if object is DialogicCharacter:
		_editor_view.edit_character(object)


func _enable_plugin():
	add_autoload_singleton("Dialogic", "res://addons/dialogic/Other/DialogicGameHandler.gd")
	add_dialogic_default_action()

func _disable_plugin():
	remove_autoload_singleton("Dialogic")

func add_dialogic_default_action():
	if !ProjectSettings.has_setting('input/dialogic_default_action'):
		var input_enter = InputEventKey.new()
		input_enter.keycode = KEY_ENTER
		var input_left_click = InputEventMouseButton.new()
#		input_left_click.button_index = BUTTON_LEFT
		input_left_click.pressed = true
		var input_space = InputEventKey.new()
		input_space.keycode = KEY_SPACE
		var input_x = InputEventKey.new()
		input_x.keycode = KEY_X
		var input_controller = InputEventJoypadButton.new()
		input_controller.button_index = JOY_BUTTON_A

		ProjectSettings.set_setting('input/dialogic_default_action', {'deadzone':0.5, 'events':[input_enter, input_left_click, input_space, input_x, input_controller]})
		ProjectSettings.save()
