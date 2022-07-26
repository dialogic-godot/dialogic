@tool
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
	get_editor_interface().get_editor_main_control().add_child(_editor_view)
	make_visible(false)


func _ready():
	if Engine.is_editor_hint():
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
	return load("res://addons/dialogic/Editor/Images/Plugin/plugin-editor-icon-" + _theme + "-theme-" + str(_scale) + ".svg")


func _add_custom_editor_view():
	var button = Button.new()
	button.text = 'Dialogic is this now'
	_editor_view = button
#	_editor_view = preload("res://addons/dialogic/Editor/EditorView.tscn").instance()


func _remove_custom_editor_view():
	if _editor_view:
		remove_control_from_bottom_panel(_editor_view)
		_editor_view.queue_free()


func save_external_data():
	emit_signal('dialogic_save')


#func handles(object):
#	if object is DialogicTimeline:
#		return true
#	if object is DialogicCharacter:
#		return true


#func edit(object):
#	make_visible(true)
#	if object is DialogicTimeline:
#		_editor_view.edit_timeline(object)
#	if object is DialogicCharacter:
#		_editor_view.edit_character(object)


func enable_plugin():
	add_autoload_singleton("Dialogic", "res://addons/dialogic/Other/DialogicGameHandler.gd")
	add_dialogic_default_action()

func disable_plugin():
	remove_autoload_singleton("Dialogic")

func add_dialogic_default_action():
	if !ProjectSettings.has_setting('input/dialogic_default_action'):
		var input_enter = InputEventKey.new()
		input_enter.scancode = KEY_ENTER
		var input_left_click = InputEventMouseButton.new()
#		input_left_click.button_index = BUTTON_LEFT
		input_left_click.pressed = true
		var input_space = InputEventKey.new()
		input_space.scancode = KEY_SPACE
		var input_x = InputEventKey.new()
		input_x.scancode = KEY_X
		var input_controller = InputEventJoypadButton.new()
#		input_controller.button_index = JOY_BUTTON_0
	
		ProjectSettings.set_setting('input/dialogic_default_action', {'deadzone':0.5, 'events':[input_enter, input_left_click, input_space, input_x, input_controller]})
		ProjectSettings.save()
