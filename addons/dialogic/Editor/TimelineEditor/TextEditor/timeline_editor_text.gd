@tool
extends CodeEdit

## Sub-Editor that allows editing timelines in a text format.

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

 
func _ready():
	syntax_highlighter = load("res://addons/dialogic/Editor/TimelineEditor/TextEditor/syntax_highlighter.gd").new()
	
	# Compile RegEx's
	completion_word_regex.compile("(?<s>(\\W)|^)(?<word>\\w*)\\x{FFFF}")
	completion_shortcode_getter_regex.compile("\\[(?<code>\\w*)")
	completion_character_getter_regex.compile("(?<type>Join|Update|Leave)\\s*(\")?(?<name>(?(2)[^\"\\n]*|[^(: \\n]*))(?(2)\"|)(\\W*\\((?<portrait>.*)\\))?(\\s*(?<position>\\d))?(\\s*\\[(?<shortcode>.*)\\])?")
	completion_text_character_getter_regex.compile("\\W*(\")?(?<name>(?(2)[^\"\\n]*|[^(: \\n]*))(?(1)\"|)")
	completion_shortcode_param_getter_regex.compile("(?<param>\\w*)\\W*=\\s*\"?"+String.chr(0xFFFF))


func _on_text_editor_text_changed():
	get_parent().current_resource_state = DialogicEditor.ResourceStates.Unsaved
	request_code_completion(true)



func clear_timeline():
	text = ''


func load_timeline(object:DialogicTimeline) -> void:
	clear_timeline()
	if get_parent().current_resource.events.size() == 0:
		pass
	else: 
		if typeof(get_parent().current_resource.events[0]) == TYPE_STRING:
			get_parent().current_resource.events_processed = false
			get_parent().current_resource = get_parent().editors_manager.resource_helper.process_timeline(get_parent().current_resource)
	
	var result:String = ""	
	var indent := 0
	for idx in range(0, len(object.events)):
		var event = object.events[idx]
		
		if event['event_name'] == 'End Branch':
			indent -= 1
			continue
		
		if event != null:
			for i in event.empty_lines_above:
				result += "\t".repeat(indent)+"\n"
			result += "\t".repeat(indent)+event['event_node_as_text'].replace('\n', "\n"+"\t".repeat(indent)) + "\n"
		if event.can_contain_events:
			indent += 1
		if indent < 0: 
			indent = 0
		
	text = result
	get_parent().current_resource.set_meta("timeline_not_saved", false)


func save_timeline():
	if get_parent().current_resource:
		var text_array:Array = text_timeline_to_array(text)
		
		get_parent().current_resource.events = text_array
		get_parent().current_resource.events_processed = false
		ResourceSaver.save(get_parent().current_resource, get_parent().current_resource.resource_path)

		get_parent().current_resource.set_meta("timeline_not_saved", false)
		get_parent().current_resource_state = DialogicEditor.ResourceStates.Saved
		get_parent().editors_manager.resource_helper.rebuild_timeline_directory()


func text_timeline_to_array(text:String) -> Array:
	# Parse the lines down into an array
	var events := []
	
	var lines := text.split('\n', true)
	var idx := -1
	
	while idx < len(lines)-1:
		idx += 1
		var line :String = lines[idx]
		var line_stripped :String = line.strip_edges(true, true)
		events.append(line)
	
	return events


################################################################################
## 					HELPFUL EDITOR FUNCTIONALITY
################################################################################

func _gui_input(event):
	if not event is InputEventKey: return
	if not event.is_pressed(): return
	match event.as_text():
		"Ctrl+K":
			toggle_comment()
		"Alt+Up":
			move_line(-1)
		"Alt+Down":
			move_line(1)
		_:
			return
	get_viewport().set_input_as_handled()

# Toggle the selected lines as comments
func toggle_comment() -> void:
	var cursor: Vector2 = Vector2(get_caret_column(), get_caret_line())
	var from: int = cursor.y
	var to: int = cursor.y
	if has_selection():
		from = get_selection_from_line()
		to = get_selection_to_line()

	var lines: PackedStringArray = text.split("\n")
	var will_comment: bool = not lines[from].begins_with("# ")
	for i in range(from, to + 1):
		lines[i] = "# " + lines[i] if will_comment else lines[i].substr(2)

	text = "\n".join(lines)
	select(from, 0, to, get_line_width(to))
	set_caret_line(cursor.y)
	set_caret_column(cursor.x)
	text_changed.emit()


