@tool
extends SyntaxHighlighter

## Syntax highlighter for the dialogic text timeline editor and text events in the visual editor.

enum Modes {TEXT_EVENT_ONLY, FULL_HIGHLIGHTING}
var mode := Modes.FULL_HIGHLIGHTING


## RegEx's
var word_regex := RegEx.new()
var region_regex := RegEx.new()
var number_regex := RegEx.create_from_string("(\\d|\\.)+")
var shortcode_regex := RegEx.create_from_string("\\W*\\[(?<id>\\w*)(?<args>[^\\]]*)?")
var shortcode_param_regex := RegEx.create_from_string('((?<parameter>[^\\s=]*)\\s*=\\s*"(?<value>([^=]|\\\\=)*)(?<!\\\\)")')

## Colors
var normal_color : Color
var translation_id_color: Color

var code_flow_color : Color
var boolean_operator_color : Color
var variable_color : Color
var string_color : Color
var character_name_color : Color
var character_portrait_color : Color

var shortcode_events := {}
var custom_syntax_events := []
var text_event :DialogicTextEvent = null


func _init():
	# Load colors from editor settings
	if DialogicUtil.get_dialogic_plugin():
		var editor_settings = DialogicUtil.get_dialogic_plugin().get_editor_interface().get_editor_settings()
		normal_color = editor_settings.get('text_editor/theme/highlighting/text_color')
		translation_id_color = editor_settings.get('text_editor/theme/highlighting/comment_color')

		code_flow_color = editor_settings.get("text_editor/theme/highlighting/control_flow_keyword_color")
		boolean_operator_color = code_flow_color.lightened(0.5)
		variable_color = editor_settings.get('text_editor/theme/highlighting/engine_type_color')
		string_color = editor_settings.get('text_editor/theme/highlighting/string_color')
		character_name_color = editor_settings.get('text_editor/theme/highlighting/symbol_color').lerp(normal_color, 0.3)
		character_portrait_color = character_name_color.lerp(normal_color, 0.5)


func _get_line_syntax_highlighting(line:int) -> Dictionary:
	var str_line := get_text_edit().get_line(line)

	if shortcode_events.is_empty():
		for event in DialogicResourceUtil.get_event_cache():
			if event.get_shortcode() != 'default_shortcode':
				shortcode_events[event.get_shortcode()] = event
			else:
				custom_syntax_events.append(event)
			if event is DialogicTextEvent:
				text_event = event
				text_event.load_text_effects()

	var dict := {}
	dict[0] = {'color':normal_color}

	dict = color_translation_id(dict, str_line)

	if mode == Modes.FULL_HIGHLIGHTING:
		if str_line.strip_edges().begins_with("[") and !text_event.text_effects_regex.search(str_line.get_slice(' ', 0)):
			var result:= shortcode_regex.search(str_line)
			if result:
				if result.get_string('id') in shortcode_events:
					dict[result.get_start('id')] = {"color":shortcode_events[result.get_string('id')].event_color.lerp(normal_color, 0.4)}
					dict[result.get_end('id')] = {"color":normal_color}

					if result.get_string('args'):
						color_shortcode_content(dict, str_line, result.get_start('args'), result.get_end('args'), shortcode_events[result.get_string('id')].event_color)
			return fix_dict(dict)

		else:
			for event in custom_syntax_events:
				if event.is_valid_event(str_line.strip_edges()):
					dict = event._get_syntax_highlighting(self, dict, str_line)
					return fix_dict(dict)

	else:
		dict = text_event._get_syntax_highlighting(self, dict, str_line)
	return fix_dict(dict)


func fix_dict(dict:Dictionary) -> Dictionary:
	var d := {}
	var k := dict.keys()
	k.sort()
	for i in k:
		d[i] = dict[i]
	return d


func color_condition(dict:Dictionary, line:String, from:int = 0, to:int = 0) -> Dictionary:
	dict = color_word(dict, code_flow_color, line, 'or',  from, to)
	dict = color_word(dict, code_flow_color, line, 'and', from, to)
	dict = color_word(dict, code_flow_color, line, '==',  from, to)
	dict = color_word(dict, code_flow_color, line, '!=',  from, to)
	if !">=" in line:
		dict = color_word(dict, code_flow_color, line, '>',   from, to)
	else:
		dict = color_word(dict, code_flow_color, line, '>=',  from, to)
	if !"<=" in line:
		dict = color_word(dict, code_flow_color, line, '<',   from, to)
	else:
		dict = color_word(dict, code_flow_color, line, '<=',  from, to)
	dict = color_region(dict, variable_color, line, '{', '}', from, to)
	dict = color_region(dict, string_color, line, '"', '"', from, to)


	return dict


func color_translation_id(dict:Dictionary, line:String) -> Dictionary:
	dict = color_region(dict, translation_id_color, line, '#id:', '')
	return dict


func color_word(dict:Dictionary, color:Color, line:String, word:String, from:int= 0, to:int = 0) -> Dictionary:
	word_regex.compile("\\W(?<word>"+word+")\\W")
	if to <= from:
		to = len(line)-1
	for i in word_regex.search_all(line.substr(from, to-from+2)):
		dict[i.get_start('word')+from] = {'color':color}
		dict[i.get_end('word')+from] = {'color':normal_color}
	return dict


func color_region(dict:Dictionary, color:Color, line:String, start:String, end:String, from:int = 0, to:int = 0, base_color:Color=normal_color) -> Dictionary:
	if start in "()[].":
		start = "\\"+start
	if end in "()[].":
		end = "\\"+end

	if end.is_empty():
		region_regex.compile("(?<!\\\\)"+start+".*")
	else:
		region_regex.compile("(?<!\\\\)"+start+"(.(?!"+end+"))*."+end)
	if to <= from:
		to = len(line)-1
	for region in region_regex.search_all(line.substr(from, to-from+2)):
		dict[region.get_start()+from] = {'color':color}
		dict[region.get_end()+from] = {'color':base_color}
	return dict


func color_shortcode_content(dict:Dictionary, line:String, from:int = 0, to:int = 0, base_color:=normal_color) -> Dictionary:
	if to <= from:
		to = len(line)-1
	var args_result:= shortcode_param_regex.search_all(line.substr(from, to-from+2))
	for x in args_result:
		dict[x.get_start()+from] = {"color":base_color.lerp(normal_color, 0.5)}
		dict[x.get_start('value')+from-1] = {"color":base_color.lerp(normal_color, 0.7)}
		dict[x.get_end()+from] = {"color":normal_color}
	return dict
