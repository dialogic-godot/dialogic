@tool
extends Node

enum Modes {TextEventOnly, FullHighlighting}
@export var mode := Modes.FullHighlighting

# These RegEx's are used to deduce information from the current line for auto-completion
# E.g. the character for portrait suggestions or the event type for parameter suggestions

# To find the currently typed word and the symbol before
var completion_word_regex := RegEx.new()
# To find the shortcode of the current shortcode event (basically the type)
var completion_shortcode_getter_regex := RegEx.new()
# To find the parameter name of the current if typing a value
var completion_shortcode_param_getter_regex := RegEx.new()
# To find the character from a character event (for portrait suggestions)
var completion_character_getter_regex := RegEx.new()
# To find the character from a text event (for portrait suggestions)
var completion_text_character_getter_regex := RegEx.new()

# Stores references to all shortcode events for parameter and value suggestions
var completion_shortcodes := {}
var completion_text_effects := {}
 
func _ready():
	# Compile RegEx's
	completion_word_regex.compile("(?<s>(\\W)|^)(?<word>\\w*)\\x{FFFF}")
	completion_shortcode_getter_regex.compile("\\[(?<code>\\w*)")
	completion_character_getter_regex.compile("(?<type>Join|Update|Leave)\\s*(\")?(?<name>(?(2)[^\"\\n]*|[^(: \\n]*))(?(2)\"|)(\\W*\\((?<portrait>.*)\\))?(\\s*(?<position>\\d))?(\\s*\\[(?<shortcode>.*)\\])?")
	completion_text_character_getter_regex.compile("\\W*(\")?(?<name>(?(2)[^\"\\n]*|[^(: \\n]*))(?(1)\"|)")
	completion_shortcode_param_getter_regex.compile("(?<param>\\w*)\\W*=\\s*\"?"+String.chr(0xFFFF))

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


# Called if something was typed
# Adds all kinds of options depending on the 
#   content of the current line, the last word and the symbol that came before
# Triggers opening of the popup
func request_code_completion(force:bool, text:CodeEdit):
	# make sure shortcode event references are loaded
	if mode == Modes.FullHighlighting:
		if completion_shortcodes.is_empty():
			for event in text.get_parent().editors_manager.resource_helper.event_script_cache:
				if event.get_shortcode() != 'default_shortcode':
					completion_shortcodes[event.get_shortcode()] = event
	if completion_text_effects.is_empty():
		for idx in DialogicUtil.get_indexers():
			for effect in idx._get_text_effects():
				completion_text_effects[effect['command']] = effect
	
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
	
	if mode == Modes.FullHighlighting:
		# Shortcode event suggestions
		if line.begins_with('['):
			if symbol == '[':
				# suggest shortcodes if a shortcode event has just begun
				for shortcode in completion_shortcodes.keys():
					if completion_shortcodes[shortcode].get_shortcode_parameters().is_empty():
						text.add_code_completion_option(CodeEdit.KIND_MEMBER, shortcode, shortcode, completion_shortcodes[shortcode].event_color, completion_shortcodes[shortcode]._get_icon())
					else:
						text.add_code_completion_option(CodeEdit.KIND_MEMBER, shortcode, shortcode+" ", completion_shortcodes[shortcode].event_color, completion_shortcodes[shortcode]._get_icon())
			else:
				# suggest either parameters or values
				var current_shortcode := completion_shortcode_getter_regex.search(line)
				if current_shortcode:
					var code := current_shortcode.get_string('code')
					if code in completion_shortcodes.keys():
						if symbol == ' ':
							for param in completion_shortcodes[code].get_shortcode_parameters().keys():
								text.add_code_completion_option(CodeEdit.KIND_MEMBER, param, param+'="' , text.syntax_highlighter.shortcode_param_color)
						elif symbol == '=' or symbol == '"':
							var current_parameter_gex := completion_shortcode_param_getter_regex.search(line)
							if current_parameter_gex: 
								var current_parameter := current_parameter_gex.get_string('param')
								if completion_shortcodes[code].get_shortcode_parameters().has(current_parameter):
									if completion_shortcodes[code].get_shortcode_parameters()[current_parameter].has('suggestions'):
										var suggestions : Dictionary= completion_shortcodes[code].get_shortcode_parameters()[current_parameter]['suggestions'].call()
										for key in suggestions.keys():
											text.add_code_completion_option(CodeEdit.KIND_MEMBER, key, suggestions[key].value, text.syntax_highlighter.shortcode_value_color, suggestions[key].get('icon', null), '"')

		# Condition event suggestions
		elif line.begins_with('if') or line.begins_with('elif'):
			if symbol == '{':
				suggest_variables(text)

		# Choice Event suggestions
		elif line.begins_with('-') and '[' in line:
			if symbol == '[':
				text.add_code_completion_option(CodeEdit.KIND_MEMBER, 'if', 'if ', text.syntax_highlighter.code_flow_color)
			elif symbol == '{':
				suggest_variables(text)

		# Character Event suggestions
		elif line.begins_with('Join') or line.begins_with('Leave') or line.begins_with('Update'):
			if symbol == ' ' and line.count(' ') <= max(line.count('"'), 1):
				suggest_characters(text)
				if line.begins_with('Leave'):
					text.add_code_completion_option(CodeEdit.KIND_MEMBER, 'All', '--All-- ', text.syntax_highlighter.character_name_color, text.get_theme_icon("GuiEllipsis", "EditorIcons"))
			
			if symbol == '(':
				var character:= completion_character_getter_regex.search(line).get_string('name')
				suggest_portraits(text, character)

		# Start of line suggestions
		# These are all as KIND_PLAIN_TEXT, because that means they won't 
		# be suggested unless at least the first letter is typed in.
		elif not ' ' in line:
			text.add_code_completion_option(CodeEdit.KIND_PLAIN_TEXT, 'Join', 'Join ', text.syntax_highlighter.character_event_color, load('res://addons/dialogic/Editor/Images/Dropdown/join.svg'))
			text.add_code_completion_option(CodeEdit.KIND_PLAIN_TEXT, 'Leave', 'Leave ', text.syntax_highlighter.character_event_color, load('res://addons/dialogic/Editor/Images/Dropdown/leave.svg'))
			text.add_code_completion_option(CodeEdit.KIND_PLAIN_TEXT, 'Update', 'Update ', text.syntax_highlighter.character_event_color, load('res://addons/dialogic/Editor/Images/Dropdown/update.svg'))
			
			text.add_code_completion_option(CodeEdit.KIND_PLAIN_TEXT, 'if', 'if ', text.syntax_highlighter.code_flow_color)
			text.add_code_completion_option(CodeEdit.KIND_PLAIN_TEXT, 'elif', 'elif ', text.syntax_highlighter.code_flow_color)
			text.add_code_completion_option(CodeEdit.KIND_PLAIN_TEXT, 'else', 'else:', text.syntax_highlighter.code_flow_color)
			
			text.add_code_completion_option(CodeEdit.KIND_PLAIN_TEXT, 'VAR', 'VAR ', text.syntax_highlighter.keyword_VAR_color)
			text.add_code_completion_option(CodeEdit.KIND_PLAIN_TEXT, 'Setting', 'Setting ', text.syntax_highlighter.keyword_SETTING_color)
			
			suggest_characters(text, CodeEdit.KIND_CLASS)

	# Text Event Suggestions
	if not ':' in line.substr(0, text.get_caret_column()) and symbol == '(':
		var character := completion_text_character_getter_regex.search(line).get_string('name')
		suggest_portraits(text, character)
	if symbol == '[':
		suggest_bbcode(text)
		for effect in completion_text_effects:
			text.add_code_completion_option(CodeEdit.KIND_MEMBER, effect, effect, text.syntax_highlighter.normal_color, text.get_theme_icon("RichTextEffect", "EditorIcons"), ']')
	if symbol == '{':
		suggest_variables(text)
	
	# Force update and showing of the popup
	text.update_code_completion_options(true)