# Move the selected lines up or down
func move_line(offset: int) -> void:
	offset = clamp(offset, -1, 1)

	var cursor: Vector2 = Vector2(get_caret_column(), get_caret_line())
	var reselect: bool = false
	var from: int = cursor.y
	var to: int = cursor.y
	if has_selection():
		reselect = true
		from = get_selection_from_line()
		to = get_selection_to_line()

	var lines := text.split("\n")

	if from + offset < 0 or to + offset >= lines.size(): return

	var target_from_index: int = from - 1 if offset == -1 else to + 1
	var target_to_index: int = to if offset == -1 else from
	var line_to_move: String = lines[target_from_index]
	lines.remove_at(target_from_index)
	lines.insert(target_to_index, line_to_move)

	text = "\n".join(lines)

	cursor.y += offset
	from += offset
	to += offset
	if reselect:
		select(from, 0, to, get_line_width(to))
	set_caret_line(cursor.y)
	set_caret_column(cursor.x)
	text_changed.emit()


# Allows dragging files into the editor
func _can_drop_data(at_position:Vector2, data:Variant) -> bool:
	if typeof(data) == TYPE_DICTIONARY and 'files' in data.keys() and len(data.files) == 1:
		return true
	return false

# Allows dragging files into the editor
func _drop_data(at_position:Vector2, data:Variant) -> void:
	if typeof(data) == TYPE_DICTIONARY and 'files' in data.keys() and len(data.files) == 1:
		set_caret_column(get_line_column_at_pos(at_position).x)
		set_caret_line(get_line_column_at_pos(at_position).y)
		insert_text_at_caret('"'+data.files[0]+'"')


################################################################################
## 					AUTO COMPLETION
################################################################################

# Helper that gets the current line with a special character where the caret is
func get_code_completion_line() -> String:
	return get_line(get_caret_line()).insert(get_caret_column(), String.chr(0xFFFF)).strip_edges()


# Helper that gets the currently typed word
func get_code_completion_word() -> String:
	var result := completion_word_regex.search(get_code_completion_line())
	return result.get_string('word') if result else ""


# Helper that gets the symbol before the current word
func get_code_completion_prev_symbol() -> String:
	var result := completion_word_regex.search(get_code_completion_line())
	return result.get_string('s') if result else ""


