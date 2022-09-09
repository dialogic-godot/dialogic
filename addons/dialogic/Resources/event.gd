@tool
extends Resource
class_name DialogicEvent

## The event color that event node will take in the editor
var event_color:Color = Color("FBB13C")
## If you are using the default color palette
var dialogic_color_name:String = ''

## The event name that'll be displayed in the editor.
## If the resource name is different from the event name, resource_name is returned instead.
var event_name:String = "Event"

# To sort the buttons shown in the editor
var event_sorting_index : int = 0

# A property used for runtime, to verify if it's been loaded yet or not
var event_node_ready : bool = false
var event_node_as_text : String = ""

enum Category {
	MAIN,
	LOGIC,
	TIMELINE,
	AUDIOVISUAL,
	GODOT,
	OTHER,
}

enum Location {
	HEADER,
	BODY
}

var event_category:int = Category.OTHER

var help_page_path : String = ""

var display_name : bool = true
var disable_editor_button : bool = false
var expand_by_default : bool = true


# This is necessary to distinguish different ways value types might need to be represented
# It's used to communicate between the event resource and the event node, how a value
#    should be shown
enum ValueType {
	# STRINGS
	Label,
	MultilineText,
	SinglelineText,
	Condition,
	
	Bool,
	
	# "Resources"
	ComplexPicker,
	File,
	
	StringArray,
	
	# INTEGERS
	FixedOptionSelector,
	Integer,
	Vector2,

	Float,
	Decibel,
	
	Custom, 
}
var editor_list : Array = []

var needs_indentation : bool = false

##
# This means it will always spawn with a END BRANCH event
var can_contain_events : bool = false
var end_branch_event : DialogicEndBranchEvent = null
var needs_parent_event : bool = false

var translation_id = null

# This file is part of EventSystem, distributed under MIT license
# and modified to work with Dialogic.
# You can see the license of this file here
# https://github.com/AnidemDex/Godot-EventSystem/blob/main/LICENSE


## 
## Base class for all events.
##
## @desc: 
##    Every event relies on this class. 
##    If you want to do your own event, you should [code]extend[/code] this class.
##

## Emmited when the event starts.
## The signal is emmited with the event resource [code]event_resource[/code]
signal event_started(event_resource)

## Emmited when the event finish. 
## The signal is emmited with the event resource [code]event_resource[/code]
signal event_finished(event_resource)

##########
# EVENT EXECUTION PROPERTIES
##########

## Determines if the event will go to next event inmediatly or not. 
## If value is true, the next event will be executed when event ends.
var continue_at_end:bool = true #setget _set_continue
var dialogic = null

## Executes the event behaviour.
func execute(_dialogic_game_handler) -> void:
	emit_signal("event_started", self)
	dialogic = _dialogic_game_handler
	call_deferred("_execute")


## Ends the event behaviour.
func finish() -> void:
	emit_signal("event_finished", self)


func _execute() -> void:
	finish()


func _set_continue(value:bool) -> void:
	continue_at_end = value
	notify_property_list_changed()
	emit_changed()


func _to_string() -> String:
	return "[{name}:{id}]".format({"name":event_name, "id":get_instance_id()})


func get_icon() -> Resource:
	var ext : String = '.png'
	var icon := load(self.get_script().get_path().get_base_dir() + "/icon" + ext)
	if icon:
		return icon
	return load("res://addons/dialogic/Editor/Images/Pieces/warning.svg")


func set_default_color(value) -> void:
	dialogic_color_name = value
	event_color = DialogicUtil.get_color(value)
	
# to be overridden by sub-classes
func get_required_subsystems() -> Array:
	return []

# to be overridden by sub-classes
# if needs_parent_event is true, this needs to return true if the event is that event
func is_expected_parent_event(event:DialogicEvent) -> bool:
	return false

# to be overridden by sub-classes
# only called if can_contain_events is true. 
# return a control node that should show on the END BRANCH node
func get_end_branch_control() -> Control:
	return null


# to be overridden by sub-classes
# only called if can_contain_events is true and the previous event was an end-branch event
# return true if this event should be executed if the previous event was an end-branch event
# basically only important for the Condition event but who knows. Some day someone might need this.
func should_execute_this_branch() -> bool:
	return false

################################################################################
## 					TRANSLATIONS
################################################################################
func can_be_translated() -> bool:
	return false

func get_original_translation_text() -> String:
	return ''

func add_translation_id() -> String:
	translation_id = "%x" % [get_instance_id()]
	return translation_id

func get_translated_text() -> String:
	if translation_id and DialogicUtil.get_project_setting('dialogic/translation_enabled', false):
		return tr(translation_id) if tr(translation_id) != translation_id else get_original_translation_text()
	else:
		return get_original_translation_text()

################################################################################
## 					PARSE AND STRINGIFY
################################################################################
# These functions are used by the timeline loader/saver
# They mainly use the overridable behaviour below, but enforce the unique_id saving

func _store_as_string() -> String:
	if translation_id and can_be_translated():
		return to_text() + ' #id:'+str(translation_id)
	else:
		return to_text()


func _load_from_string(string:String) -> void:
	if '#id:' in string and can_be_translated():
		translation_id = string.get_slice('#id:', 1).strip_edges()
		from_text(string.get_slice('#id:', 0))
		event_node_ready = true
	else:
		from_text(string)
		event_node_ready = true


func _test_event_string(string:String) -> bool:
	if '#id:' in string and can_be_translated():
		return is_valid_event(string.get_slice('#id:', 0)) 
	return is_valid_event(string.strip_edges())


################################################################################
## 					PARSE AND STRINGIFY
################################################################################
## All of these functions can/should be overridden by the sub classes

