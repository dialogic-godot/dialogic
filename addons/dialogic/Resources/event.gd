@tool
class_name DialogicEvent
extends Resource

## Base event class for all dialogic events.
## Implements basic properties, translation, shortcode saving and usefull methods for creating
## the editor UI.


## Emmited when the event starts.
## The signal is emmited with the event resource [code]event_resource[/code]
signal event_started(event_resource:DialogicEvent)

## Emmited when the event finish.
## The signal is emmited with the event resource [code]event_resource[/code]
signal event_finished(event_resource:DialogicEvent)


### Main Event Properties ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

## The event name that'll be displayed in the editor.
var event_name: String = "Event"
## Unique identifier used for translatable events.
var _translation_id: String = ""
## A reference to dialogic during execution, can be used the same as Dialogic (reference to the autoload)
var dialogic: DialogicGameHandler = null


### Special Event Properties ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
### (these properties store how this event affects indentation/flow of timeline)

## If true this event can not be toplevel (e.g. Choice)
var needs_indentation: bool = false
## If true this event will spawn with an END BRANCH event and higher the indentation
var can_contain_events: bool = false
## If [can_contain_events] is true this is a reference to the end branch event
var end_branch_event: DialogicEndBranchEvent = null
## If this is true this event will group with other similar events (like choices do).
var wants_to_group: bool = false


### Saving/Loading Properties ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

## Stores the event in a text format. Does NOT automatically update.
var event_node_as_text: String = ""
## Flags if the event has been processed or is only stored as text
var event_node_ready: bool = false
## How many empty lines are before this event
var empty_lines_above:int = 0


### Editor UI Properties ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

## The event color that event node will take in the editor
var event_color: Color = Color("FBB13C")
## If you are using the default color palette
var dialogic_color_name: String = ''
## To sort the buttons shown in the editor. Lower index is placed at the top of a category
var event_sorting_index: int = 0
## If true the event will not have a button in the visual editor sidebar
var disable_editor_button: bool = false
## If false the event will hide it's body by default. Recommended for most events
var expand_by_default: bool = false
## The URL to open when right_click>Documentation is selected
var help_page_path: String = ""
## Is the event block created by a button?
var created_by_button: bool = false

## Reference to the node, that represents this event. Only works while in visual editor mode.
## Use with care.
var _editor_node: Control = null

## The categories and which one to put it in (in the visual editor sidebar)
var event_category: String = "Other"


### Editor UI creation ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

## To differentiate fields that should go to the header and to the body
enum Location {HEADER, BODY}

## To differentiate the different types of fields for event properties in the visual editor
enum ValueType {
	# Strings
	MULTILINE_TEXT, SINGLELINE_TEXT, CONDITION, FILE,
	# Booleans
	BOOL, BOOL_BUTTON,
	# Options
	DYNAMIC_OPTIONS, FIXED_OPTIONS,
	# Containers,
	ARRAY, DICTIONARY,
	# Numbers
	NUMBER,
	VECTOR2, VECTOR3, VECTOR4,
	# Other
	CUSTOM, BUTTON, LABEL, COLOR
}
## List that stores the fields for the editor
var editor_list: Array = []
## Singal that notifies the visual editor block to update
signal ui_update_needed
signal ui_update_warning(text:String)


## Makes this resource printable.
func _to_string() -> String:
	return "[{name}:{id}]".format({"name":event_name, "id":get_instance_id()})

#endregion


#region EXECUTION
################################################################################

## Executes the event behaviour. In subclasses [_execute] (not this one) should be overriden!
func execute(_dialogic_game_handler) -> void:
	event_started.emit(self)
	dialogic = _dialogic_game_handler
	call_deferred("_execute")


## Ends the event behaviour.
func finish() -> void:
	event_finished.emit(self)


## To be overridden by subclasses.
func _execute() -> void:
	finish()

#endregion


#region OVERRIDABLES
################################################################################

