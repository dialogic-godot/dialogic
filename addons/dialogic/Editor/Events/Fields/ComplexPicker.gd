@tool
extends Control

@export var placeholder_text:String = "Select Resource"

### SETTINGS FOR THE RESOURCE PICKER
var file_extension = ""
var get_suggestions_func = [self, 'get_default_suggestions']
var empty_text = ""
var disable_pretty_name := false

var resource_icon:Texture = null:
	get:
		return resource_icon
	set(new_icon):
		resource_icon = new_icon
		$'%Icon'.custom_minimum_size.x = $'%Icon'.size.y
		$'%Icon'.texture = new_icon
		if new_icon == null:
			$Search.theme_type_variation = ""
		else:
			$Search.theme_type_variation = "LineEditWithIcon"

# I'm so sorry for this, but the popup_hide signal get's triggered if the popup is hidden by me,
# and I don't want it to change the resource, if one was just selected by clicking
var ignore_popup_hide_once = false

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

func set_rightt_text(value:String):
	$RightText.text = str(value)
	$RightText.visible = !value.is_empty()

func set_value(value):
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
		'border-color': '#14161A',
		'border': 1,
		'background': '#1D1F25',
		'padding': [5, 25],
	})
	$Search.text_changed.connect(_on_Search_text_changed)
	$Search.focus_entered.connect(_on_Search_focus_entered)
	$Search/Icon.position.x = 0
	var scale = DialogicUtil.get_editor_scale()
	if scale == 2:
		$Search/Icon.position.x = 10
	$Search/SelectButton.icon = get_theme_icon("Collapse", "EditorIcons")
	$Search.placeholder_text = placeholder_text
	$Search/Suggestions.hide()
	$Search/Suggestions.index_pressed.connect(suggestion_selected)
	$Search/Suggestions.popup_hide.connect(popup_hide)
	#TODO: Invalid call. Nonexistent function 'add_theme_stylebox_override' in base 'PopupMenu'.
	#$Search/Suggestions.add_theme_stylebox_override('panel', load("res://addons/dialogic/Editor/Events/styles/ResourceMenuPanelBackground.tres"))
	if resource_icon == null:
		self.resource_icon = null


################################################################################
## 						SEARCH & SUGGESTION POPUP
################################################################################
func _on_Search_text_entered(new_text = ""):
	if $Search/Suggestions.get_item_count() and not $Search.text.is_empty():
		suggestion_selected(0)
	else:
		changed_to_empty()

func _on_Search_text_changed(new_text, just_update = false):
	$Search/Suggestions.clear()
	
	if new_text == "" and !just_update:
		changed_to_empty()
	
	ignore_popup_hide_once = just_update
	
	var suggestions = get_suggestions_func[0].call(get_suggestions_func[1], new_text)
	
	var more_hidden = false
	var idx = 0
	for element in suggestions:
		if new_text != "" or idx < 12:
			if suggestions[element].has('icon'):
				$Search/Suggestions.add_icon_item(suggestions[element].icon, element)
			elif suggestions[element].has('editor_icon'):
				$Search/Suggestions.add_icon_item(get_theme_icon(suggestions[element].editor_icon[0],suggestions[element].editor_icon[1]), element)
			else:
				$Search/Suggestions.add_item(element)
			$Search/Suggestions.set_item_tooltip(idx, suggestions[element].get('tooltip', ''))
			$Search/Suggestions.set_item_metadata(idx, suggestions[element].value)
		else:
			more_hidden = true
			break
		idx += 1
	
	if more_hidden:
		$Search/Suggestions.add_item('...')
		$Search/Suggestions.set_item_disabled(idx, true)
	
	if not $Search/Suggestions.visible:
#		$Search/Suggestions.popup(Rect2(get_viewport().get_visible_rect().position+$Search.global_position + Vector2(0,1)*$Search.size, Vector2($Search.size.x, 100)))
		$Search/Suggestions.popup_on_parent(Rect2i($Search.get_global_rect().position+Vector2(0,$Search.size.y), Vector2($Search.size.x, 50)))
		#(Rect2(get_viewport().get_visible_rect().position+$Search.global_position, Vector2()))
		$Search.grab_focus()


func get_default_suggestions(search_text):
	if !file_extension: return {}
	var suggestions = {}
	var resources = DialogicUtil.list_resources_of_type(file_extension)

	for resource in resources:
		if search_text.is_empty() or search_text.to_lower() in DialogicUtil.pretty_name(resource).to_lower():
			suggestions[DialogicUtil.pretty_name(resource)] = {'value':resource, 'tooltip':resource}
	return suggestions
	
func suggestion_selected(index):
	$Search.text = $Search/Suggestions.get_item_text(index)
	
	# if this is a resource:
	if file_extension:
		var file = load($Search/Suggestions.get_item_metadata(index))
		current_value = file
	else:
		current_value = $Search/Suggestions.get_item_metadata(index)
	
	ignore_popup_hide_once = true
	$Search/Suggestions.hide()
	
	emit_signal("value_changed", property_name, current_value)
	
func popup_hide():
	$Search/SelectButton.button_pressed = false
	if ignore_popup_hide_once:
		ignore_popup_hide_once = false
		return
	if $Search/Suggestions.get_item_count() and not $Search.text.is_empty():
		suggestion_selected(0)
	else:
		set_value(null)
		changed_to_empty()

func _on_Search_focus_entered():
	if $Search.text == "" or current_value == null or (typeof(current_value) == TYPE_STRING and current_value.is_empty()):
		_on_Search_text_changed("")

func _on_SelectButton_toggled(button_pressed):
	if button_pressed:
		_on_Search_text_changed('', true)

################################################################################
##	 					DRAG AND DROP
################################################################################

func can_drop_data(position, data):
	if typeof(data) == TYPE_DICTIONARY and data.has('files') and len(data.files) == 1:
		if file_extension:
			if data.files[0].ends_with(file_extension):
				return true
		else:
			return false
	return false
	
func drop_data(position, data):
	var file = load(data.files[0])
	set_value(file)
	emit_signal("value_changed", property_name, file)
