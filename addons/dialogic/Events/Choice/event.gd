tool
extends DialogicEvent
class_name DialogicChoiceEvent

enum IfFalseActions {HIDE, DISABLE, DEFAULT}

# DEFINE ALL PROPERTIES OF THE EVENT
var Text :String = ""
var Condition:String = ""
var IfFalseAction = IfFalseActions.DEFAULT

func _execute() -> void:
	# I have no idea how this event works
	finish()

func get_required_subsystems() -> Array:
	return [
				{'name':'Choices',
				'subsystem': get_script().resource_path.get_base_dir().plus_file('Subsystem_Choices.gd'),
				'settings':get_script().resource_path.get_base_dir().plus_file('ChoicesSettings.tscn'),
				},
			]


################################################################################
## 						INITIALIZE
################################################################################

# SET ALL VALUES THAT SHOULD NEVER CHANGE HERE
func _init() -> void:
	event_name = "Choice"
	set_default_color('Color3')
	event_category = Category.LOGIC
	event_sorting_index = 0
	expand_by_default = false


################################################################################
## 						SAVING/LOADING
################################################################################

## THIS RETURNS A READABLE REPRESENTATION, BUT HAS TO CONTAIN ALL DATA (This is how it's stored)
func get_as_string_to_store() -> String:
	var result_string = ""

	result_string = "- "+Text
	if Condition:
		result_string += " [if "+Condition+"]"
	
	if IfFalseAction == IfFalseActions.HIDE:
		result_string += " [else hide]"
	elif IfFalseAction == IfFalseActions.DISABLE:
		result_string += " [else disable]"
	
	return result_string


## THIS HAS TO READ ALL THE DATA FROM THE SAVED STRING (see above) 
func load_from_string_to_store(string:String):
	var regex = RegEx.new()
	regex.compile('- (?<text>[^\\[]*)(\\[if (?<condition>[^\\]]+)])?\\s?(\\[else (?<else_option>[^\\]\\n]*)\\])?')
	var result = regex.search(string.strip_edges())
	
	Text = result.get_string('text')
	Condition = result.get_string('condition')
	if result.get_string('else_option'):
		IfFalseAction = {
			'default':IfFalseActions.DEFAULT, 
			'hide':IfFalseActions.HIDE,
			'disable':IfFalseActions.DISABLE}.get(result.get_string('else_option'), IfFalseActions.DEFAULT)

# RETURN TRUE IF THE GIVEN LINE SHOULD BE LOADED AS THIS EVENT
func is_valid_event_string(string:String) -> bool:
	
	if string.strip_edges().begins_with("-"):
		return true
	
	return false


func can_be_translated():
	return true
	
func get_original_translation_text():
	return Text


################################################################################
## 						EDITOR REPRESENTATION
################################################################################

func build_event_editor():
	add_header_edit("Text", ValueType.SinglelineText)
	add_body_edit("Condition", ValueType.SinglelineText, 'if ')
	add_body_edit("IfFalseAction", ValueType.FixedOptionSelector, 'else ', '', {'selector_options':{"Default":IfFalseActions.DEFAULT, "Hide":IfFalseActions.HIDE, "Disable":IfFalseActions.DISABLE}}, '!Condition.empty()')
