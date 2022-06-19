tool
extends Resource
class_name DialogicEvent

## The event color that event node will take in the editor
var event_color:Color = Color("FBB13C")

## The event name that'll be displayed in the editor.
## If the resource name is different from the event name, resource_name is returned instead.
var event_name:String = "Event"


var event_category:int = Category.OTHER


# To sort the buttons shown in the editor
var event_sorting_index : int = 0

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

# This is necessary to distinguish different ways value types might need to be represented
# It's used to communicate between the event resource and the event node, how a value
#    should be shown
enum ValueType {
	# STRINGS
	Label,
	MultilineText,
	SinglelineText,
	
	# OBJECTS ? (for the ResourcePicker)
	Timeline,
	Character,
	Portrait,
	
	# INTEGERS
	FixedOptionSelector,
	Integer,

	Float,
	
	Custom, 
}
var editor_list = []

# Hopefully we can replace this with a cleaner system
# maybe even generate them based on some markup? who knows, it is free to dream
var header : Array
var body : Array

var help_page_path : String = ""

var expand_by_default : bool = true
var needs_indentation : bool = false
var display_name : bool = true
var disable_editor_button : bool = false

# -----------------------------------------
# Emilio:
# Stuff I yet don't understand made by Dex:
# -----------------------------------------

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
var continue_at_end:bool = true setget _set_continue
var dialogic_game_handler = null

## Executes the event behaviour.
func execute(_dialogic_game_handler) -> void:
	emit_signal("event_started", self)
	dialogic_game_handler = _dialogic_game_handler
	call_deferred("_execute")


## Ends the event behaviour.
func finish() -> void:
	emit_signal("event_finished", self)


func _execute() -> void:
	finish()


func _set_continue(value:bool) -> void:
	continue_at_end = value
	property_list_changed_notify()
	emit_changed()


func _to_string() -> String:
	return "[{name}:{id}]".format({"name":event_name, "id":get_instance_id()})


func _hide_script_from_inspector():
	return true


func get_icon():
	var icon = load(self.get_script().get_path().get_base_dir() + "/icon.svg")
	if icon:
		return icon
	return load("res://addons/dialogic/Editor/Images/Event Icons/warning.svg")


func parse_shortcode_parameters(shortcode : String) -> Dictionary:
	var regex = RegEx.new()
	regex.compile('((?<parameter>[^\\s=]*)\\s*=\\s*"(?<value>[^"]*)")')
	var dict = {}
	for result in regex.search_all(shortcode):
		dict[result.get_string('parameter')] = result.get_string('value')
	return dict

################################################################################
## 					BUILDING THE EDITOR LIST
################################################################################
func clear_editor() -> void:
	editor_list.clear()


func add_header_label(text:String) -> void:
	editor_list.append({
		"name":"something", 				# Must be the same as the corresponding property that it edits!
		"type":TYPE_STRING,
		"location": Location.HEADER,		# Definest the location
		"usage":PROPERTY_USAGE_DEFAULT,	
		"dialogic_type":ValueType.Label,	# Define the type of node
		"display_info":{"text":text}, 
		})


func add_header_edit(variable:String, editor_type = ValueType.Label, left_text:String = "", right_text:String = "", extra_info:Dictionary = {}) -> void:
	editor_list.append({
		"name":variable, 				# Must be the same as the corresponding property that it edits!
		"type":typeof(get(variable)),
		"location": Location.HEADER,	# Definest the location
		"usage":PROPERTY_USAGE_DEFAULT,	
		"dialogic_type":editor_type,	# Define the type of node
		"display_info":extra_info,
		"left_text":left_text,			# Text that will be displayed left of the field
		"right_text":right_text,		# Text that will be displayed right of the field
		})


func add_body_edit(variable:String, editor_type = ValueType.Label, extra_info:Dictionary = {}) -> void:
	editor_list.append({
		"name":variable, 				# Must be the same as the corresponding property that it edits!
		"type":typeof(get(variable)),
		"location": Location.BODY,	# Definest the location
		"usage":PROPERTY_USAGE_DEFAULT,	
		"dialogic_type":editor_type,	# Define the type of node
		"display_info":extra_info,
		})

func build_event_editor():
	pass

func _get_property_list() -> Array:
	clear_editor()
	build_event_editor()
	return editor_list


func property_can_revert(property:String) -> bool:
	if property == "event_node_path":
		return true
	return false


func property_get_revert(property:String):
	if property == "event_node_path":
		return NodePath()

