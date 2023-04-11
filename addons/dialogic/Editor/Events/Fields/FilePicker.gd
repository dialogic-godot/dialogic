@tool
extends Control

## Event block field for selecting a file or directory.

signal value_changed(property_name:String, value:String)
var property_name : String

@export var file_filter := ""
@export var placeholder := ""
@export var file_mode : EditorFileDialog.FileMode = EditorFileDialog.FILE_MODE_OPEN_FILE
@export var resource_icon:Texture = null:
	get:
		return resource_icon
	set(new_icon):
		resource_icon = new_icon
		%Icon.texture = new_icon
		if new_icon == null:
			%Field.theme_type_variation = ""
		else:
			%Field.theme_type_variation = "LineEditWithIcon"
var current_value : String
var hide_reset:bool = false

func _ready() -> void:
	var focus_style :StyleBoxFlat = get_theme_stylebox("focus", "LineEdit").duplicate()
	var normal_style :StyleBoxFlat = get_theme_stylebox("normal", "LineEdit").duplicate()
	normal_style.content_margin_bottom = 0
	normal_style.content_margin_top = 0
	focus_style.expand_margin_left = normal_style.content_margin_left
	focus_style.expand_margin_right = normal_style.content_margin_right
	$FocusStyle.add_theme_stylebox_override('panel', focus_style)
	add_theme_stylebox_override('panel', normal_style)
	%OpenButton.icon = get_theme_icon("Folder", "EditorIcons")
	%ClearButton.icon = get_theme_icon("Reload", "EditorIcons")
	%OpenButton.button_down.connect(_on_OpenButton_pressed)
	%ClearButton.button_up.connect(clear_path)
	%ClearButton.visible = !hide_reset
	%Field.set_drag_forwarding(Callable(), self._can_drop_data_fw, self._drop_data_fw)
	%Field.placeholder_text = placeholder


func set_value(value:String) -> void:
	current_value = value
	if file_mode != EditorFileDialog.FILE_MODE_OPEN_DIR:
		%Field.text = value.get_file()
		%Field.tooltip_text = value
		%ClearButton.visible = !value.is_empty() and !hide_reset
	else:
		%Field.text = value


func _on_OpenButton_pressed() -> void:
	find_parent('EditorView').godot_file_dialog(_on_file_dialog_selected, file_filter, file_mode, "Open "+ property_name)


func _on_file_dialog_selected(path:String) -> void:
	emit_signal("value_changed", property_name, path)
	set_value(path)


func clear_path() -> void:
	emit_signal("value_changed", property_name, "")
	set_value("")

func _can_drop_data_fw(at_position: Vector2, data: Variant) -> bool:
	if typeof(data) == TYPE_DICTIONARY and data.has('files') and len(data.files) == 1:
		if file_filter:
			if '*.'+data.files[0].get_extension() in file_filter:
				return true
		else: return true
	return false

func _drop_data_fw(at_position: Vector2, data: Variant) -> void:
	_on_file_dialog_selected(data.files[0])


func _on_field_focus_entered():
	$FocusStyle.show()

func _on_field_focus_exited():
	$FocusStyle.hide()
