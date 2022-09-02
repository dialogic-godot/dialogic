@tool
extends Control

@export var file_filter := ""
@export var placeholder := ""
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

var property_name : String
signal value_changed

func _ready():
	DCSS.style(%Field, {
		'border-radius': 3,
		'border-color': Color('#14161A'),
		'border': 1,
		'background': Color('#1D1F25'),
		'padding': [5, 25],
	})
	%OpenButton.icon = get_theme_icon("Folder", "EditorIcons")
	%ClearButton.icon = get_theme_icon("Reload", "EditorIcons")
	%OpenButton.button_down.connect(_on_OpenButton_pressed)
	%ClearButton.button_up.connect(clear_path)
	%Field.set_drag_forwarding(self)
	%Field.placeholder_text = placeholder

func set_right_text(value:String):
	$RightText.text = str(value)
	$RightText.visible = !value.is_empty()

func set_left_text(value:String):
	$LeftText.text = str(value)
	$LeftText.visible = !value.is_empty()

func set_value(value):
	%Field.text = value.get_file()
	%Field.tooltip_text = value
	%ClearButton.visible = !value.is_empty()

func _on_OpenButton_pressed() -> void:
	find_parent('EditorView').godot_file_dialog(_on_file_dialog_selected, file_filter, EditorFileDialog.FILE_MODE_OPEN_FILE, "Open "+ property_name)

func _on_file_dialog_selected(path:String) -> void:
	emit_signal("value_changed", property_name, path)
	set_value(path)
	
func clear_path():
	emit_signal("value_changed", property_name, "")
	set_value("")

func _can_drop_data_fw(position, data, from_control):
	if typeof(data) == TYPE_DICTIONARY and data.has('files') and len(data.files) == 1:
		if file_filter:
			if '*.'+data.files[0].get_extension() in file_filter:
				return true
		else: return true
	return false

func _drop_data_fw(position, data, from_control):
	_on_file_dialog_selected(data.files[0])
