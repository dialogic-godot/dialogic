@tool
extends Node

enum Modes {TEXT_EVENT_ONLY, FULL_HIGHLIGHTING}

var syntax_highlighter :SyntaxHighlighter = load("res://addons/dialogic/Editor/TimelineEditor/TextEditor/syntax_highlighter.gd").new()
var text_syntax_highlighter :SyntaxHighlighter = load("res://addons/dialogic/Editor/TimelineEditor/TextEditor/syntax_highlighter.gd").new()


# These RegEx's are used to deduce information from the current line for auto-completion

# To find the currently typed word and the symbol before
var completion_word_regex := RegEx.new()
# To find the shortcode of the current shortcode event (basically the type)
var completion_shortcode_getter_regex := RegEx.new()
# To find the parameter name of the current if typing a value
var completion_shortcode_param_getter_regex := RegEx.new()

# Stores references to all shortcode events for parameter and value suggestions
var shortcode_events := {}
var custom_syntax_events := []
var text_event :DialogicTextEvent = null
 
func _ready():
	# Compile RegEx's
	completion_word_regex.compile("(?<s>(\\W)|^)(?<word>\\w*)\\x{FFFF}")
	completion_shortcode_getter_regex.compile("\\[(?<code>\\w*)")
	completion_shortcode_param_getter_regex.compile("(?<param>\\w*)\\W*=\\s*\"?(\\w|\\s)*"+String.chr(0xFFFF))
	
	text_syntax_highlighter.mode = text_syntax_highlighter.Modes.TEXT_EVENT_ONLY

################################################################################
## 					AUTO COMPLETION
################################################################################

# Helper that gets the current line with a special character where the caret is
func get_code_completion_line(text:CodeEdit) -> String:
	return text.get_line(text.get_caret_line()).insert(text.get_caret_column(), String.chr(0xFFFF)).strip_edges()


# Helper that gets the currently typed word
func get_code_completion_word(text:CodeEdit) -> String:
	var result := completion_word_regex.search(get_code_completion_line(text))
	return result.get_string('word') if result else ""


# Helper that gets the symbol before the current word
func get_code_completion_prev_symbol(text:CodeEdit) -> String:
	var result := completion_word_regex.search(get_code_completion_line(text))
	return result.get_string('s') if result else ""


func get_line_untill_caret(line:String) -> String:
	return line.substr(0, line.find(String.chr(0xFFFF)))


