@tool
extends Control

## Event block field for selecting a file or directory.

signal value_changed
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


func _ready() -> void:
	DCSS.style(%Field, {
		'border-radius': 3,
		'border-color': get_theme_color("dark_color_3", "Editor"),
		'border': 1,
		'background': get_theme_color("dark_color_1", "Editor"),
		'padding': [5, 5],
	})
	$PanelContainer.add_theme_stylebox_override('panel', get_theme_stylebox("normal", "LineEdit"))
	%OpenButton.icon = get_theme_icon("Folder", "EditorIcons")
	%ClearButton.icon = get_theme_icon("Reload", "EditorIcons")
	%OpenButton.button_down.connect(_on_OpenButton_pressed)
	%ClearButton.button_up.connect(clear_path)
	%Field.set_drag_forwarding(Callable(), self._can_drop_data_fw, self._drop_data_fw)
	%Field.placeholder_text = placeholder


func set_value(value:String) -> void:
	current_value = value
	if file_mode != EditorFileDialog.FILE_MODE_OPEN_DIR:
		%Field.text = value.get_file()
		tooltip_text = value
		%ClearButton.visible = !value.is_empty()
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
