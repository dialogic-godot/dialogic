@tool
extends Control

@export var placeholder_text:String = "Select Resource"

### SETTINGS FOR THE RESOURCE PICKER
var file_extension = ""
var get_suggestions_func = [self, 'get_default_suggestions']
var empty_text = ""
@export var disable_pretty_name := false

var resource_icon:Texture = null:
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
var current_value

# this signal is on all event parts and informs the event that a change happened.
signal value_changed(property_name, value)

################################################################################
## 						BASIC EVENT PART FUNCTIONS
################################################################################
# These functions have to be implemented by all scenes that are used to display 
# values on the events.

func set_left_text(value:String):
	$LeftText.text = str(value)
	$LeftText.visible = !value.is_empty()

func set_right_text(value:String):
	$RightText.text = str(value)
	$RightText.visible = !value.is_empty()

func set_value(value, text = ''):
	if value == null:
		$Search.text = empty_text
	elif file_extension:
		
		$Search.text = DialogicUtil.pretty_name(value.resource_path)
		$Search.hint_tooltip = value.resource_path
	elif value:
		if disable_pretty_name:
			$Search.text =value
		else:
			$Search.text = DialogicUtil.pretty_name(value)
	else:
		$Search.text = empty_text
	if text:
		$Search.text = text
	current_value = value


func changed_to_empty():
	if file_extension:
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
	var scale = DialogicUtil.get_editor_scale()
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


################################################################################
## 						SEARCH & SUGGESTION POPUP
################################################################################
func _on_Search_text_entered(new_text = ""):
	if %Suggestions.get_item_count() and not $Search.text.is_empty():
		suggestion_selected(0)
	else:
		changed_to_empty()


func _on_Search_text_changed(new_text, just_update = false):
	%Suggestions.clear()
	
	if new_text == "" and !just_update:
		changed_to_empty()

	var suggestions = get_suggestions_func[0].call(get_suggestions_func[1], new_text)
	
	var line_length = 0
	var more_hidden = false
	var idx = 0
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
	var suggestions = {}
	var resources = DialogicUtil.list_resources_of_type(file_extension)

	for resource in resources:
		if search_text.is_empty() or search_text.to_lower() in DialogicUtil.pretty_name(resource).to_lower():
			suggestions[DialogicUtil.pretty_name(resource)] = {'value':resource, 'tooltip':resource}
	return suggestions
	
func suggestion_selected(index):
	if %Suggestions.is_item_disabled(index):
		return
	
	$Search.text = %Suggestions.get_item_text(index)
	
	# if this is a resource:
	if file_extension:
		var file = load(%Suggestions.get_item_metadata(index))
		current_value = file
	else:
		current_value = %Suggestions.get_item_metadata(index)
	
	hide_suggestions()
	
	emit_signal("value_changed", property_name, current_value)

func _input(event):
	if event is InputEventMouseButton and event.pressed:
		if !%Suggestions.get_global_rect().has_point(get_global_mouse_position()):
			if %Suggestions.visible: hide_suggestions()

func hide_suggestions():
	$Search/SelectButton.button_pressed = false
	%Suggestions.hide()

func _on_Search_focus_entered():
	if $Search.text == "" or current_value == null or (typeof(current_value) == TYPE_STRING and current_value.is_empty()):
		_on_Search_text_changed("")

func _on_SelectButton_toggled(button_pressed):
	if button_pressed:
		_on_Search_text_changed('', true)

################################################################################
##	 					DRAG AND DROP
################################################################################

func _can_drop_data(position, data):
	if typeof(data) == TYPE_DICTIONARY and data.has('files') and len(data.files) == 1:
		if file_extension:
			if data.files[0].ends_with(file_extension):
				return true
		else:
			return false
	return false
	
func _drop_data(position, data):
	var file = load(data.files[0])
	set_value(file)
	emit_signal("value_changed", property_name, file)
