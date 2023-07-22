@tool
extends Control

## Event block field for resources/options.


# this signal is on all event parts and informs the event that a change happened.
signal value_changed(property_name, value)
var property_name : String
var event_resource : DialogicEvent = null

### SETTINGS FOR THE RESOURCE PICKER
@export var placeholder_text : String = "Select Resource"
var file_extension : String = ""
var get_suggestions_func : Callable = get_default_suggestions
var empty_text : String = ""
@export var enable_pretty_name : bool = false
@export var fit_text_length : bool = true

var resource_icon : Texture = null:
	get:
		return resource_icon
	set(new_icon):
		resource_icon = new_icon
		%Icon.texture = new_icon

## STORING VALUE AND REFERENCE TO RESOURCE
var current_value :Variant # Dynamic
var editor_reference

var current_selected = 0

################################################################################
## 						BASIC EVENT PART FUNCTIONS
################################################################################

func set_value(value:Variant, text : String = '') -> void:
	if value == null:
		%Search.text = empty_text
	elif file_extension != "" and file_extension != ".dch" and file_extension != ".dtl":
		%Search.text = value.resource_path
		%Search.tooltip_text = value.resource_path
	elif value:
		if enable_pretty_name:
			%Search.text = DialogicUtil.pretty_name(value)
		else:
			%Search.text = value
	else:
		%Search.text = empty_text
	if text:
		%Search.text = text
	
	current_value = value


func changed_to_empty() -> void:
	if file_extension != "" && file_extension != ".dch":
		emit_signal("value_changed", property_name, null)
	else:
		emit_signal("value_changed", property_name, "")
		

################################################################################
## 						BASIC
################################################################################
func _ready():
	%BG.add_theme_stylebox_override('panel', get_theme_stylebox('normal', 'LineEdit'))
	%Focus.add_theme_stylebox_override('panel', get_theme_stylebox('focus', 'LineEdit'))
	%Search.text_changed.connect(_on_Search_text_changed)
	%Search.text_submitted.connect(_on_Search_text_entered)
	var scale: float = DialogicUtil.get_editor_scale()
	%SelectButton.icon = get_theme_icon("Collapse", "EditorIcons")
	%Search.placeholder_text = placeholder_text
	%Search.expand_to_text_length = fit_text_length
	%Suggestions.add_theme_stylebox_override('bg', load("res://addons/dialogic/Editor/Events/styles/ResourceMenuPanelBackground.tres"))
	%Suggestions.hide()
	%Suggestions.item_selected.connect(suggestion_selected)
	%Suggestions.item_clicked.connect(suggestion_selected)
	if resource_icon == null:
		self.resource_icon = null
	
	editor_reference = find_parent('EditorView')


func _exit_tree():
	# Explicitly free any open cache resources on close, so we don't get leaked resource errors on shutdown
	event_resource = null


func take_autofocus():
	%Search.grab_focus()

################################################################################
## 						SEARCH & SUGGESTION POPUP
################################################################################
func _on_Search_text_entered(new_text:String) -> void:
	if %Suggestions.get_item_count() and not %Search.text.is_empty():
		if %Suggestions.is_anything_selected():
			suggestion_selected(%Suggestions.get_selected_items()[0])
		else:
			suggestion_selected(0)
	else:
		changed_to_empty()


func _on_Search_text_changed(new_text:String, just_update:bool = false) -> void:
	%Suggestions.clear()
	
	if new_text == "" and !just_update:
		changed_to_empty()

	var suggestions :Dictionary = get_suggestions_func.call(new_text)
	
	var line_length:int = 0
	var idx:int = 0
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
		#%Suggestions.position = Vector2()
		%Suggestions.size.x = max(%Search.size.x, line_length)
		%Suggestions.size.y = min(%Suggestions.get_item_count()*35*DialogicUtil.get_editor_scale(), 200*DialogicUtil.get_editor_scale())
	if %Suggestions.get_item_count():
		%Suggestions.select(0)
		current_selected = 0
	else:
		current_selected = -1
	%Search.grab_focus()


func get_default_suggestions(input:String) -> Dictionary:
	if file_extension.is_empty(): return {'Nothing found!':{'value':''}}
	var suggestions: Dictionary = {}
	if file_extension == ".dch":
		suggestions['(No one)'] = {'value':'', 'editor_icon':["GuiRadioUnchecked", "EditorIcons"]}
		
		for resource in editor_reference.character_directory.keys():
			suggestions[resource] = {'value': resource, 'tooltip': editor_reference.character_directory[resource]['full_path']}
	else:
		var resources: Array = DialogicUtil.list_resources_of_type(file_extension)

		for resource in resources:
			suggestions[resource] = {'value':resource, 'tooltip':resource}
	
	return suggestions


func suggestion_selected(index : int, position:=Vector2(), button_index:=MOUSE_BUTTON_LEFT) -> void:
	if button_index != MOUSE_BUTTON_LEFT:
		return
	if %Suggestions.is_item_disabled(index):
		return
	
	%Search.text = %Suggestions.get_item_text(index)
	
	if %Suggestions.get_item_metadata(index) == null:
		current_value = null
	
	# if this is a resource, then load it instead of assigning the string:
	elif file_extension != "" and file_extension != ".dch" and file_extension != ".dtl":
		var file = load(%Suggestions.get_item_metadata(index))
		current_value = file
	else:
		current_value = %Suggestions.get_item_metadata(index)
	
	hide_suggestions()
	
	%Search.grab_focus()
	emit_signal("value_changed", property_name, current_value)

func _input(event:InputEvent):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if %Suggestions.visible:
			if !%Suggestions.get_global_rect().has_point(get_global_mouse_position()):
				hide_suggestions()
		

func hide_suggestions() -> void:
	%SelectButton.button_pressed = false
	%Suggestions.hide()


func _on_SelectButton_toggled(button_pressed:bool) -> void:
	if button_pressed:
		_on_Search_text_changed('', true)

func _on_focus_entered():
	%Search.grab_focus()



func _on_search_gui_input(event):
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

func _on_search_focus_entered():
	if %Search.text == "" or current_value == null or (typeof(current_value) == TYPE_STRING and current_value.is_empty()):
		_on_Search_text_changed("")
	%Search.call_deferred('select_all')
	%Focus.show()


func _on_search_focus_exited():
	%Focus.hide()
	if !%Suggestions.get_global_rect().has_point(get_global_mouse_position()):
		hide_suggestions()

################################################################################
##	 					DRAG AND DROP
################################################################################

func _can_drop_data(position, data) -> bool:
	if typeof(data) == TYPE_DICTIONARY and data.has('files') and len(data.files) == 1:
		if file_extension:
			if data.files[0].ends_with(file_extension):
				return true
		else:
			return false
	return false
	
func _drop_data(position, data) -> void:
	if data.files[0].ends_with('dch'):
		for character in editor_reference.character_directory.keys():
			if editor_reference.character_directory[character]["full_path"] == data.files[0]:
				set_value(character)
				break
	elif data.files[0].ends_with('dtl'):
		for timeline in editor_reference.timeline_directory.keys():
			if editor_reference.timeline_directory[timeline] == data.files[0]:
				set_value(timeline)
				break
	else:
		var file = load(data.files[0])
		set_value(file)
		emit_signal("value_changed", property_name, file)

