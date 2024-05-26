@tool
extends DialogicVisualEditorField

## Event block field for displaying conditions in either a simple or complex way.

var _current_value1 :Variant = ""
var _current_value2 :Variant = ""

#region MAIN METHODS
################################################################################

func _set_value(value:Variant) -> void:
	var too_complex := is_too_complex(value)
	%ToggleComplex.disabled = too_complex
	%ToggleComplex.button_pressed = too_complex
	%ComplexEditor.visible = too_complex
	%SimpleEditor.visible = !too_complex
	%ComplexEditor.text = value
	if not too_complex:
		load_simple_editor(value)



func _autofocus():
	%Value1Variable.grab_focus()

#endregion

func _ready() -> void:
	for i in [%Value1Type, %Value2Type]:
		i.options = [{
				'label': 'String',
				'icon': ["String", "EditorIcons"],
				'value': 0
			},{
				'label': 'Number',
				'icon': ["float", "EditorIcons"],
				'value': 1
			},{
				'label': 'Variable',
				'icon': load("res://addons/dialogic/Editor/Images/Pieces/variable.svg"),
				'value': 2
			},{
				'label': 'Bool',
				'icon': ["bool", "EditorIcons"],
				'value': 3
			},{
				'label': 'Expression',
				'icon': ["Variant", "EditorIcons"],
				'value': 4
			}]
		i.symbol_only = true
		i.value_changed.connect(value_type_changed.bind(i.name))
		i.value_changed.connect(something_changed)
		i.tooltip_text = "Change type"


	for i in [%Value1Variable, %Value2Variable]:
		i.get_suggestions_func = get_variable_suggestions
		i.value_changed.connect(something_changed)

	%Value1Number.value_changed.connect(something_changed)
	%Value2Number.value_changed.connect(something_changed)
	%Value1Text.value_changed.connect(something_changed)
	%Value2Text.value_changed.connect(something_changed)
	%Value1Bool.value_changed.connect(something_changed)
	%Value2Bool.value_changed.connect(something_changed)

	%ToggleComplex.icon = get_theme_icon("Enum", "EditorIcons")

	%Operator.value_changed.connect(something_changed)
	%Operator.options = [
		{'label': '==', 'value': '=='},
		{'label': '>', 	'value': '>'},
		{'label': '<',	'value': '<'},
		{'label': '<=',	'value': '<='},
		{'label': '>=', 'value': '>='},
		{'label': '!=', 'value': '!='}
	]


func load_simple_editor(condition_string:String) -> void:
	var data := complex2simple(condition_string)
	%Value1Type.set_value(get_value_type(data[0], 2))
	_current_value1 = data[0]
	value_type_changed('', get_value_type(data[0], 2), 'Value1')
	%Operator.set_value(data[1].strip_edges())
	%Value2Type.set_value(get_value_type(data[2], 0))
	_current_value2 = data[2]
	value_type_changed('', get_value_type(data[2], 0), 'Value2')


func value_type_changed(property:String, value_type:int, value_name:String) -> void:
	value_name = value_name.trim_suffix('Type')
	get_node('%'+value_name+'Variable').hide()
	get_node('%'+value_name+'Text').hide()
	get_node('%'+value_name+'Number').hide()
	get_node('%'+value_name+'Bool').hide()
	var current_val :Variant = ""
	if '1' in value_name:
		current_val = _current_value1
	else:
		current_val = _current_value2
	match value_type:
		0:
			get_node('%'+value_name+'Text').show()
			get_node('%'+value_name+'Text').set_value(trim_value(current_val, value_type))
		1:
			get_node('%'+value_name+'Number').show()
			get_node('%'+value_name+'Number').set_value(float(current_val.strip_edges()))
		2:
			get_node('%'+value_name+'Variable').show()
			get_node('%'+value_name+'Variable').set_value(trim_value(current_val, value_type))
		3:
			get_node('%'+value_name+'Bool').show()
			get_node('%'+value_name+'Bool').set_value(trim_value(current_val, value_type))
		4:
			get_node('%'+value_name+'Text').show()
			get_node('%'+value_name+'Text').set_value(str(current_val))


func get_value_type(value:String, default:int) -> int:
	value = value.strip_edges()
	if value.begins_with('"') and value.ends_with('"') and value.count('"')-value.count('\\"') == 2:
		return 0
	elif value.begins_with('{') and value.ends_with('}') and value.count('{') == 1:
		return 2
	elif value == "true" or value == "false":
		return 3
	else:
		if value.is_empty():
			return default
		if value.is_valid_float():
			return 1
		else:
			return 4


