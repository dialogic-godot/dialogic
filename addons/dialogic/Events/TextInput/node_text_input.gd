class_name DialogicNode_TextInput
extends Control

## Node that will show when a text input field is reached. 
## Should be connected to a (probably contained) label, a line edit and a button to work.

## The LineEdit to use.
@export_node_path var input_line_edit:NodePath
## The Label to use.
@export_node_path var text_label:NodePath
## The Button to use.
@export_node_path var confirmation_button:NodePath

# This is set by the subsystem and used as a confirmation check.
var _allow_empty : bool = false


func _ready():
	add_to_group('dialogic_text_input')
	if confirmation_button:
		get_node(confirmation_button).pressed.connect(_on_confirmation_button_pressed)
	if input_line_edit:
		get_node(input_line_edit).text_changed.connect(_on_input_text_changed)
	visible = false


func set_text(text:String) -> void:
	if get_node(text_label) is Label:
		get_node(text_label).text = text


func set_placeholder(placeholder:String) -> void:
	if get_node(input_line_edit) is LineEdit:
		get_node(input_line_edit).placeholder_text = placeholder
		get_node(input_line_edit).grab_focus()


func set_default(default:String) -> void:
	if get_node(input_line_edit) is LineEdit:
		get_node(input_line_edit).text = default
		_on_input_text_changed(default)


func set_allow_empty(boolean:bool) -> void:
	_allow_empty = boolean


func _on_input_text_changed(text:String) -> void:
	if confirmation_button.is_empty():
		return
	get_node(confirmation_button).disabled = !_allow_empty and text.is_empty()


func _on_confirmation_button_pressed() -> void:
	if get_node(input_line_edit) is LineEdit:
		if !get_node(input_line_edit).text.is_empty() or _allow_empty:
			Dialogic.TextInput.input_confirmed.emit(get_node(input_line_edit).text)
