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

var max_text_length := 16
var current_value : String
var hide_reset:bool = false

func _ready() -> void:
	$FocusStyle.add_theme_stylebox_override('panel', get_theme_stylebox('focus', 'DialogicEventEdit'))
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
		if len(value.get_file()) > max_text_length:
			%Field.custom_minimum_size.x = get_theme_font('font', 'Label').get_string_size(value.get_file()).x
			%Field.expand_to_text_length = false
			%Field.size.x = 0
		else:
			%Field.custom_minimum_size.x = 0
			%Field.expand_to_text_length = true
		%Field.tooltip_text = value
		%ClearButton.visible = !value.is_empty() and !hide_reset
	else:
		%Field.text = value


func _on_OpenButton_pressed() -> void:
	find_parent('EditorView').godot_file_dialog(_on_file_dialog_selected, file_filter, file_mode, "Open "+ property_name)


func _on_file_dialog_selected(path:String) -> void:
	set_value(path)
	emit_signal("value_changed", property_name, path)


func clear_path() -> void:
	set_value("")
	emit_signal("value_changed", property_name, "")

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
