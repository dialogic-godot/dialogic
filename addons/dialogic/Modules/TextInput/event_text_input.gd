@tool
class_name DialogicTextInputEvent
extends DialogicEvent

## Event that shows an input field and will change a dialogic variable.


### Settings

## The promt to be shown.
var text := "Please enter some text:"
## The name/path of the variable to set.
var variable := ""
## The placeholder text to show in the line edit.
var placeholder := ""
## The value that should be in the line edit by default.
var default := ""
## If true, the player can continue if nothing is entered.
var allow_empty := false


#region EXECUTION
################################################################################

func _execute() -> void:
	dialogic.Inputs.auto_skip.enabled = false
	dialogic.current_state = DialogicGameHandler.States.WAITING
	dialogic.TextInput.show_text_input(
		get_property_translated("text"),
		get_property_translated("default"),
		get_property_translated("placeholder"), allow_empty)
	dialogic.TextInput.input_confirmed.connect(_on_DialogicTextInput_input_confirmed, CONNECT_ONE_SHOT)


func _on_DialogicTextInput_input_confirmed(input:String) -> void:
	if not dialogic.has_subsystem('VAR'):
		printerr('[Dialogic] The TextInput event needs the variable subsystem to be present.')
		finish()
		return
	dialogic.VAR.set_variable(variable, input)
	dialogic.TextInput.hide_text_input()
	dialogic.current_state = DialogicGameHandler.States.IDLE
	finish()

#endregion


#region SETUP
################################################################################

func _init() -> void:
	event_name = "Text Input"
	event_description = "Shows a text input field and stores it to a dialogic variable."
	set_default_color('Color6')
	event_category = "Logic"
	event_sorting_index = 6

#endregion


#region SAVING/LOADING
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


func _get_translatable_properties() -> Array:
	return ["text", "placeholder", "default"]


func _get_property_original_translation(property_name:String) -> String:
	match property_name:
		"text":
			return text
		"placeholder":
			return placeholder
		"default":
			return default
	return ""

#endregion


#region EDITOR
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


func get_var_suggestions(filter: String = "") -> Dictionary:
	var suggestions := {}
	if filter:
		suggestions[filter] = {
			'value'			: filter,
			'editor_icon'	: ["GuiScrollArrowRight", "EditorIcons"]}
	var vars: Dictionary = ProjectSettings.get_setting('dialogic/variables', {})
	for var_path in DialogicUtil.list_variables(vars, "", DialogicUtil.VarTypes.STRING):
		suggestions[var_path] = {'value':var_path, 'icon':load("res://addons/dialogic/Editor/Images/Pieces/variable.svg")}
	return suggestions

#endregion
