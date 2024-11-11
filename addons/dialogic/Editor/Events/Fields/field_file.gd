@tool
extends DialogicVisualEditorField

## Event block field for selecting a file or directory.

#region VARIABLES
################################################################################

@export var file_filter := ""
@export var placeholder := ""
@export var file_mode: EditorFileDialog.FileMode = EditorFileDialog.FILE_MODE_OPEN_FILE
var resource_icon: Texture:
	get:
		return resource_icon
	set(new_icon):
		resource_icon = new_icon
		%Icon.texture = new_icon
		if new_icon == null:
			%Field.theme_type_variation = ""
		else:
			%Field.theme_type_variation = "LineEditWithIcon"

var max_width := 200
var current_value: String
var hide_reset := false

#endregion


#region MAIN METHODS
################################################################################

func _ready() -> void:
	$FocusStyle.add_theme_stylebox_override('panel', get_theme_stylebox('focus', 'DialogicEventEdit'))

	%OpenButton.icon = get_theme_icon("Folder", "EditorIcons")
	%OpenButton.button_down.connect(_on_OpenButton_pressed)

	%ClearButton.icon = get_theme_icon("Reload", "EditorIcons")
	%ClearButton.button_up.connect(clear_path)
	%ClearButton.visible = !hide_reset

	%Field.set_drag_forwarding(Callable(), self._can_drop_data_fw, self._drop_data_fw)
	%Field.placeholder_text = placeholder


func _load_display_info(info:Dictionary) -> void:
	file_filter = info.get('file_filter', '')
	placeholder = info.get('placeholder', '')
	resource_icon = info.get('icon', null)
	await ready

	if resource_icon == null and info.has('editor_icon'):
		resource_icon = callv('get_theme_icon', info.editor_icon)


func _set_value(value: Variant) -> void:
	current_value = value
	var text: String = value

	if file_mode != EditorFileDialog.FILE_MODE_OPEN_DIR:
		text = value.get_file()
		%Field.tooltip_text = value

	if %Field.get_theme_font('font').get_string_size(
		text, 0, -1,
		%Field.get_theme_font_size('font_size')).x > max_width:
		%Field.expand_to_text_length = false
		%Field.custom_minimum_size.x = max_width
		%Field.size.x = 0
	else:
		%Field.custom_minimum_size.x = 0
		%Field.expand_to_text_length = true

	if not %Field.text == text:
		value_changed.emit(property_name, current_value)
		%Field.text = text

	%ClearButton.visible = not value.is_empty() and not hide_reset


#endregion


#region BUTTONS
################################################################################

func _on_OpenButton_pressed() -> void:
	find_parent('EditorView').godot_file_dialog(_on_file_dialog_selected, file_filter, file_mode, "Open "+ property_name)


func _on_file_dialog_selected(path:String) -> void:
	_set_value(path)
	value_changed.emit(property_name, path)


func clear_path() -> void:
	_set_value("")
	value_changed.emit(property_name, "")

#endregion


#region DRAG AND DROP
################################################################################

func _can_drop_data_fw(_at_position: Vector2, data: Variant) -> bool:
	if typeof(data) == TYPE_DICTIONARY and data.has('files') and len(data.files) == 1:

		if file_filter:

			if '*.'+data.files[0].get_extension() in file_filter:
				return true

		else: return true

	return false


func _drop_data_fw(_at_position: Vector2, data: Variant) -> void:
	var file: String = data.files[0]
	_on_file_dialog_selected(file)

#endregion


#region VISUALS FOR FOCUS
################################################################################

func _on_field_focus_entered() -> void:
	$FocusStyle.show()


func _on_field_focus_exited() -> void:
	$FocusStyle.hide()
	var field_text: String = %Field.text
	if current_value == field_text or (file_mode != EditorFileDialog.FILE_MODE_OPEN_DIR and current_value.get_file() == field_text):
		return
	_on_file_dialog_selected(field_text)

#endregion