# if this uses the short-code format, return the shortcode
func get_shortcode() -> String:
	return 'default_shortcode'

# if this uses the short-code format, return the parameters and corresponding property names
func get_shortcode_parameters() -> Dictionary:
	return {}

# returns a readable presentation of the event (This is how it's stored)
# by default it uses a shortcode format, but can be overridden
func to_text() -> String:
	var result_string : String = "["+self.get_shortcode()
	var params : Dictionary = get_shortcode_parameters()
	for parameter in params.keys():
		if get(params[parameter]):
			if typeof(get(params[parameter])) == TYPE_OBJECT:
				result_string += " "+parameter+'="'+str(get(params[parameter]).resource_path)+'"'
			elif typeof(get(params[parameter])) == TYPE_STRING:
				result_string += " "+parameter+'="'+get(params[parameter]).replace('=', "\\=")+'"'
			else:
				result_string += " "+parameter+'="'+var_to_str(get(params[parameter])).replace('=', "\\=")+'"'
	result_string += "]"
	return result_string


# loads the variables from the string stored above
# by default it uses the shortcode format, but can be overridden
func from_text(string:String) -> void:
	var data : Dictionary = parse_shortcode_parameters(string)
	var params : Dictionary = get_shortcode_parameters()
	for parameter in params.keys():
		if not parameter in data:
			continue
			
		#if typeof(data[parameter]) == TYPE_STRING and (data[parameter].ends_with(".dtl") or data[parameter].ends_with(".dch")):
		if typeof(data[parameter]) == TYPE_STRING and (data[parameter].ends_with(".dch")):
			set(params[parameter], load(data[parameter]))
		else:
			var value = str_to_var(data[parameter].replace('\\=', '=')) if str_to_var(data[parameter].replace('\\=', '=')) != null else data[parameter].replace('\\=', '=')
			set(params[parameter], value)


# has to return true, if the given string can be interpreted as this event
# by default it uses the shortcode formta, but can be overridden
func is_valid_event(string:String) -> bool:
	if string.strip_edges().begins_with('['+get_shortcode()):
		return true
	return false

# has to return true if this string seems to be a full event of this kind 
# (only tested if is_valid_event() returned true)
# if a shortcode it used it will default to true if the string ends with ']'
func is_string_full_event(string:String) -> bool:
	if get_shortcode() != 'default_shortcode': return string.strip_edges().ends_with(']')
	return true


# used to get all the shortcode parameters in a string as a dictionary
func parse_shortcode_parameters(shortcode : String) -> Dictionary:
	var regex:RegEx = RegEx.new()
	regex.compile('((?<parameter>[^\\s=]*)\\s*=\\s*"(?<value>([^=]|\\\\=)*)(?<!\\\\)")')
	var dict : Dictionary = {}
	for result in regex.search_all(shortcode):
		dict[result.get_string('parameter')] = result.get_string('value')
	return dict

################################################################################
## 					BUILDING THE EDITOR LIST
################################################################################
func _get_property_list() -> Array:
	if Engine.is_editor_hint():
		if editor_list != null:
			editor_list.clear()
		else:
			editor_list = []
		
		build_event_editor()
		return editor_list
	else:
		return []

# to be overwriten by the sub_classes
func build_event_editor() -> void:
	pass


func add_header_label(text:String, condition:String = "") -> void:
	editor_list.append({
		"name":"something", 				# Must be the same as the corresponding property that it edits!
		"type":TYPE_STRING,
		"location": Location.HEADER,		# Definest the location
		"usage":PROPERTY_USAGE_EDITOR,	
		"dialogic_type":ValueType.Label,	# Define the type of node
		"display_info":{"text":text}, 
		"condition":condition
		})


func add_header_edit(variable:String, editor_type = ValueType.Label, left_text:String = "", right_text:String = "", extra_info:Dictionary = {}, condition:String = "") -> void:
	editor_list.append({
		"name":variable, 				# Must be the same as the corresponding property that it edits!
		"type":typeof(get(variable)),
		"location": Location.HEADER,	# Definest the location
		"usage":PROPERTY_USAGE_DEFAULT,	
		"dialogic_type":editor_type,	# Define the type of node
		"display_info":extra_info,
		"left_text":left_text,			# Text that will be displayed left of the field
		"right_text":right_text,		# Text that will be displayed right of the field
		"condition":condition,			# If true (or empty), the edit is shown
		})


func add_body_edit(variable:String, editor_type = ValueType.Label, left_text:String= "", right_text:String="", extra_info:Dictionary = {}, condition:String = "") -> void:
	editor_list.append({
		"name":variable, 				# Must be the same as the corresponding property that it edits!
		"type":typeof(get(variable)),
		"location": Location.BODY,	# Definest the location
		"usage":PROPERTY_USAGE_DEFAULT,	
		"dialogic_type":editor_type,	# Define the type of node
		"display_info":extra_info,
		"left_text":left_text,			# Text that will be displayed left of the field
		"right_text":right_text,		# Text that will be displayed right of the field
		"condition":condition,			# If true (or empty), the edit is shown
		})

func add_body_line_break(condition:String = ""):
	editor_list.append({
		"name":"linebreak", 				# Must be the same as the corresponding property that it edits!
		"type":TYPE_BOOL,
		"location": Location.BODY,	# Definest the location
		"usage":PROPERTY_USAGE_DEFAULT,	
		"condition":condition,			# If true (or empty), the edit is shown
		})

func property_can_revert(property:String) -> bool:
	if property == "event_node_path":
		return true
	return false


func property_get_revert(property:String):
	if property == "event_node_path":
		return NodePath()