# Called if something was typed
# Adds all kinds of options depending on the 
#   content of the current line, the last word and the symbol that came before
# Triggers opening of the popup
func _request_code_completion(force):
	# make sure shortcode event references are loaded
	if completion_shortcodes.is_empty():
		for event in get_parent().editors_manager.resource_helper.event_script_cache:
			if event.get_shortcode() != 'default_shortcode':
				completion_shortcodes[event.get_shortcode()] = event
	
	# fill helpers
	var line := get_code_completion_line()
	var word := get_code_completion_word()
	var symbol := get_code_completion_prev_symbol()
	
	
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
	if line.begins_with('['):
		if symbol == '[':
			# suggest shortcodes if a shortcode event has just begun
			for shortcode in completion_shortcodes.keys():
				add_code_completion_option(CodeEdit.KIND_MEMBER, shortcode, shortcode, completion_shortcodes[shortcode].event_color, completion_shortcodes[shortcode]._get_icon())
		
		else:
			# suggest either parameters or values
			var current_shortcode := completion_shortcode_getter_regex.search(line)
			if current_shortcode:
				var code := current_shortcode.get_string('code')
				if code in completion_shortcodes.keys():
					if symbol == ' ':
						for param in completion_shortcodes[code].get_shortcode_parameters().keys():
							add_code_completion_option(CodeEdit.KIND_MEMBER, param, param+'="' , syntax_highlighter.shortcode_param_color)
					elif symbol == '=' or symbol == '"':
						var current_parameter_gex := completion_shortcode_param_getter_regex.search(line)
						if current_parameter_gex: 
							var current_parameter := current_parameter_gex.get_string('param')
							if completion_shortcodes[code].get_shortcode_parameters().has(current_parameter):
								if completion_shortcodes[code].get_shortcode_parameters()[current_parameter].has('suggestions'):
									var suggestions : Dictionary= completion_shortcodes[code].get_shortcode_parameters()[current_parameter]['suggestions'].call()
									for key in suggestions.keys():
										add_code_completion_option(CodeEdit.KIND_MEMBER, key, suggestions[key].value, syntax_highlighter.shortcode_value_color, suggestions[key].get('icon', null), '"')
	
	# Condition event suggestions
	elif line.begins_with('if') or line.begins_with('elif'):
		if symbol == '{':
			suggest_variables()
	
	# Choice Event suggestions
	elif line.begins_with('-') and '[' in line:
		if symbol == '[':
			add_code_completion_option(CodeEdit.KIND_MEMBER, 'if', 'if ', syntax_highlighter.code_flow_color)
		elif symbol == '{':
			suggest_variables()
	
	# Character Event suggestions
	elif line.begins_with('Join') or line.begins_with('Leave') or line.begins_with('Update'):
		if symbol == ' ' and line.count(' ') <= max(line.count('"'), 1):
			suggest_characters()
			if line.begins_with('Leave'):
				add_code_completion_option(CodeEdit.KIND_MEMBER, 'All', '--All-- ', syntax_highlighter.character_name_color, get_theme_icon("GuiEllipsis", "EditorIcons"))
		
		if symbol == '(':
			var character:= completion_character_getter_regex.search(line).get_string('name')
			suggest_portraits(character)
	
	# Start of line suggestions
	# These are all as KIND_PLAIN_TEXT, because that means they won't 
	# be suggested unless at least the first letter is typed in.
	elif not ' ' in line:
		add_code_completion_option(CodeEdit.KIND_PLAIN_TEXT, 'Join', 'Join ', syntax_highlighter.character_event_color, load('res://addons/dialogic/Editor/Images/Dropdown/join.svg'))
		add_code_completion_option(CodeEdit.KIND_PLAIN_TEXT, 'Leave', 'Leave ', syntax_highlighter.character_event_color, load('res://addons/dialogic/Editor/Images/Dropdown/leave.svg'))
		add_code_completion_option(CodeEdit.KIND_PLAIN_TEXT, 'Update', 'Update ', syntax_highlighter.character_event_color, load('res://addons/dialogic/Editor/Images/Dropdown/update.svg'))
		
		add_code_completion_option(CodeEdit.KIND_PLAIN_TEXT, 'if', 'if ', syntax_highlighter.code_flow_color)
		add_code_completion_option(CodeEdit.KIND_PLAIN_TEXT, 'elif', 'elif ', syntax_highlighter.code_flow_color)
		add_code_completion_option(CodeEdit.KIND_PLAIN_TEXT, 'else', 'else:', syntax_highlighter.code_flow_color)
		
		add_code_completion_option(CodeEdit.KIND_PLAIN_TEXT, 'VAR', 'VAR ', syntax_highlighter.keyword_VAR_color)
		
		suggest_characters(CodeEdit.KIND_CLASS)
	
	# Text Event Suggestions
	else:
		if not ':' in line and symbol == '(':
			var character := completion_text_character_getter_regex.search(line).get_string('name')
			suggest_portraits(character)
		if symbol == '[':
			add_code_completion_option(CodeEdit.KIND_MEMBER, 'speed (custom)', 'speed=', syntax_highlighter.normal_color, get_theme_icon("RichTextEffect", "EditorIcons"))
			add_code_completion_option(CodeEdit.KIND_MEMBER, 'speed (default)', 'speed', syntax_highlighter.normal_color, get_theme_icon("RichTextEffect", "EditorIcons"), ']')
			add_code_completion_option(CodeEdit.KIND_MEMBER, 'pause (custom)', 'pause=', syntax_highlighter.normal_color, get_theme_icon("RichTextEffect", "EditorIcons"))
			add_code_completion_option(CodeEdit.KIND_MEMBER, 'pause (default)', 'pause', syntax_highlighter.normal_color, get_theme_icon("RichTextEffect", "EditorIcons"), ']')
			add_code_completion_option(CodeEdit.KIND_MEMBER, 'portrait', 'portrait=', syntax_highlighter.normal_color, get_theme_icon("RichTextEffect", "EditorIcons"))
			add_code_completion_option(CodeEdit.KIND_MEMBER, 'br', 'br', syntax_highlighter.normal_color, get_theme_icon("RichTextEffect", "EditorIcons"), ']')
			add_code_completion_option(CodeEdit.KIND_MEMBER, 'signal', 'signal=', syntax_highlighter.normal_color, get_theme_icon("RichTextEffect", "EditorIcons"))
		if symbol == '{':
			suggest_variables()
	
	# Force update and showing of the popup
	update_code_completion_options(true)


