@tool
extends DialogicVisualEditorField

## Event block field for strings. Options are determined by a function.


## SETTINGS
@export var placeholder_text := "Select Resource"
@export var empty_text := ""
enum Modes {PURE_STRING, PRETTY_PATH, IDENTIFIER}
@export var mode := Modes.PURE_STRING
@export var fit_text_length := true
var collapse_when_empty := false
var valid_file_drop_extension := ""
var get_suggestions_func: Callable

var resource_icon: Texture = null:
	get:
		return resource_icon
	set(new_icon):
		resource_icon = new_icon
		%Icon.texture = new_icon

## STATE
var current_value: String
var current_selected := 0


#region FIELD METHODS
################################################################################

func _set_value(value:Variant, text:String = '') -> void:
	if value == null or value.is_empty():
		%Search.text = empty_text
	else:
		match mode:
			Modes.PRETTY_PATH:
				%Search.text = DialogicUtil.pretty_name(value)
			Modes.IDENTIFIER when value.begins_with("res://"):
				%Search.text = DialogicResourceUtil.get_unique_identifier(value)
			_:
				%Search.text = str(value)

	%Search.visible = not collapse_when_empty or value
	current_value = str(value)



func _load_display_info(info:Dictionary) -> void:
	valid_file_drop_extension = info.get('file_extension', '')
	collapse_when_empty = info.get('collapse_when_empty', false)
	get_suggestions_func = info.get('suggestions_func', get_suggestions_func)
	empty_text = info.get('empty_text', '')
	placeholder_text = info.get('placeholder', 'Select Resource')
	mode = info.get("mode", 0)
	resource_icon = info.get('icon', null)
	await ready
	if resource_icon == null and info.has('editor_icon'):
		resource_icon = callv('get_theme_icon', info.editor_icon)


func _autofocus() -> void:
	%Search.grab_focus()

#endregion


#region BASIC
################################################################################

func _ready() -> void:
	%Focus.add_theme_stylebox_override('panel', get_theme_stylebox('focus', 'DialogicEventEdit'))

	%Search.text_changed.connect(_on_Search_text_changed)
	%Search.text_submitted.connect(_on_Search_text_entered)
	%Search.placeholder_text = placeholder_text
	%Search.expand_to_text_length = fit_text_length

	%SelectButton.icon = get_theme_icon("Collapse", "EditorIcons")

	%Suggestions.add_theme_stylebox_override('bg', load("res://addons/dialogic/Editor/Events/styles/ResourceMenuPanelBackground.tres"))
	%Suggestions.hide()
	%Suggestions.item_selected.connect(suggestion_selected)
	%Suggestions.item_clicked.connect(suggestion_selected)

	if resource_icon == null:
		self.resource_icon = null


func change_to_empty() -> void:
	value_changed.emit(property_name, "")

#endregion


#region SEARCH & SUGGESTION POPUP
################################################################################
func _on_Search_text_entered(new_text:String) -> void:
	if %Suggestions.get_item_count():
		if %Suggestions.is_anything_selected():
			suggestion_selected(%Suggestions.get_selected_items()[0])
		else:
			suggestion_selected(0)
	else:
		change_to_empty()


func _on_Search_text_changed(new_text:String, just_update:bool = false) -> void:
	%Suggestions.clear()

	if new_text == "" and !just_update:
		change_to_empty()
	else:
		%Search.show()

	var suggestions: Dictionary = get_suggestions_func.call(new_text)

	var line_length: int = 0
	var idx: int = 0
	for element in suggestions:
		if new_text.is_empty() or new_text.to_lower() in element.to_lower() or new_text.to_lower() in str(suggestions[element].value).to_lower() or new_text.to_lower() in suggestions[element].get('tooltip', '').to_lower():
			line_length = max(get_theme_font('font', 'Label').get_string_size(element, HORIZONTAL_ALIGNMENT_LEFT, -1, get_theme_font_size("font_size", 'Label')).x+80, line_length)
			%Suggestions.add_item(element)
			if suggestions[element].has('icon'):
				%Suggestions.set_item_icon(idx, suggestions[element].icon)
			elif suggestions[element].has('editor_icon'):
				%Suggestions.set_item_icon(idx, get_theme_icon(suggestions[element].editor_icon[0],suggestions[element].editor_icon[1]))

			%Suggestions.set_item_tooltip(idx, suggestions[element].get('tooltip', ''))
			%Suggestions.set_item_metadata(idx, suggestions[element].value)
			idx += 1

	if not %Suggestions.visible:
		%Suggestions.show()
		%Suggestions.global_position = $PanelContainer.global_position+Vector2(0,1)*$PanelContainer.size.y
		%Suggestions.size.x = max(%Search.size.x, line_length)
		%Suggestions.size.y = min(%Suggestions.get_item_count()*35*DialogicUtil.get_editor_scale(), 200*DialogicUtil.get_editor_scale())

	if %Suggestions.get_item_count():
		%Suggestions.select(0)
		current_selected = 0
	else:
		current_selected = -1

	%Search.grab_focus()


