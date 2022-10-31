@tool
extends Control

var property_name : String
signal value_changed

func _ready():
	%ComplexEditor.add_theme_stylebox_override('normal', get_theme_stylebox('normal', 'LineEdit'))
	%ComplexEditor.add_theme_stylebox_override('focus', get_theme_stylebox('focus', 'LineEdit'))
	
	%Operator.options = [
		{
			'label': '==',
			'value': '=='
		}, 
		{
			'label': '>',
			'value': '>'
		}, 
		{
			'label': '<',
			'value': '<'
		}, 
		{
			'label': '<=',
			'value': '<='
		}, 
		{
			'label': '>=',
			'value': '>='
		}, 
		{
			'label': '!=',
			'value': '!='
		}
	]
	%ToggleComplex.icon = get_theme_icon("Enum", "EditorIcons")
	
	%Value1.resource_icon = get_theme_icon("ClassList", "EditorIcons")
	%Value1.get_suggestions_func = get_value1_suggestions
	%Value1.value_changed.connect(something_changed)
	%Operator.value_changed.connect(something_changed)
	
	%Value2.resource_icon = get_theme_icon("Variant", "EditorIcons")
	%Value2.get_suggestions_func = get_value2_suggestions
	%Value2.value_changed.connect(something_changed)

func set_right_text(value:String):
	$RightText.text = str(value)
	$RightText.visible = !value.is_empty()

func set_left_text(value:String):
	$LeftText.text = str(value)
	$LeftText.visible = !value.is_empty()

func set_value(value:String):
	var too_complex = is_too_complex(value)
	%ToggleComplex.disabled = too_complex
	%ToggleComplex.button_pressed = too_complex
	%ComplexEditor.visible = too_complex
	%SimpleEditor.visible = !too_complex
	%ComplexEditor.text = value
	if not too_complex:
		var data = complex2simple(value)
		%Value1.set_value(data[0], data[0].trim_prefix("{").trim_suffix('}'))
		%Operator.set_value(data[1].strip_edges())
		%Value2.set_value(data[2], data[2].trim_prefix("{").trim_suffix('}'))

func something_changed(fake_arg1=null, fake_arg2 = null):
	if %ComplexEditor.visible:
		value_changed.emit(property_name, %ComplexEditor.text)
	elif %SimpleEditor.visible:
		value_changed.emit(property_name, simple2complex(%Value1.current_value, %Operator.get_value(), %Value2.current_value))

func is_too_complex(condition:String) -> bool:
	return !condition.is_empty() and len(condition.split(' ', false)) != 3

func complex2simple(condition:String) -> Array:
	if is_too_complex(condition) or condition.strip_edges().is_empty():
		return ['', '==','']
	var cond_split = Array(condition.split(' ', false))
	if cond_split[2].begins_with('"'): cond_split[2] = cond_split[2].trim_prefix('"').trim_suffix('"')
	return cond_split

func simple2complex(value1, operator, value2) -> String:
	if value1 == null: value1 = ''
	if value1.is_empty():
		return ''
	if value2 == null: value2 = ''
	if !value2.is_valid_float() and !value2.begins_with('{'):
		value2 = '"'+value2+'"'
	return value1 +" "+ operator +" "+ value2

func _on_toggle_complex_toggled(button_pressed) -> void:
	if button_pressed:
		%ComplexEditor.show()
		%SimpleEditor.hide()
		%ComplexEditor.text = simple2complex(%Value1.current_value, %Operator.get_value(), %Value2.current_value)
	else:
		if !is_too_complex(%ComplexEditor.text):
			%ComplexEditor.hide()
			%SimpleEditor.show()
			var data = complex2simple(%ComplexEditor.text)
			%Value1.set_value(data[0], data[0].trim_prefix("{").trim_suffix('}'))
			%Operator.set_value(data[1].strip_edges())
			%Value2.set_value(data[2], data[2].trim_prefix("{").trim_suffix('}'))

func _on_complex_editor_text_changed(new_text):
	%ToggleComplex.disabled = is_too_complex(%ComplexEditor.text)
	something_changed()

func get_value1_suggestions(filter:String) -> Dictionary:
	var suggestions = {}
	if filter:
		suggestions[filter] = {'value':filter, 'editor_icon':["GuiScrollArrowRight", "EditorIcons"]}
	var vars = DialogicUtil.get_project_setting('dialogic/variables', {})
	for var_path in list_variables(vars):
		suggestions[var_path] = {'value':'{'+var_path+"}", 'editor_icon':["ClassList", "EditorIcons"]}
	return suggestions

func list_variables(dict, path = "") -> Array:
	var array = []
	for key in dict.keys():
		if typeof(dict[key]) == TYPE_DICTIONARY:
			array.append_array(list_variables(dict[key], path+key+"."))
		else:
			array.append(path+key)
	return array

func get_value2_suggestions(filter:String) -> Dictionary:
	var suggestions = {}
	if filter:
		suggestions[filter] = {'value':filter, 'editor_icon':["GuiScrollArrowRight", "EditorIcons"]}
	var vars = DialogicUtil.get_project_setting('dialogic/variables', {})
	for var_path in list_variables(vars):
		suggestions[var_path] = {'value':'{'+var_path+"}", 'editor_icon':["ClassList", "EditorIcons"]}
	return suggestions
