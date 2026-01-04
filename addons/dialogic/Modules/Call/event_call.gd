@tool
class_name DialogicCallEvent
extends DialogicEvent

## Event that allows calling a method in a node or autoload.

### Settings

## The name of the autoload to call the method on.
var autoload_name := ""
## The name of the method to call on the given autoload.
var method := "":
	set(value):
		method = value
		if Engine.is_editor_hint():
			update_argument_info()
			check_arguments_and_update_warning()
## A list of arguments to give to the call.
var arguments := []:
	set(value):
		arguments = value
		if Engine.is_editor_hint():
			check_arguments_and_update_warning()

var _current_method_arg_hints := {'a':null, 'm':null, 'info':{}}


#region EXECUTION
################################################################################

func _execute() -> void:
	var object: Object = null
	var obj_path := autoload_name
	var autoload: Node = dialogic.get_node('/root/'+obj_path.get_slice('.', 0))
	obj_path = obj_path.trim_prefix(obj_path.get_slice('.', 0)+'.')
	object = autoload
	if object:
		while obj_path:
			if obj_path.get_slice(".", 0) in object and object.get(obj_path.get_slice(".", 0)) is Object:
				object = object.get(obj_path.get_slice(".", 0))
			else:
				break
			obj_path = obj_path.trim_prefix(obj_path.get_slice('.', 0)+'.')

	if object == null:
		printerr("[Dialogic] Call event failed: Unable to find autoload '",autoload_name,"'")
		finish()
		return

	if object.has_method(method):
		var args := []
		for arg in arguments:
			if arg is String and arg.begins_with('@'):
				args.append(dialogic.Expressions.execute_string(arg.trim_prefix('@')))
			else:
				args.append(arg)
		dialogic.current_state = dialogic.States.WAITING
		await object.callv(method, args)
		dialogic.current_state = dialogic.States.IDLE
	else:
		printerr("[Dialogic] Call event failed: Autoload doesn't have the method '", method,"'.")

	finish()

#endregion


#region INITIALIZE
################################################################################

func _init() -> void:
	event_name = "Call"
	event_description = "Calls a method on an autoload script or scene."
	set_default_color('Color6')
	event_category = "Logic"
	event_sorting_index = 10

#endregion


#region SAVING/LOADING
################################################################################

func to_text() -> String:
	var result := "do "
	if autoload_name:
		result += autoload_name
		if method:
			result += '.'+method
			if arguments.is_empty():
				result += '()'
			else:
				result += '('
				for i in arguments:
					if i is String and i.begins_with('@'):
						result += i.trim_prefix('@')
					else:
						result += var_to_str(i)
					result += ', '
				result = result.trim_suffix(', ')+')'
	return result


func from_text(string:String) -> void:
	var result := RegEx.create_from_string(r"do (?<autoload>[^\(]*)\.((?<method>[^.(]*)(\((?<arguments>.*)\))?)?").search(string.strip_edges())
	if result:
		autoload_name = result.get_string('autoload')
		method = result.get_string('method')
		if result.get_string('arguments').is_empty():
			arguments = []
		else:
			var arr := []
			for i in result.get_string('arguments').split(','):
				i = i.strip_edges()
				if str_to_var(i) != null:
					arr.append(str_to_var(i))
				else:
					# Mark this as a complex expression
					arr.append("@"+i)
			arguments = arr


func is_valid_event(string:String) -> bool:
	if string.strip_edges().begins_with("do"):
		return true
	return false


func get_shortcode_parameters() -> Dictionary:
	return {
		#param_name : property_info
		"autoload" 	: {"property": "autoload_name", 	"default": ""},
		"method" 	: {"property": "method", 			"default": ""},
		"args" 		: {"property": "arguments", 		"default": []},
	}

#endregion


#region EDITOR REPRESENTATION
################################################################################

func build_event_editor() -> void:
	add_header_edit('autoload_name', ValueType.DYNAMIC_OPTIONS, {'left_text':'On autoload',
		'empty_text':'Autoload',
		'suggestions_func': DialogicUtil.get_autoload_suggestions,
		'editor_icon':["Node", "EditorIcons"]})
	add_header_edit('method', ValueType.DYNAMIC_OPTIONS, {'left_text':'call',
		'empty_text':'Method',
		'suggestions_func': get_method_suggestions,
		'editor_icon':["Callable", "EditorIcons"]}, 'autoload_name')
	add_body_edit('arguments', ValueType.ARRAY, {'left_text':'Arguments:'}, 'not autoload_name.is_empty() and not method.is_empty()')


func get_method_suggestions(filter:="") -> Dictionary:
	return DialogicUtil.get_autoload_method_suggestions(filter, autoload_name)