func suggestion_selected(index : int, position:=Vector2(), button_index:=MOUSE_BUTTON_LEFT) -> void:
	if button_index != MOUSE_BUTTON_LEFT:
		return
	if %Suggestions.is_item_disabled(index):
		return

	%Search.text = %Suggestions.get_item_text(index)

	if %Suggestions.get_item_metadata(index) == null:
		current_value = ""

	else:
		current_value = %Suggestions.get_item_metadata(index)

	hide_suggestions()

	grab_focus()
	value_changed.emit(property_name, current_value)


func _input(event:InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if %Suggestions.visible:
			if !%Suggestions.get_global_rect().has_point(get_global_mouse_position()) and \
				!%SelectButton.get_global_rect().has_point(get_global_mouse_position()):
				hide_suggestions()


func hide_suggestions() -> void:
	%SelectButton.set_pressed_no_signal(false)
	%Suggestions.hide()
	if !current_value and collapse_when_empty:
		%Search.hide()


func _on_SelectButton_toggled(button_pressed:bool) -> void:
	if button_pressed:
		_on_Search_text_changed('', true)
	else:
		hide_suggestions()


func _on_focus_entered() -> void:
	%Search.grab_focus()


func _on_search_gui_input(event: InputEvent) -> void:
	if event is InputEventKey and (event.keycode == KEY_DOWN or event.keycode == KEY_UP) and event.pressed:
		if !%Suggestions.visible:
			_on_Search_text_changed('', true)
			current_selected = -1
		if event.keycode == KEY_DOWN:
			current_selected = wrapi(current_selected+1, 0, %Suggestions.item_count)
		if event.keycode == KEY_UP:
			current_selected = wrapi(current_selected-1, 0, %Suggestions.item_count)
		%Suggestions.select(current_selected)
		%Suggestions.ensure_current_is_visible()

	if Input.is_key_pressed(KEY_CTRL):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if valid_file_drop_extension in [".dch", ".dtl"] and not current_value.is_empty():
				EditorInterface.edit_resource(DialogicResourceUtil.get_resource_from_identifier(current_value, valid_file_drop_extension))

		if valid_file_drop_extension in [".dch", ".dtl"] and not current_value.is_empty():
			%Search.mouse_default_cursor_shape = CURSOR_POINTING_HAND
	else:
		%Search.mouse_default_cursor_shape = CURSOR_IBEAM


func _on_search_focus_entered() -> void:
	if %Search.text == "" or current_value == "":
		_on_Search_text_changed("")
	%Search.call_deferred('select_all')
	%Focus.show()


func _on_search_focus_exited() -> void:
	%Focus.hide()
	if !%Suggestions.get_global_rect().has_point(get_global_mouse_position()):
		hide_suggestions()

#endregion


#region DRAG AND DROP
################################################################################

func _can_drop_data(position:Vector2, data:Variant) -> bool:
	if typeof(data) == TYPE_DICTIONARY and data.has('files') and len(data.files) == 1:
		if valid_file_drop_extension:
			if data.files[0].ends_with(valid_file_drop_extension):
				return true
		else:
			return false
	return false


func _drop_data(position:Vector2, data:Variant) -> void:
	var path := str(data.files[0])
	if mode == Modes.IDENTIFIER:
		path = DialogicResourceUtil.get_unique_identifier(path)
	_set_value(path)
	value_changed.emit(property_name, path)

#endregion