## to be overridden by sub-classes
## only called if can_contain_events is true.
## return a control node that should show on the END BRANCH node
func get_end_branch_control() -> Control:
	return null


## to be overridden by sub-classes
## only called if can_contain_events is true and the previous event was an end-branch event
## return true if this event should be executed if the previous event was an end-branch event
## basically only important for the Condition event but who knows. Some day someone might need this.
func should_execute_this_branch() -> bool:
	return false

#endregion


#region TRANSLATIONS
################################################################################

## Overwrite if this events needs translation.
func _get_translatable_properties() -> Array:
	return []


## Overwrite if this events needs translation.
func _get_property_original_translation(property_name:String) -> String:
	return ''


## Returns true if there is any translatable properties on this event.
## Overwrite [_get_translatable_properties()] to change this.
func can_be_translated() -> bool:
	return !_get_translatable_properties().is_empty()


## This is automatically called, no need to use this.
func add_translation_id() -> String:
	_translation_id = DialogicUtil.get_next_translation_id()
	return _translation_id


func remove_translation_id() -> void:
	_translation_id = ""


func get_property_translation_key(property_name:String) -> String:
	return event_name.path_join(_translation_id).path_join(property_name)


## Call this whenever you are using a translatable property
func get_property_translated(property_name:String) -> String:
	if !_translation_id.is_empty() and ProjectSettings.get_setting('dialogic/translation/enabled', false):
		var translation := tr(get_property_translation_key(property_name))
		# if no translation is found tr() returns the id, but we want to fallback to the original
		return translation if translation != get_property_translation_key(property_name) else _get_property_original_translation(property_name)
	else:
		return _get_property_original_translation(property_name)

#endregion


#region SAVE / LOAD (internal, don't override)
################################################################################
### These functions are used by the timeline loader/saver
### They mainly use the overridable behaviour below, but enforce the unique_id saving

## Used by the Timeline saver.
func _store_as_string() -> String:
	if !_translation_id.is_empty() and can_be_translated():
		return to_text() + ' #id:'+str(_translation_id)
	else:
		return to_text()


## Call this if you updated an event and want the changes to be saved.
func update_text_version() -> void:
	event_node_as_text = _store_as_string()


## Used by timeline processor.
func _load_from_string(string:String) -> void:
	_load_custom_defaults()
	if '#id:' in string and can_be_translated():
		_translation_id = string.get_slice('#id:', 1).strip_edges()
		from_text(string.get_slice('#id:', 0))
	else:
		from_text(string)
	event_node_ready = true


## Assigns the custom defaults
func _load_custom_defaults():
	for default_prop in DialogicUtil.get_custom_event_defaults(event_name):
		if default_prop in self:
			set(default_prop, DialogicUtil.get_custom_event_defaults(event_name)[default_prop])


## Used by the timeline processor.
func _test_event_string(string:String) -> bool:
	if '#id:' in string and can_be_translated():
		return is_valid_event(string.get_slice('#id:', 0))
	return is_valid_event(string.strip_edges())

#endregion


#region SAVE / LOAD
################################################################################
### All of these functions can/should be overridden by the sub classes

## if this uses the short-code format, return the shortcode
func get_shortcode() -> String:
	return 'default_shortcode'


## if this uses the short-code format, return the parameters and corresponding property names
func get_shortcode_parameters() -> Dictionary:
	return {}


