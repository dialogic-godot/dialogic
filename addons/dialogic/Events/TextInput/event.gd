@tool
extends DialogicEvent
class_name DialogicTextInputEvent

var Text : String = "Please enter some text:"
var Variable : String = ""
var Placeholder : String = ""
var Default : String = ""
var AllowEmpty : bool = false

func _execute() -> void:
	dialogic.current_state = Dialogic.states.WAITING
	dialogic.TextInput.show_text_input(Text, Default, Placeholder, AllowEmpty)
	dialogic.TextInput.input_confirmed.connect(_on_DialogicTextInput_input_confirmed)

func _on_DialogicTextInput_input_confirmed(input:String) -> void:
	assert (Dialogic.has_subsystem('VAR'), 'The TextInput event needs the variable subsystem to be present.')
	dialogic.VAR.set_variable(Variable, input)
	dialogic.TextInput.hide_text_input()
	dialogic.current_state = Dialogic.states.IDLE
	finish()

func get_required_subsystems() -> Array:
	return [
				{'name':'TextInput',
				'subsystem': get_script().resource_path.get_base_dir().path_join('Subsystem_TextInput.gd'),
				},
			]

func _init() -> void:
	event_name = "Text Input"
	set_default_color('Color1')
	event_category = Category.GODOT
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
		#param_name 	: property_name
		"text"			: "Text",
		"var"			: "Variable",
		"placeholder"	: "Placeholder",
		"default"		: "Default",
		"allow_empty"	: "AllowEmpty"
	}

################################################################################
## 						EDITOR
################################################################################
func build_event_editor() -> void:
	add_header_label('Show an input field. The value will be stored to')
	add_header_edit('Variable', ValueType.ComplexPicker, '', '', {'suggestions_func':get_var_suggestions, 'editor_icon':["ClassList", "EditorIcons"]})
	add_body_edit('Text', ValueType.SinglelineText, 'Text:')
	add_body_edit('Placeholder', ValueType.SinglelineText, 'Placeholder:')
	add_body_edit('Default', ValueType.SinglelineText, 'Default:')
	add_body_edit('AllowEmpty', ValueType.Bool, 'Allow empty:')


func get_var_suggestions(filter:String) -> Dictionary:
	var suggestions := {}
	if filter:
		suggestions[filter] = {'value':filter, 'editor_icon':["GuiScrollArrowRight", "EditorIcons"]}
	var vars :Dictionary = DialogicUtil.get_project_setting('dialogic/variables', {})
	for var_path in list_variables(vars):
		suggestions[var_path] = {'value':var_path, 'editor_icon':["ClassList", "EditorIcons"]}
	return suggestions

func list_variables(dict:Dictionary, path := "") -> Array:
	var array := []
	for key in dict.keys():
		if typeof(dict[key]) == TYPE_DICTIONARY:
			array.append_array(list_variables(dict[key], path+key+"."))
		else:
			array.append(path+key)
	return array