func prep_value(value:Variant, value_type:int) -> String:
	if value != null: value = str(value)
	else: value = ""
	value = value.strip_edges()
	match value_type:
		0: return '"'+value.replace('"', '\\"')+'"'
		2: return '{'+value+'}'
		_: return value


func trim_value(value:Variant, value_type:int) -> String:
	value = value.strip_edges()
	match value_type:
		0: return value.trim_prefix('"').trim_suffix('"').replace('\\"', '"')
		2: return value.trim_prefix('{').trim_suffix('}')
		3:
			if value == "true" or (value and (typeof(value) != TYPE_STRING or value != "false")):
				return "true"
			else:
				return "false"
		_: return value


func something_changed(fake_arg1=null, fake_arg2 = null):
	if %ComplexEditor.visible:
		value_changed.emit(property_name, %ComplexEditor.text)
		return


	match %Value1Type.current_value:
		0: _current_value1 = prep_value(%Value1Text.text, %Value1Type.current_value)
		1: _current_value1 = str(%Value1Number.get_value())
		2: _current_value1 = prep_value(%Value1Variable.current_value, %Value1Type.current_value)
		3: _current_value1 = prep_value(%Value1Bool.button_pressed, %Value1Type.current_value)
		_: _current_value1 = prep_value(%Value1Text.text, %Value1Type.current_value)

	match %Value2Type.current_value:
		0: _current_value2 = prep_value(%Value2Text.text, %Value2Type.current_value)
		1: _current_value2 = str(%Value2Number.get_value())
		2: _current_value2 = prep_value(%Value2Variable.current_value, %Value2Type.current_value)
		3: _current_value2 = prep_value(%Value2Bool.button_pressed, %Value2Type.current_value)
		_: _current_value2 = prep_value(%Value2Text.text, %Value2Type.current_value)

	if event_resource:
		if not %Operator.text in ['==', '!='] and get_value_type(_current_value2, 0) in [0, 3]:
			event_resource.ui_update_warning.emit("This operator doesn't work with strings and booleans.")
		else:
			event_resource.ui_update_warning.emit("")

	value_changed.emit(property_name, get_simple_condition())


func is_too_complex(condition:String) -> bool:
	if condition.strip_edges().is_empty():
		return false

	var comparison_count: int = 0
	for i in ['==', '!=', '<=', '<', '>', '>=']:
		comparison_count += condition.count(i)
	if comparison_count == 1:
		return false

	return true


## Combines the info from the simple editor fields into a string condition
func get_simple_condition() -> String:
	return _current_value1 +" "+ %Operator.text +" "+ _current_value2


func complex2simple(condition:String) -> Array:
	if is_too_complex(condition) or condition.strip_edges().is_empty():
		return ['', '==','']

	for i in ['==', '!=', '<=', '<', '>', '>=']:
		if i in condition:
			var cond_split := Array(condition.split(i, false))
			return [cond_split[0], i, cond_split[1]]

	return ['', '==','']


func _on_toggle_complex_toggled(button_pressed:bool) -> void:
	if button_pressed:
		%ComplexEditor.show()
		%SimpleEditor.hide()
		%ComplexEditor.text = get_simple_condition()
	else:
		if !is_too_complex(%ComplexEditor.text):
			%ComplexEditor.hide()
			%SimpleEditor.show()
			load_simple_editor(%ComplexEditor.text)


func _on_complex_editor_text_changed(new_text:String) -> void:
	%ToggleComplex.disabled = is_too_complex(%ComplexEditor.text)
	something_changed()


func get_variable_suggestions(filter:String) -> Dictionary:
	var suggestions := {}
	var vars :Dictionary= ProjectSettings.get_setting('dialogic/variables', {})
	for var_path in DialogicUtil.list_variables(vars):
		suggestions[var_path] = {'value':var_path, 'editor_icon':["ClassList", "EditorIcons"]}
	return suggestions


func _on_value_1_variable_value_changed(property_name: Variant, value: Variant) -> void:
	var type := DialogicUtil.get_variable_type(value)
	match type:
		DialogicUtil.VarTypes.BOOL:
			if not %Operator.text in ["==", "!="]:
				%Operator.text = "=="
			if get_value_type(_current_value2, 3) in [0, 1]:
				%Value2Type.insert_options()
				%Value2Type.index_pressed(3)
		DialogicUtil.VarTypes.STRING:
			if not %Operator.text in ["==", "!="]:
				%Operator.text = "=="
			if get_value_type(_current_value2, 0) in [1, 3]:
				%Value2Type.insert_options()
				%Value2Type.index_pressed(0)
		DialogicUtil.VarTypes.FLOAT, DialogicUtil.VarTypes.INT:
			if get_value_type(_current_value2, 1) in [0,3]:
				%Value2Type.insert_options()
				%Value2Type.index_pressed(1)

	something_changed()