# Helper that adds all characters as options
func suggest_characters(type := CodeEdit.KIND_MEMBER) -> void:
	for character in get_parent().editors_manager.resource_helper.character_directory:
		add_code_completion_option(type, character, character, syntax_highlighter.character_name_color, load("res://addons/dialogic/Editor/Images/Resources/character.svg"))


# Helper that adds all portraits of a given character as options
func suggest_portraits(character_name:String) -> void:
	var character_resource :DialogicCharacter= get_parent().editors_manager.resource_helper.character_directory[character_name]['resource']
	for portrait in character_resource.portraits:
		add_code_completion_option(CodeEdit.KIND_MEMBER, portrait, portrait, syntax_highlighter.character_portrait_color, load("res://addons/dialogic/Editor/Images/Resources/character.svg"), ')')
	if character_resource.portraits.is_empty():
		add_code_completion_option(CodeEdit.KIND_MEMBER, 'Has no portraits!', '', syntax_highlighter.character_portrait_color, load("res://addons/dialogic/Editor/Images/Pieces/warning.svg"))


# Helper that adds all variable paths as options
func suggest_variables():
	for variable in DialogicUtil.list_variables(DialogicUtil.get_project_setting('dialogic/variables')):
		add_code_completion_option(CodeEdit.KIND_MEMBER, variable, variable, syntax_highlighter.variable_color, get_theme_icon("MemberProperty", "EditorIcons"), '}')


# Filters the list of all possible options, depending on what was typed
# Purpose of the different Kinds is explained in [_request_code_completion]
func _filter_code_completion_candidates(candidates:Array):
	var valid_candidates := []
	var current_word := get_code_completion_word()
	for candidate in candidates:
		if candidate.kind == KIND_PLAIN_TEXT:
			if !current_word.is_empty() and candidate.insert_text.begins_with(current_word):
				valid_candidates.append(candidate)
		elif candidate.kind == KIND_MEMBER:
			if current_word.is_empty() or current_word.to_lower() in candidate.insert_text.to_lower():
				valid_candidates.append(candidate)
		elif candidate.kind == KIND_CONSTANT:
			if current_word.is_empty() or candidate.insert_text.begins_with(current_word):
				valid_candidates.append(candidate)
		elif candidate.kind == KIND_CLASS:
			if !current_word.is_empty() and current_word.to_lower() in candidate.insert_text.to_lower():
				valid_candidates.append(candidate)
	valid_candidates.reverse()
	return valid_candidates


# Called when code completion was activated
# Inserts the selected item
func _confirm_code_completion(replace):
	# Note: I decided to ALWAYS use replace mode, as dialogic is supposed to be beginner friendly 
	var word := get_code_completion_word()
	var code_completion := get_code_completion_option(get_code_completion_selected_index())
	remove_text(get_caret_line(), get_caret_column()-len(word), get_caret_line(), get_caret_column())
	set_caret_column(get_caret_column()-len(word))
	insert_text_at_caret(code_completion.insert_text)#
	if code_completion.has('default_value') and typeof(code_completion['default_value']) == TYPE_STRING:
		var next_letter := get_line(get_caret_line()).substr(get_caret_column(), 1)
		if next_letter != code_completion['default_value']:
			insert_text_at_caret(code_completion['default_value'])
		else:
			set_caret_column(get_caret_column()+1)


################################################################################
##					SYMBOL CLICKING
################################################################################

# Performs an action (like opening a link) when a valid symbol was clicked
func _on_symbol_lookup(symbol, line, column):
	if symbol in completion_shortcodes.keys():
		if !completion_shortcodes[symbol].help_page_path.is_empty():
			OS.shell_open(completion_shortcodes[symbol].help_page_path)


# Called to test if a symbol can be clicked
func _on_symbol_validate(symbol:String) -> void:
	if symbol in completion_shortcodes.keys():
		if !completion_shortcodes[symbol].help_page_path.is_empty():
			set_symbol_lookup_word_as_valid(true)