# Called if something was typed
# Adds all kinds of options depending on the 
#   content of the current line, the last word and the symbol that came before
# Triggers opening of the popup
func request_code_completion(force:bool, text:CodeEdit, mode:=Modes.FULL_HIGHLIGHTING) -> void:
	## TODO remove this once https://github.com/godotengine/godot/issues/38560 is fixed
	if mode != Modes.FULL_HIGHLIGHTING:
		return
	
	# make sure shortcode event references are loaded
	if mode == Modes.FULL_HIGHLIGHTING:
		var hidden_events :Array= DialogicUtil.get_editor_setting('hidden_event_buttons', [])
		if shortcode_events.is_empty():
			for event in text.timeline_editor.editors_manager.resource_helper.event_script_cache:
				if event.get_shortcode() != 'default_shortcode':
					shortcode_events[event.get_shortcode()] = event
					
				else:
					custom_syntax_events.append(event)
				if event.event_name in hidden_events:
					event.set_meta('hidden', true)
				if event is DialogicTextEvent:
					text_event = event
					# this is done to force-load the text effects regex which is used below
					event.load_text_effects()
	
	# fill helpers
	var line := get_code_completion_line(text)
	var word := get_code_completion_word(text)
	var symbol := get_code_completion_prev_symbol(text)
	
	
	## Note on use of KIND types for options. 
	# These types are mostly useless for us.
	# However I decidede to assign some special cases for them:
	# - KIND_PLAIN_TEXT is only shown if the beginnging of the option is already typed 
			# !word.is_empty() and option.begins_with(word)
	# - KIND_CLASS is only shown if anything from the options is already typed
			# !word.is_empty() and word in option
	# - KIND_CONSTANT is shown and checked against the beginning
			# option.begins_with(word)
	# - KIND_MEMBER is shown and searched completely 
			# word in option
	
	## Note on VALUE key
	# The value key is used to store a potential closing letter for the completion.
	# The completion will check if the letter is already present and add it otherwise.

	# Shortcode event suggestions
	if line.begins_with('[') and !text_event.text_effects_regex.search(line.get_slice(' ', 0)) and mode == Modes.FULL_HIGHLIGHTING:
		if symbol == '[':
			# suggest shortcodes if a shortcode event has just begun
			var shortcodes := shortcode_events.keys()
			shortcodes.sort()
			for shortcode in shortcodes:
				if shortcode_events[shortcode].get_meta('hidden', false):
					continue
				if shortcode_events[shortcode].get_shortcode_parameters().is_empty():
					text.add_code_completion_option(CodeEdit.KIND_MEMBER, shortcode, shortcode, shortcode_events[shortcode].event_color.lerp(syntax_highlighter.normal_color, 0.3), shortcode_events[shortcode]._get_icon())
				else:
					text.add_code_completion_option(CodeEdit.KIND_MEMBER, shortcode, shortcode+" ", shortcode_events[shortcode].event_color.lerp(syntax_highlighter.normal_color, 0.3), shortcode_events[shortcode]._get_icon())
		else:
			var current_shortcode := completion_shortcode_getter_regex.search(line)
			if !current_shortcode:
				text.update_code_completion_options(false)
				return
			
			var code := current_shortcode.get_string('code')
			if !code in shortcode_events.keys():
				text.update_code_completion_options(false)
				return
			
			# suggest parameters
			if symbol == ' ':
				var parameters :Array = shortcode_events[code].get_shortcode_parameters().keys()
				for param in parameters:
					if !param+'=' in line:
						text.add_code_completion_option(CodeEdit.KIND_MEMBER, param, param+'="' , shortcode_events[code].event_color.lerp(syntax_highlighter.normal_color, 0.3), text.get_theme_icon("MemberProperty", "EditorIcons"))
			
			# suggest values
			elif symbol == '=' or symbol == '"' or get_code_completion_prev_symbol(text) == '"':
				var current_parameter_gex := completion_shortcode_param_getter_regex.search(line)
				if !current_parameter_gex:
					text.update_code_completion_options(false)
					return
				
				var current_parameter := current_parameter_gex.get_string('param')
				if !shortcode_events[code].get_shortcode_parameters().has(current_parameter):
					text.update_code_completion_options(false)
					return
				if !shortcode_events[code].get_shortcode_parameters()[current_parameter].has('suggestions'):
					if typeof(shortcode_events[code].get_shortcode_parameters()[current_parameter].default) == TYPE_BOOL:
						suggest_bool(text, shortcode_events[code].event_color.lerp(syntax_highlighter.normal_color, 0.3))
					elif len(word) > 0:
						text.add_code_completion_option(CodeEdit.KIND_MEMBER, word, word, shortcode_events[code].event_color.lerp(syntax_highlighter.normal_color, 0.3), text.get_theme_icon("GuiScrollArrowRight", "EditorIcons"), '" ')
					text.update_code_completion_options(true)
					return
				
				var suggestions : Dictionary= shortcode_events[code].get_shortcode_parameters()[current_parameter]['suggestions'].call()
				for key in suggestions.keys():
					if suggestions[key].has('text_alt'):
						text.add_code_completion_option(CodeEdit.KIND_MEMBER, key, suggestions[key].text_alt[0], shortcode_events[code].event_color.lerp(syntax_highlighter.normal_color, 0.3), suggestions[key].get('icon', null), '" ')
					else:
						text.add_code_completion_option(CodeEdit.KIND_MEMBER, key, str(suggestions[key].value), shortcode_events[code].event_color.lerp(syntax_highlighter.normal_color, 0.3), suggestions[key].get('icon', null), '" ')

				
		# Force update and showing of the popup
		text.update_code_completion_options(true)
		return
	
	
	for event in custom_syntax_events:
		if mode == Modes.TEXT_EVENT_ONLY and !event is DialogicTextEvent:
			continue
		
		if ! ' ' in line:
			event._get_start_code_completion(self, text)
		
		if event.is_valid_event(line):
			event._get_code_completion(self, text, line, word, symbol)
			break
	
	# Force update and showing of the popup
	text.update_code_completion_options(true)



# Helper that adds all characters as options
func suggest_characters(text:CodeEdit, type := CodeEdit.KIND_MEMBER, text_event_start:=false) -> void:
	for character in text.timeline_editor.editors_manager.resource_helper.character_directory:
		var result :String = character
		if " " in character:
			result = '"'+character+'"'
		if text_event_start and text.timeline_editor.editors_manager.resource_helper.character_directory[character].resource.portraits.is_empty():
			result += ':'
		text.add_code_completion_option(type, character, result, syntax_highlighter.character_name_color, load("res://addons/dialogic/Editor/Images/Resources/character.svg"))


# Helper that adds all timelines as options
func suggest_timelines(text:CodeEdit, type := CodeEdit.KIND_MEMBER, color:=Color()) -> void:
	for timeline in text.timeline_editor.editors_manager.resource_helper.timeline_directory:
		text.add_code_completion_option(type, timeline, timeline+'/', color, text.get_theme_icon("TripleBar", "EditorIcons"))