# Helper that adds all characters as options
func suggest_characters(text:CodeEdit, type := CodeEdit.KIND_MEMBER) -> void:
	for character in text.get_parent().editors_manager.resource_helper.character_directory:
		text.add_code_completion_option(type, character, character, text.syntax_highlighter.character_name_color, load("res://addons/dialogic/Editor/Images/Resources/character.svg"))


# Helper that adds all portraits of a given character as options
func suggest_portraits(text:CodeEdit, character_name:String) -> void:
	var character_resource :DialogicCharacter= text.get_parent().editors_manager.resource_helper.character_directory[character_name]['resource']
	for portrait in character_resource.portraits:
		text.add_code_completion_option(CodeEdit.KIND_MEMBER, portrait, portrait, text.syntax_highlighter.character_portrait_color, load("res://addons/dialogic/Editor/Images/Resources/character.svg"), ')')
	if character_resource.portraits.is_empty():
		text.add_code_completion_option(CodeEdit.KIND_MEMBER, 'Has no portraits!', '', text.syntax_highlighter.character_portrait_color, load("res://addons/dialogic/Editor/Images/Pieces/warning.svg"))


# Helper that adds all variable paths as options
func suggest_variables(text:CodeEdit):
	for variable in DialogicUtil.list_variables(ProjectSettings.get_setting('dialogic/variables')):
		text.add_code_completion_option(CodeEdit.KIND_MEMBER, variable, variable, text.syntax_highlighter.variable_color, text.get_theme_icon("MemberProperty", "EditorIcons"), '}')


func suggest_bbcode(text:CodeEdit):
	for i in [['b (bold)', 'b'], ['i (italics)', 'i'], ['color', 'color='], ['font size','font_size=']]:
		text.add_code_completion_option(CodeEdit.KIND_MEMBER, i[0], i[1],  text.syntax_highlighter.normal_color, text.get_theme_icon("RichTextEffect", "EditorIcons"),)
		text.add_code_completion_option(CodeEdit.KIND_CLASS, 'end '+i[0], '/'+i[1],  text.syntax_highlighter.normal_color, text.get_theme_icon("RichTextEffect", "EditorIcons"), ']')

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
	valid_candidates.reverse()
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
	if symbol in completion_shortcodes.keys():
		if !completion_shortcodes[symbol].help_page_path.is_empty():
			OS.shell_open(completion_shortcodes[symbol].help_page_path)


# Called to test if a symbol can be clicked
func symbol_validate(symbol:String, text:CodeEdit) -> void:
	if symbol in completion_shortcodes.keys():
		if !completion_shortcodes[symbol].help_page_path.is_empty():
			text.set_symbol_lookup_word_as_valid(true)
