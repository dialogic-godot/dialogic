tool
extends Control


### SETTINGS FOR THE RESOURCE PICKER
var file_extension = ""
var get_suggestions_func = [self, 'get_default_suggestions']
var empty_text = ""

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

func set_left_text(value):
	$LeftText.text = str(value)
	$LeftText.visible = bool(value)

func set_rightt_text(value):
	$RightText.text = str(value)
	$RightText.visible = bool(value)

func set_value(value):
	if value == null:
		$Search.text = empty_text
	elif file_extension:
		$Search.text = DialogicUtil.pretty_name(value.resource_path)
		$Search.hint_tooltip = value.resource_path
	elif value:
		$Search.text = DialogicUtil.pretty_name(value)
	else:
		$Search.text = empty_text

	current_value = value


################################################################################
## 						BASIC
################################################################################
func _ready():
	$Search/Suggestions.hide()
	$Search/Suggestions.connect("index_pressed", self, 'suggestion_selected')
	$Search/Suggestions.connect("popup_hide", self, 'popup_hide')
	$Search/OpenButton.icon = get_icon("EditResource", "EditorIcons")


################################################################################
## 						SEARCH & SUGGESTION POPUP
################################################################################
func _on_Search_text_entered(new_text = ""):
	if $Search/Suggestions.get_item_count() and not $Search.text.empty():
		suggestion_selected(0)
	else:
		emit_signal("value_changed", property_name, null)

func _on_Search_text_changed(new_text):
	$Search/Suggestions.clear()
	
	if new_text != "":
		var suggestions = get_suggestions_func[0].call(get_suggestions_func[1], new_text)
		
		var idx = 0
		for element in suggestions:
			$Search/Suggestions.add_item(element) #element.get_file().trim_suffix(ext))
			$Search/Suggestions.set_item_metadata(idx, suggestions[element])
			idx += 1
		
		if not $Search/Suggestions.visible:
			$Search/Suggestions.popup(Rect2($Search.rect_global_position + Vector2(0,1)*$Search.rect_size, Vector2($Search.rect_size.x, 100)))
			$Search.grab_focus()
	
	else:
		emit_signal("value_changed", property_name, null)
		$Search/Suggestions.hide()

func get_default_suggestions(search_text):
	if !file_extension: return {}
	var suggestions = {}
	var resources = DialogicUtil.list_resources_of_type(file_extension)
	for resource in resources:
		if search_text.to_lower() in DialogicUtil.pretty_name(resource).to_lower():
			suggestions[DialogicUtil.pretty_name(resource)] = resource
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
	#if resource_type != resource_types.Portraits: $Search/OpenButton.show()
	
	emit_signal("value_changed", property_name, current_value)

func popup_hide():
	if ignore_popup_hide_once:
		ignore_popup_hide_once = false
		return
	if $Search/Suggestions.get_item_count() and not $Search.text.empty():
		suggestion_selected(0)
	else:
		set_value(current_value)


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


################################################################################
##	 					OPEN RESOURCE BUTTON
################################################################################
# This function triggers the resource to be opened in the inspector and possible editors provided by plugins
func _on_OpenButton_pressed():
	if current_value:
		var dialogic_plugin = get_tree().root.get_node('EditorNode/DialogicPlugin')
		if typeof(current_value) == TYPE_STRING and not current_value.empty():
			dialogic_plugin._editor_interface.inspect_object(load(current_value))
		elif typeof(current_value) == TYPE_OBJECT:
			dialogic_plugin._editor_interface.inspect_object(current_value)