## returns a readable presentation of the event (This is how it's stored)
## by default it uses a shortcode format, but can be overridden
func to_text() -> String:
	var result_string: String = "["+self.get_shortcode()
	var params: Dictionary = get_shortcode_parameters()
	var custom_defaults: Dictionary = DialogicUtil.get_custom_event_defaults(event_name)
	for parameter in params.keys():
		if (typeof(get(params[parameter].property)) != typeof(custom_defaults.get(params[parameter].property, params[parameter].default))) or \
		(get(params[parameter].property) != custom_defaults.get(params[parameter].property, params[parameter].default)):
			if typeof(get(params[parameter].property)) == TYPE_OBJECT:
				result_string += " "+parameter+'="'+str(get(params[parameter].property).resource_path)+'"'
			elif typeof(get(params[parameter].property)) == TYPE_STRING:
				result_string += " "+parameter+'="'+get(params[parameter].property).replace('=', "\\=")+'"'
			# if this is an enum with values provided, try to use a text alternative
			elif typeof(get(params[parameter].property)) == TYPE_INT and params[parameter].has('suggestions'):
				for option in params[parameter].suggestions.call().values():
					if option.value == get(params[parameter].property):
						if option.has('text_alt'):
							result_string += " "+parameter+'="'+option.text_alt[0]+'"'
						else:
							result_string += " "+parameter+'="'+var_to_str(option.value).replace('=', "\\=")+'"'
						break
			elif typeof(get(params[parameter].property)) == TYPE_DICTIONARY:
				result_string += " "+parameter+'="'+ JSON.stringify(get(params[parameter].property)).replace('=', "\\=")+'"'
			else:
				result_string += " "+parameter+'="'+var_to_str(get(params[parameter].property)).replace('=', "\\=")+'"'
	result_string += "]"
	return result_string


## loads the variables from the string stored above
## by default it uses the shortcode format, but can be overridden
func from_text(string:String) -> void:
	var data: Dictionary = parse_shortcode_parameters(string)
	var params: Dictionary = get_shortcode_parameters()
	for parameter in params.keys():
		if not parameter in data:
			continue

		var value: Variant
		match typeof(get(params[parameter].property)):
			TYPE_STRING:
				value = data[parameter].replace('\\=', '=')
			TYPE_INT:
				if params[parameter].has('suggestions'):
					for option in params[parameter].suggestions.call().values():
						if option.has('text_alt') and data[parameter] in option.text_alt:
							value = option.value
							break
				if !value:
					value = float(data[parameter].replace('\\=', '='))
			_:
				value = str_to_var(data[parameter].replace('\\=', '='))
		set(params[parameter].property, value)


## has to return true, if the given string can be interpreted as this event
## by default it uses the shortcode formta, but can be overridden
func is_valid_event(string:String) -> bool:
	if string.strip_edges().begins_with('['+get_shortcode()+' ') or string.strip_edges().begins_with('['+get_shortcode()+']'):
		return true
	return false


## has to return true if this string seems to be a full event of this kind
## (only tested if is_valid_event() returned true)
## if a shortcode it used it will default to true if the string ends with ']'
func is_string_full_event(string:String) -> bool:
	if get_shortcode() != 'default_shortcode': return string.strip_edges().ends_with(']')
	return true


## used to get all the shortcode parameters in a string as a dictionary
func parse_shortcode_parameters(shortcode : String) -> Dictionary:
	var regex: RegEx = RegEx.new()
	regex.compile('((?<parameter>[^\\s=]*)\\s*=\\s*"(?<value>([^=]|\\\\=)*)(?<!\\\\)")')
	var dict: Dictionary = {}
	for result in regex.search_all(shortcode):
		dict[result.get_string('parameter')] = result.get_string('value')
	return dict

#endregion


#region EDITOR REPRESENTATION
################################################################################

func _get_icon() -> Resource:
	var _icon_file_name := "res://addons/dialogic/Editor/Images/Pieces/closed-icon.svg" # Default
	# Check for both svg and png, but prefer svg if available
	if ResourceLoader.exists(self.get_script().get_path().get_base_dir() + "/icon.svg"):
		_icon_file_name = self.get_script().get_path().get_base_dir() + "/icon.svg"
	elif ResourceLoader.exists(self.get_script().get_path().get_base_dir() + "/icon.png"):
		_icon_file_name = self.get_script().get_path().get_base_dir() + "/icon.png"
	return load(_icon_file_name)


func set_default_color(value:Variant) -> void:
	dialogic_color_name = value
	event_color = DialogicUtil.get_color(value)


