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

## SUGGESTIONS ITEM LIST
var _v_separation := 0
var _h_separation := 0
var _icon_margin := 0
var _line_height := 24
var _max_height := 200 * DialogicUtil.get_editor_scale()


#region FIELD METHODS
################################################################################

func _set_value(value:Variant) -> void:
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
	%Search.tooltip_text = info.get('tooltip_text', '')
	await ready
	if resource_icon == null and info.has('editor_icon'):
		resource_icon = callv('get_theme_icon', info.editor_icon)


func _autofocus() -> void:
	%Search.grab_focus()

#endregion


#region BASIC
################################################################################

func _ready() -> void:
	var focus := get_theme_stylebox("focus", "LineEdit")
	if has_theme_stylebox("focus", "DialogicEventEdit"):
		focus = get_theme_stylebox('focus', 'DialogicEventEdit')
	%Focus.add_theme_stylebox_override('panel', focus)

	%Search.text_changed.connect(_on_Search_text_changed)
	%Search.text_submitted.connect(_on_Search_text_entered)
	%Search.placeholder_text = placeholder_text
	%Search.expand_to_text_length = fit_text_length

	%SelectButton.icon = get_theme_icon("Collapse", "EditorIcons")

	%Suggestions.add_theme_stylebox_override('bg', load("res://addons/dialogic/Editor/Events/styles/ResourceMenuPanelBackground.tres"))
	%Suggestions.hide()
	%Suggestions.item_selected.connect(suggestion_selected)
	%Suggestions.item_clicked.connect(suggestion_selected)
	%Suggestions.fixed_icon_size = Vector2i(16, 16) * DialogicUtil.get_editor_scale()

	_v_separation = %Suggestions.get_theme_constant("v_separation")
	_h_separation = %Suggestions.get_theme_constant("h_separation")
	_icon_margin = %Suggestions.get_theme_constant("icon_margin")

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

	if new_text == "" and not just_update:
		change_to_empty()
	else:
		%Search.show()

	if just_update and new_text.is_empty() and %Search.text.ends_with("."):
		new_text = %Search.text

	var suggestions: Dictionary = get_suggestions_func.call(new_text)

	var line_length := 0
	var idx := 0
	for element in suggestions:
		if new_text.is_empty() or new_text.to_lower() in element.to_lower() or new_text.to_lower() in str(suggestions[element].value).to_lower() or new_text.to_lower() in suggestions[element].get('tooltip', '').to_lower():
			var curr_line_length: int = 0
			curr_line_length = get_theme_font('font', 'Label').get_string_size(
				element, HORIZONTAL_ALIGNMENT_LEFT, -1, get_theme_font_size("font_size", 'Label')
			).x

			%Suggestions.add_item(element)
			if suggestions[element].has('icon'):
				%Suggestions.set_item_icon(idx, suggestions[element].icon)
				curr_line_length += %Suggestions.fixed_icon_size.x * %Suggestions.get_icon_scale() + _icon_margin * 2 + _h_separation
			elif suggestions[element].has('editor_icon'):
				%Suggestions.set_item_icon(idx, get_theme_icon(suggestions[element].editor_icon[0],suggestions[element].editor_icon[1]))
				curr_line_length += %Suggestions.fixed_icon_size.x * %Suggestions.get_icon_scale() + _icon_margin * 2 + _h_separation

			line_length = max(line_length, curr_line_length)

			%Suggestions.set_item_tooltip(idx, suggestions[element].get('tooltip', ''))
			%Suggestions.set_item_metadata(idx, suggestions[element].value)
			idx += 1

	if not %Suggestions.visible:
		%Suggestions.show()
		%Suggestions.global_position = $PanelContainer.global_position+Vector2(0,1)*$PanelContainer.size.y

	if %Suggestions.item_count:
		%Suggestions.select(0)
		current_selected = 0
	else:
		current_selected = -1
	%Search.grab_focus()

	var total_height: int = 0
	for item in %Suggestions.item_count:
		total_height += _line_height * DialogicUtil.get_editor_scale() + _v_separation
	total_height += _v_separation * 2
	if total_height > _max_height:
		line_length += %Suggestions.get_v_scroll_bar().get_minimum_size().x

	%Suggestions.size.x = max(%PanelContainer.size.x, line_length)
	%Suggestions.size.y = min(total_height, _max_height)

	# Defer setting width to give PanelContainer
	# time to update it's size
	await get_tree().process_frame
	await get_tree().process_frame

	%Suggestions.size.x = max(%PanelContainer.size.x, line_length)


func suggestion_selected(index: int, position := Vector2(), button_index := MOUSE_BUTTON_LEFT) -> void:
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
	if %Search.text == "":
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