func update_argument_info() -> void:
	if autoload_name and method and not _current_method_arg_hints.is_empty() and (_current_method_arg_hints.a == autoload_name and _current_method_arg_hints.m == method):
		if !ResourceLoader.exists(ProjectSettings.get_setting('autoload/'+autoload_name, '').trim_prefix('*')):
			_current_method_arg_hints = {}
			return
		var script: Script = load(ProjectSettings.get_setting('autoload/'+autoload_name, '').trim_prefix('*'))
		for m in script.get_script_method_list():
			if m.name == method:
				_current_method_arg_hints = {'a':autoload_name, 'm':method, 'info':m}
				break


func check_arguments_and_update_warning() -> void:
	if not _current_method_arg_hints.has("info") or _current_method_arg_hints.info.is_empty():
		ui_update_warning.emit()
		return

	var idx := -1
	for arg in arguments:
		idx += 1
		if len(_current_method_arg_hints.info.args) <= idx:
			continue
		if _current_method_arg_hints.info.args[idx].type != 0:
			if _current_method_arg_hints.info.args[idx].type != typeof(arg):
				if arg is String and arg.begins_with('@'):
					continue
				var expected_type: String = ""
				match _current_method_arg_hints.info.args[idx].type:
					TYPE_BOOL: 		expected_type = "bool"
					TYPE_STRING: 	expected_type = "string"
					TYPE_FLOAT: 	expected_type = "float"
					TYPE_INT: 		expected_type = "int"
					_: 				expected_type = "something else"

				ui_update_warning.emit('Argument '+ str(idx+1)+ ' ('+_current_method_arg_hints.info.args[idx].name+') has the wrong type (method expects '+expected_type+')!')
				return

	if len(arguments) < len(_current_method_arg_hints.info.args)-len(_current_method_arg_hints.info.default_args):
		ui_update_warning.emit("The method is expecting at least "+str(len(_current_method_arg_hints.info.args)-len(_current_method_arg_hints.info.default_args))+ " arguments, but is given only "+str(len(arguments))+".")
		return
	elif len(arguments) > len(_current_method_arg_hints.info.args):
		ui_update_warning.emit("The method is expecting at most "+str(len(_current_method_arg_hints.info.args))+ " arguments, but is given "+str(len(arguments))+".")
		return
	ui_update_warning.emit()

#endregion


#region CODE COMPLETION
################################################################################

func _get_code_completion(CodeCompletionHelper:Node, TextNode:TextEdit, line:String, _word:String, symbol:String) -> void:
	var autoloads := DialogicUtil.get_autoload_suggestions()
	var line_until_caret: String = CodeCompletionHelper.get_line_untill_caret(line)

	if line.count(' ') == 1 and not '.' in line:
		for i in autoloads:
			TextNode.add_code_completion_option(CodeEdit.KIND_MEMBER, i, i+'.', event_color.lerp(TextNode.syntax_highlighter.normal_color, 0.3), TextNode.get_theme_icon("Node", "EditorIcons"))

	elif (line_until_caret.ends_with(".") or symbol == "."):
		var some_autoload := line_until_caret.split(" ")[-1].split(".")[0]
		if some_autoload in autoloads:
			var methods := DialogicUtil.get_autoload_method_suggestions("", some_autoload)
			for i in methods.keys():
				TextNode.add_code_completion_option(CodeEdit.KIND_MEMBER, i, i+'(', event_color.lerp(TextNode.syntax_highlighter.normal_color, 0.3), TextNode.get_theme_icon("MemberMethod", "EditorIcons"))



func _get_start_code_completion(_CodeCompletionHelper:Node, TextNode:TextEdit) -> void:
	TextNode.add_code_completion_option(CodeEdit.KIND_PLAIN_TEXT, 'do', 'do ', event_color.lerp(TextNode.syntax_highlighter.normal_color, 0.3), _get_icon())

#endregion


#region SYNTAX HIGHLIGHTING
################################################################################

func _get_syntax_highlighting(Highlighter:SyntaxHighlighter, dict:Dictionary, line:String) -> Dictionary:
	dict[line.find('do')] = {"color":event_color.lerp(Highlighter.normal_color, 0.3)}
	dict[line.find('do')+2] = {"color":event_color.lerp(Highlighter.normal_color, 0.5)}

	Highlighter.color_region(dict, Highlighter.normal_color, line, '(', ')')
	Highlighter.color_region(dict, Highlighter.string_color, line, '"', '"')
	Highlighter.color_word(dict, Highlighter.boolean_operator_color, line, 'true')
	Highlighter.color_word(dict, Highlighter.boolean_operator_color, line, 'false')
	return dict

#endregion