## Called when the resource is assigned to a event block in the visual editor
func _enter_visual_editor(timeline_editor:DialogicEditor) -> void:
	pass

#endregion


#region CODE COMPLETION
################################################################################

## This method can be overwritten to implement code completion for custom syntaxes
func _get_code_completion(CodeCompletionHelper:Node, TextNode:TextEdit, line:String, word:String, symbol:String) -> void:
	pass

## This method can be overwritten to add starting suggestions for this event
func _get_start_code_completion(CodeCompletionHelper:Node, TextNode:TextEdit) -> void:
	pass

#endregion


#region SYNTAX HIGHLIGHTING
################################################################################

func _get_syntax_highlighting(Highlighter:SyntaxHighlighter, dict:Dictionary, line:String) -> Dictionary:
	return dict

#endregion


#region EVENT FIELDS
################################################################################

func get_event_editor_info() -> Array:
	if Engine.is_editor_hint():
		if editor_list != null:
			editor_list.clear()
		else:
			editor_list = []

		build_event_editor()
		return editor_list
	else:
		return []


## to be overwritten by the sub_classes
func build_event_editor() -> void:
	pass

## For the methods below the arguments are mostly similar:
## @variable: 		String name of the property this field is for
## @condition: 		String that will be executed as an expression. If it false
## @editor_type: 	One of the ValueTypes (see ValueType enum). Defines type of field.
## @left_text: 		Text that will be shown to the left of the field
## @right_text: 	Text that will be shown to the right of the field
## @extra_info: 	Allows passing a lot more info to the field.
## 					What info can be passed is differnet for every field

func add_header_label(text:String, condition:= "") -> void:
	editor_list.append({
		"name" 			: "something",
		"type" 			:+ TYPE_STRING,
		"location" 		: Location.HEADER,
		"usage" 		: PROPERTY_USAGE_EDITOR,
		"field_type" : ValueType.LABEL,
		"display_info"  : {"text":text},
		"condition" 	: condition
		})


func add_header_edit(variable:String, editor_type := ValueType.LABEL, extra_info:= {}, condition:= "") -> void:
	editor_list.append({
		"name" 			: variable,
		"type" 			: typeof(get(variable)),
		"location" 		: Location.HEADER,
		"usage" 		: PROPERTY_USAGE_DEFAULT,
		"field_type" : editor_type,
		"display_info" 	: extra_info,
		"left_text" 	: extra_info.get('left_text', ''),
		"right_text" 	: extra_info.get('right_text', ''),
		"condition" 	: condition,
		})


func add_header_button(text:String, callable:Callable, tooltip:String, icon: Variant = null, condition:= "") -> void:
	editor_list.append({
		"name"			: "Button",
		"type" 			: TYPE_STRING,
		"location" 		: Location.HEADER,
		"usage" 		: PROPERTY_USAGE_DEFAULT,
		"field_type" : ValueType.BUTTON,
		"display_info" 	: {'text':text, 'tooltip':tooltip, 'callable':callable, 'icon':icon},
		"condition" 	: condition,
	})


func add_body_edit(variable:String, editor_type := ValueType.LABEL, extra_info:= {}, condition:= "") -> void:
	editor_list.append({
		"name" 			: variable,
		"type" 			: typeof(get(variable)),
		"location" 		: Location.BODY,
		"usage" 		: PROPERTY_USAGE_DEFAULT,
		"field_type" : editor_type,
		"display_info" 	: extra_info,
		"left_text" 	: extra_info.get('left_text', ''),
		"right_text" 	: extra_info.get('right_text', ''),
		"condition" 	: condition,
		})


func add_body_line_break(condition:= "") -> void:
	editor_list.append({
		"name" 		: "linebreak",
		"type" 		: TYPE_BOOL,
		"location" 	: Location.BODY,
		"usage" 	: PROPERTY_USAGE_DEFAULT,
		"condition" : condition,
		})

#endregion
