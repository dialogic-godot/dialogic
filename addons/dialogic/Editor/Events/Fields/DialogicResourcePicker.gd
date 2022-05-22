tool
extends Control


## SETTINGS FOR THE RESOURCE PICKER
enum resource_types {Characters, Timelines, Themes, Portraits}
var resource_type = resource_types.Characters

var file_extensions : Dictionary = {
	resource_types.Characters : '.dch',
	resource_types.Timelines : '.dtl',
	}
# I'm so sorry for this, but the popup_hide signal get's triggered if the popup is hidden by me,
# and I don't want it to change the resource, if one was just selected by clicking
var ignore_popup_hide_once = false


## STORING VALUE AND REFERENCE TO RESOURCE
var event_resource : DialogicEvent = null
var property_name : String
var current_value

# this signal is on all event parts and informs the event that a change happened.
signal value_changed

################################################################################
## 						BASIC EVENT PART FUNCTIONS
################################################################################
# These functions have to be implemented by all scenes that are used to display 
# values on the events.

func set_hint(value):
	$Hint.text = str(value)

func set_value(value):
	if value is DialogicCharacter:
		$Search.text = value.name
		$Search/OpenButton.show()
	else:
		$Search.text = "Nothing selected"
		$Search/OpenButton.hide()
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
		set_value(current_value)

func _on_Search_text_changed(new_text):
	$Search/Suggestions.clear()
	
	if new_text != "":
		var ext = ""
		if resource_type in file_extensions:
			ext = file_extensions[resource_type]
		else:
			return
		var resources = DialogicUtil.list_resources_of_type(ext)
		#print(characters)
		var idx = 0
		for element in resources:
			if new_text.to_lower() in element.to_lower().get_file().trim_suffix(ext):
				$Search/Suggestions.add_item(element.get_file().trim_suffix(ext))
				$Search/Suggestions.set_item_metadata(idx, element)
				idx += 1
		
		if not $Search/Suggestions.visible:
			$Search/Suggestions.popup(Rect2($Search.rect_global_position + Vector2(0,1)*$Search.rect_size, Vector2($Search.rect_size.x, 100)))
			$Search.grab_focus()
	else:
		$Search/Suggestions.hide()
	
func suggestion_selected(index):
	var file = load($Search/Suggestions.get_item_metadata(index))
	$Search.text = file.name
	current_value = file
	emit_signal("value_changed", property_name, file)
	ignore_popup_hide_once = true
	$Search/Suggestions.hide()
	
	$Search/OpenButton.show()

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
		if resource_type in file_extensions:
			if data.files[0].ends_with(file_extensions[resource_type]):
				return true
		else:
			return false
	return false
	
func drop_data(position, data):
	var file = load(data.files[0])
	$Search.text = file.name
	current_value = file
	emit_signal("value_changed", property_name, file)

	$Search/OpenButton.show()



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
