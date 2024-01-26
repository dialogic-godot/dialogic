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
	dialogic.Inputs.auto_skip.enabled = false
	dialogic.current_state = DialogicGameHandler.States.WAITING
	dialogic.TextInput.show_text_input(text, default, placeholder, allow_empty)
	dialogic.TextInput.input_confirmed.connect(_on_DialogicTextInput_input_confirmed, CONNECT_ONE_SHOT)


func _on_DialogicTextInput_input_confirmed(input:String) -> void:
	if !dialogic.has_subsystem('VAR'):
		printerr('[Dialogic] The TextInput event needs the variable subsystem to be present.')
		finish()
		return
	dialogic.VAR.set_variable(variable, input)
	dialogic.TextInput.hide_text_input()
	dialogic.current_state = DialogicGameHandler.States.IDLE
	finish()


################################################################################
## 						SAVING/LOADING
################################################################################

func _init() -> void:
	event_name = "Text Input"
	set_default_color('Color6')
	event_category = "Logic"
	event_sorting_index = 6


################################################################################
## 						SAVING/LOADING
################################################################################

func get_shortcode() -> String:
	return "text_input"


func get_shortcode_parameters() -> Dictionary:
	return {
		#param_name 	: property_info
		"text"			: {"property": "text", 			"default": "Please enter some text:"},
		"var"			: {"property": "variable", 		"default": "", "suggestions":get_var_suggestions},
		"placeholder"	: {"property": "placeholder", 	"default": ""},
		"default"		: {"property": "default", 		"default": ""},
		"allow_empty"	: {"property": "allow_empty",	"default": false},
	}

################################################################################
## 						EDITOR
################################################################################

func build_event_editor() -> void:
	add_header_label('Show an input and store it in')
	add_header_edit('variable', ValueType.DYNAMIC_OPTIONS,
			{'suggestions_func'	: get_var_suggestions,
			'icon'		 : load("res://addons/dialogic/Editor/Images/Pieces/variable.svg"),
			'placeholder':'Select Variable'})
	add_body_edit('text', ValueType.SINGLELINE_TEXT, {'left_text':'Text:'})
	add_body_edit('placeholder', ValueType.SINGLELINE_TEXT, {'left_text':'Placeholder:'})
	add_body_edit('default', ValueType.SINGLELINE_TEXT, {'left_text':'Default:'})
	add_body_edit('allow_empty', ValueType.BOOL, {'left_text':'Allow empty:'})


func get_var_suggestions(filter:String="") -> Dictionary:
	var suggestions := {}
	if filter:
		suggestions[filter] = {
			'value'			: filter,
			'editor_icon'	: ["GuiScrollArrowRight", "EditorIcons"]}
	var vars :Dictionary = ProjectSettings.get_setting('dialogic/variables', {})
	for var_path in DialogicUtil.list_variables(vars, "", DialogicUtil.VarTypes.STRING):
		suggestions[var_path] = {'value':var_path, 'icon':load("res://addons/dialogic/Editor/Images/Pieces/variable.svg")}
	return suggestions
