@tool
class_name DialogicTextInputEvent
extends DialogicEvent

## Event that shows an input field and will change a dialogic variable.


### Settings

## The promt to be shown.
var text: String = "Please enter some text:"
## The name/path of the variable to set.
var variable: String = ""
## The placeholder text to show in the line edit.
var placeholder: String = ""
## The value that should be in the line edit by default.
var default: String = ""
## If true, the player can continue if nothing is entered.
var allow_empty : bool = false


################################################################################
## 						EXECUTION
################################################################################

func _execute() -> void:
	dialogic.current_state = Dialogic.states.WAITING
	dialogic.TextInput.show_text_input(text, default, placeholder, allow_empty)
	dialogic.TextInput.input_confirmed.connect(_on_DialogicTextInput_input_confirmed)


func _on_DialogicTextInput_input_confirmed(input:String) -> void:
	assert (Dialogic.has_subsystem('VAR'), \
			'The TextInput event needs the variable subsystem to be present.')
	dialogic.VAR.set_variable(variable, input)
	dialogic.TextInput.hide_text_input()
	dialogic.current_state = Dialogic.states.IDLE
	finish()


################################################################################
## 						SAVING/LOADING
################################################################################

func _init() -> void:
	event_name = "text Input"
	set_default_color('Color1')
	event_category = Category.Godot
	event_sorting_index = 6
	continue_at_end = true
	expand_by_default = false


################################################################################
## 						SAVING/LOADING
################################################################################

func get_shortcode() -> String:
	return "text_input"


func get_shortcode_parameters() -> Dictionary:
	return {
		#param_name 	: property_info
		"text"			: {"property": "text", 			"default": "Please enter some text:"},
		"var"			: {"property": "variable", 		"default": ""},
		"placeholder"	: {"property": "placeholder", 	"default": ""},
		"default"		: {"property": "default", 		"default": ""},
		"allow_empty"	: {"property": "allow_empty",	"default": false},
	}

################################################################################
## 						EDITOR
################################################################################

func build_event_editor() -> void:
	add_header_label('Show an input field. The value will be stored to')
	add_header_edit('variable', ValueType.ComplexPicker, '', '', 
			{'suggestions_func'	: get_var_suggestions, 
			'editor_icon'		: ["ClassList", "EditorIcons"]})
	add_body_edit('text', ValueType.SinglelineText, 'text:')
	add_body_edit('placeholder', ValueType.SinglelineText, 'placeholder:')
	add_body_edit('default', ValueType.SinglelineText, 'default:')
	add_body_edit('allow_empty', ValueType.Bool, 'Allow empty:')


func get_var_suggestions(filter:String) -> Dictionary:
	var suggestions := {}
	if filter:
		suggestions[filter] = {
			'value'			: filter, 
			'editor_icon'	: ["GuiScrollArrowRight", "EditorIcons"]}
	var vars :Dictionary = DialogicUtil.get_project_setting('dialogic/variables', {})
	for var_path in DialogicUtil.list_variables(vars):
		suggestions[var_path] = {'value':var_path, 'editor_icon':["ClassList", "EditorIcons"]}
	return suggestions
