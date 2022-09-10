@tool
extends Control

@export var placeholder_text : String = "Select Resource"

### SETTINGS FOR THE RESOURCE PICKER
var file_extension : String = ""
var get_suggestions_func : Array = [self, 'get_default_suggestions']
var empty_text : String = ""
@export var disable_pretty_name : bool = false

var resource_icon : Texture = null:
	get:
		return resource_icon
	set(new_icon):
		resource_icon = new_icon
		%Icon.custom_minimum_size.x = %Icon.size.y
		%Icon.texture = new_icon
		if new_icon == null:
			$Search.theme_type_variation = ""
		else:
			$Search.theme_type_variation = "LineEditWithIcon"

## STORING VALUE AND REFERENCE TO RESOURCE
var event_resource : DialogicEvent = null
var property_name : String
var current_value # Dynamic
var editor_reference

# this signal is on all event parts and informs the event that a change happened.
signal value_changed(property_name, value)

################################################################################
## 						BASIC EVENT PART FUNCTIONS
################################################################################
# These functions have to be implemented by all scenes that are used to display 
# values on the events.

func set_left_text(value:String) -> void:
	$LeftText.text = str(value)
	$LeftText.visible = !value.is_empty()

func set_right_text(value:String) -> void:
	$RightText.text = str(value)
	$RightText.visible = !value.is_empty()

func set_value(value, text : String = '') -> void:
	if value == null:
		$Search.text = empty_text
	elif file_extension != "" && file_extension != ".dch" && file_extension != ".dtl":
		
		$Search.text = value.resource_path
		$Search.tooltip_text = value.resource_path
	elif value:
		$Search.text = value
	else:
		$Search.text = empty_text
	if text:
		$Search.text = text
	
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
	DCSS.style($Search, {
		'border-radius': 3,
		'border-color': Color('#14161A'),
		'border': 1,
		'background': Color('#1D1F25'),
		'padding': [5, 25],
	})
	$Search.text_changed.connect(_on_Search_text_changed)
	$Search.focus_entered.connect(_on_Search_focus_entered)
	$Search.text_submitted.connect(_on_Search_text_entered)
	$Search/Icon.position.x = 0
	var scale: float = DialogicUtil.get_editor_scale()
	if scale == 2:
		$Search/Icon.position.x = 10
	$Search/SelectButton.icon = get_theme_icon("Collapse", "EditorIcons")
	$Search.placeholder_text = placeholder_text
	%Suggestions.add_theme_stylebox_override('bg', load("res://addons/dialogic/Editor/Events/styles/ResourceMenuPanelBackground.tres"))
	%Suggestions.hide()
	%Suggestions.item_selected.connect(suggestion_selected)
	if resource_icon == null:
		self.resource_icon = null
	set_left_text('')
	set_right_text('')
	editor_reference = find_parent('EditorView')

func _exit_tree():
	# Explicitly free any open cache resources on close, so we don't get leaked resource errors on shutdown
	event_resource = null

################################################################################
## 						SEARCH & SUGGESTION POPUP
################################################################################
func _on_Search_text_entered(new_text:String = "") -> void:
	if %Suggestions.get_item_count() and not $Search.text.is_empty():
		suggestion_selected(0)
	else:
		changed_to_empty()


func _on_Search_text_changed(new_text:String, just_update:bool = false) -> void:
	%Suggestions.clear()
	
	if new_text == "" and !just_update:
		changed_to_empty()

	var suggestions = get_suggestions_func[0].call(get_suggestions_func[1], new_text)
	
	var line_length:int = 0
	var more_hidden:bool = false
	var idx:int = 0
	for element in suggestions:
		if new_text != "" or idx < 12:
			line_length = max(get_theme_font('font', 'Label').get_string_size(element, HORIZONTAL_ALIGNMENT_LEFT, -1, get_theme_font_size("font_size", 'Label')).x+80, line_length)
			%Suggestions.add_item(element)
			if suggestions[element].has('icon'):
				%Suggestions.set_item_icon(idx, suggestions[element].icon)
			elif suggestions[element].has('editor_icon'):
				%Suggestions.set_item_icon(idx, get_theme_icon(suggestions[element].editor_icon[0],suggestions[element].editor_icon[1]))

			%Suggestions.set_item_tooltip(idx, suggestions[element].get('tooltip', ''))
			%Suggestions.set_item_metadata(idx, suggestions[element].value)
		else:
			more_hidden = true
			break
		idx += 1
	
	if more_hidden:
		%Suggestions.add_item('...', null, false)
		%Suggestions.set_item_disabled(idx, true)
		%Suggestions.set_item_tooltip(idx, "More items found. Start typing to search.")
	
	if not %Suggestions.visible:
		%Suggestions.show()
		%Suggestions.global_position = $Search.global_position+Vector2(0,1)*$Search.size.y
		%Suggestions.custom_minimum_size.x = max($Search.size.x, line_length)
	
	$Search.grab_focus()

func get_default_suggestions(search_text):
	if file_extension.is_empty(): return {'Nothing found!':{'value':''}}
	var suggestions: Dictionary = {}
	if file_extension == ".dch":
		suggestions['(No one)'] = {'value':'', 'editor_icon':["GuiRadioUnchecked", "EditorIcons"]}
		
		for resource in editor_reference.character_directory.keys():
			suggestions[resource] = {'value': resource, 'tooltip': editor_reference.character_directory[resource]['full_path']}
	else:
		var resources: Array = DialogicUtil.list_resources_of_type(file_extension)

		for resource in resources:
			if search_text.is_empty() or search_text.to_lower() in DialogicUtil.pretty_name(resource).to_lower():
				suggestions[resource] = {'value':resource, 'tooltip':resource}
		return suggestions


func suggestion_selected(index : int) -> void:
	if %Suggestions.is_item_disabled(index):
		return
	
	$Search.text = %Suggestions.get_item_text(index)
	
	# if this is a resource:
	if file_extension != "" && file_extension != ".dch" && file_extension != ".dtl":
		var file = load(%Suggestions.get_item_metadata(index))
		current_value = file
	else:
		current_value = %Suggestions.get_item_metadata(index)
	
	hide_suggestions()
	
	emit_signal("value_changed", property_name, current_value)

func _input(event:InputEvent):
	if event is InputEventMouseButton and event.pressed:
		if !%Suggestions.get_global_rect().has_point(get_global_mouse_position()):
			if %Suggestions.visible: hide_suggestions()


func hide_suggestions() -> void:
	$Search/SelectButton.button_pressed = false
	%Suggestions.hide()

func _on_Search_focus_entered() -> void:
	if $Search.text == "" or current_value == null or (typeof(current_value) == TYPE_STRING and current_value.is_empty()):
		_on_Search_text_changed("")

func _on_SelectButton_toggled(button_pressed:bool) -> void:
	if button_pressed:
		_on_Search_text_changed('', true)

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