func suggest_labels(text:CodeEdit, timeline:String='', end:='', color:=Color()) -> void:
	if timeline in Engine.get_main_loop().get_meta('dialogic_label_directory', {}):
		for i in Engine.get_main_loop().get_meta('dialogic_label_directory')[timeline]:
			text.add_code_completion_option(CodeEdit.KIND_MEMBER, i, i+end, color, load("res://addons/dialogic/Modules/Jump/icon_label.png"))


# Helper that adds all portraits of a given character as options
func suggest_portraits(text:CodeEdit, character_name:String, end_check:=')') -> void:
	if !character_name in text.timeline_editor.editors_manager.resource_helper.character_directory:
		return
	var character_resource :DialogicCharacter= text.timeline_editor.editors_manager.resource_helper.character_directory[character_name]['resource']
	for portrait in character_resource.portraits:
		text.add_code_completion_option(CodeEdit.KIND_MEMBER, portrait, portrait, syntax_highlighter.character_portrait_color, load("res://addons/dialogic/Editor/Images/Resources/character.svg"), end_check)
	if character_resource.portraits.is_empty():
		text.add_code_completion_option(CodeEdit.KIND_MEMBER, 'Has no portraits!', '', syntax_highlighter.character_portrait_color, load("res://addons/dialogic/Editor/Images/Pieces/warning.svg"))


# Helper that adds all variable paths as options
func suggest_variables(text:CodeEdit):
	for variable in DialogicUtil.list_variables(ProjectSettings.get_setting('dialogic/variables')):
		text.add_code_completion_option(CodeEdit.KIND_MEMBER, variable, variable, syntax_highlighter.variable_color, text.get_theme_icon("MemberProperty", "EditorIcons"), '}')


# Helper that adds true and false as options
func suggest_bool(text:CodeEdit, color:Color):
	text.add_code_completion_option(CodeEdit.KIND_MEMBER, 'true', 'true', color, text.get_theme_icon("GuiChecked", "EditorIcons"), '" ')
	text.add_code_completion_option(CodeEdit.KIND_MEMBER, 'false', 'false', color, text.get_theme_icon("GuiUnchecked", "EditorIcons"), '" ')


# Filters the list of all possible options, depending on what was typed
# Purpose of the different Kinds is explained in [_request_code_completion]
func filter_code_completion_candidates(candidates:Array, text:CodeEdit) -> Array:
	var valid_candidates := []
	var current_word := get_code_completion_word(text)
	for candidate in candidates:
		if candidate.kind == text.KIND_PLAIN_TEXT:
			if !current_word.is_empty() and candidate.insert_text.begins_with(current_word):
				valid_candidates.append(candidate)
		elif candidate.kind == text.KIND_MEMBER:
			if current_word.is_empty() or current_word.to_lower() in candidate.insert_text.to_lower():
				valid_candidates.append(candidate)
		elif candidate.kind == text.KIND_CONSTANT:
			if current_word.is_empty() or candidate.insert_text.begins_with(current_word):
				valid_candidates.append(candidate)
		elif candidate.kind == text.KIND_CLASS:
			if !current_word.is_empty() and current_word.to_lower() in candidate.insert_text.to_lower():
				valid_candidates.append(candidate)
	return valid_candidates


# Called when code completion was activated
# Inserts the selected item
func confirm_code_completion(replace:bool, text:CodeEdit) -> void:
	# Note: I decided to ALWAYS use replace mode, as dialogic is supposed to be beginner friendly 
	var word := get_code_completion_word(text)
	var code_completion := text.get_code_completion_option(text.get_code_completion_selected_index())
	text.remove_text(text.get_caret_line(), text.get_caret_column()-len(word), text.get_caret_line(), text.get_caret_column())
	text.set_caret_column(text.get_caret_column()-len(word))
	text.insert_text_at_caret(code_completion.insert_text)#
	if code_completion.has('default_value') and typeof(code_completion['default_value']) == TYPE_STRING:
		var next_letter := text.get_line(text.get_caret_line()).substr(text.get_caret_column(), 1)
		if next_letter != code_completion['default_value']:
			text.insert_text_at_caret(code_completion['default_value'])
		else:
			text.set_caret_column(text.get_caret_column()+1)


################################################################################
##					SYMBOL CLICKING
################################################################################

# Performs an action (like opening a link) when a valid symbol was clicked
func symbol_lookup(symbol:String, line:int, column:int) -> void:
	if symbol in shortcode_events.keys():
		if !shortcode_events[symbol].help_page_path.is_empty():
			OS.shell_open(shortcode_events[symbol].help_page_path)


# Called to test if a symbol can be clicked
func symbol_validate(symbol:String, text:CodeEdit) -> void:
	if symbol in shortcode_events.keys():
		if !shortcode_events[symbol].help_page_path.is_empty():
			text.set_symbol_lookup_word_as_valid(true)
