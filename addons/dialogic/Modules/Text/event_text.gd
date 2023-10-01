@tool
class_name DialogicTextEvent
extends DialogicEvent

## Event that stores text. Can be said by a character. 
## Should be shown by a DialogicNode_DialogText.


### Settings

## This is the content of the text event. 
## It is supposed to be displayed by a DialogicNode_DialogText node. 
## That means you can use bbcode, but also some custom commands.
var text: String = ""
## If this is not null, the given character (as a resource) will be associated with this event.
## The DialogicNode_NameLabel will show the characters display_name. If a typing sound is setup,
## it will play.
var character: DialogicCharacter = null
## If a character is set, this setting can change the portrait of that character.
var portrait: String = ""


### Helpers

## This returns the unique name_identifier of the character. This is used by the editor.
var _character_from_directory: String: 
	get:
		for item in _character_directory.keys():
			if _character_directory[item]['resource'] == character:
				return item
				break
		return _character_from_directory
	set(value):
		_character_from_directory = value
		if value.is_empty():
			character = null
		elif value in _character_directory.keys():
			character = _character_directory[value]['resource']
		
## Used by [_character_from_directory] to fetch the unique name_identifier or resource.
var _character_directory: Dictionary = {}
# Reference regex without Godot escapes: ((")?(?<name>(?(2)[^"\n]*|[^(: \n]*))(?(2)"|)(\W*\((?<portrait>.*)\))?\s*(?<!\\):)?(?<text>(.|\n)*)
var regex := RegEx.create_from_string("((\")?(?<name>(?(2)[^\"\\n]*|[^(: \\n]*))(?(2)\"|)(\\W*(?<portrait>\\(.*\\)))?\\s*(?<!\\\\):)?(?<text>(.|\\n)*)")
# Reference regex without godot escapes: ((\[n\]|\[n\+\])?((?!(\[n\]|\[n\+\]))(.|\n))*)
var split_regex := RegEx.create_from_string("((\\[n\\]|\\[n\\+\\])?((?!(\\[n\\]|\\[n\\+\\]))(.|\\n))*)")

enum States {REVEALING, IDLE, DONE}
var state = States.IDLE
signal advance

################################################################################
## 						EXECUTION
################################################################################

func _execute() -> void:
	if (not character or character.custom_info.get('style', '').is_empty()) and dialogic.has_subsystem('Styles'):
		# if previous characters had a custom style change back to base style 
		if dialogic.current_state_info.get('base_style') != dialogic.current_state_info.get('style'):
			dialogic.Styles.add_layout_style(dialogic.current_state_info.get('base_style', 'Default'))
	
	if character:
		if dialogic.has_subsystem('Styles') and character.custom_info.get('style', null):
			dialogic.Styles.add_layout_style(character.custom_info.style, false)
		
		
		if portrait and dialogic.has_subsystem('Portraits') and dialogic.Portraits.is_character_joined(character):
			dialogic.Portraits.change_character_portrait(character, portrait)
		dialogic.Portraits.change_speaker(character, portrait)
		var check_portrait :String = portrait if !portrait.is_empty() else dialogic.current_state_info['portraits'].get(character.resource_path, {}).get('portrait', '')
		if check_portrait and character.portraits.get(check_portrait, {}).get('sound_mood', '') in character.custom_info.get('sound_moods', {}):
			dialogic.Text.update_typing_sound_mood(character.custom_info.get('sound_moods', {}).get(character.portraits[check_portrait].get('sound_mood', {}), {}))
		elif !character.custom_info.get('sound_mood_default', '').is_empty():
			dialogic.Text.update_typing_sound_mood(character.custom_info.get('sound_moods', {}).get(character.custom_info.get('sound_mood_default'), {}))
		else:
			dialogic.Text.update_typing_sound_mood()
			
		dialogic.Text.update_name_label(character)
	else:
		dialogic.Portraits.change_speaker(null)
		dialogic.Text.update_name_label(null)
	
	dialogic.Text.input_handler.dialogic_action.connect(_on_dialogic_input_action)
	dialogic.Text.input_handler.autoadvance.connect(_on_dialogic_input_autoadvance)
	
	var final_text :String= get_property_translated('text')
	if ProjectSettings.get_setting('dialogic/text/split_at_new_lines', false):
		match ProjectSettings.get_setting('dialogic/text/split_at_new_lines_as', 0):
			0:
				final_text = final_text.replace('\n', '[n]')
			1:
				final_text = final_text.replace('\n', '[n+][br]')
	
	var split_text := []
	for i in split_regex.search_all(final_text):
		split_text.append([i.get_string().trim_prefix('[n]').trim_prefix('[n+]')])
		split_text[-1].append(i.get_string().begins_with('[n+]'))
	
	for section_idx in range(len(split_text)):
		dialogic.Text.hide_next_indicators()
		state = States.REVEALING
		final_text = dialogic.Text.parse_text(split_text[section_idx][0])
		dialogic.Text.about_to_show_text.emit({'text':final_text, 'character':character, 'portrait':portrait, 'append':split_text[section_idx][1]})
		final_text = await dialogic.Text.update_dialog_text(final_text, false, split_text[section_idx][1])
		
		# Plays the audio region for the current line.
		if dialogic.has_subsystem('Voice') and dialogic.Voice.is_voiced(dialogic.current_event_idx):
			dialogic.Voice.play_voice()
		
		await dialogic.Text.text_finished
		state = States.IDLE
		#end of dialog
		if dialogic.has_subsystem('Choices') and dialogic.Choices.is_question(dialogic.current_event_idx):
			dialogic.Text.show_next_indicators(true)
			dialogic.Choices.show_current_choices(false)
			dialogic.current_state = dialogic.States.AWAITING_CHOICE
			return
		elif Dialogic.Text.should_autoadvance():
			dialogic.Text.show_next_indicators(false, true)
			dialogic.Text.input_handler.start_autoadvance()
		else:
			dialogic.Text.show_next_indicators()
		
		if section_idx == len(split_text)-1:
			state = States.DONE
		
		if dialogic.has_subsystem('History'):
			if character:
				dialogic.History.store_simple_history_entry(final_text, event_name, {'character':character.display_name, 'character_color':character.color})
			else:
				dialogic.History.store_simple_history_entry(final_text, event_name)
			dialogic.History.event_was_read(self)
		
		await advance
	
	finish()


func _on_dialogic_input_action():
	match state:
		States.REVEALING:
			if Dialogic.Text.can_skip():
				Dialogic.Text.skip_text_animation()
				Dialogic.Text.input_handler.block_input()
		_:
			if Dialogic.Text.can_manual_advance():
				advance.emit()
				Dialogic.Text.input_handler.block_input()


func _on_dialogic_input_autoadvance():
	if state == States.IDLE or state == States.DONE:
		advance.emit()

################################################################################
## 						INITIALIZE
################################################################################

func _init() -> void:
	event_name = "Text"
	set_default_color('Color1')
	event_category = "Main"
	event_sorting_index = 0
	_character_directory = Engine.get_main_loop().get_meta('dialogic_character_directory')
	expand_by_default = true
	


################################################################################
## 						SAVING/LOADING
################################################################################

func to_text() -> String:
	var text_to_use := text.replace('\n', '\\\n')
	text_to_use = text_to_use.replace(':', '\\:')
	if text_to_use.is_empty():
		text_to_use = "<Empty Text Event>"
	
	if character:
		var name := ""
		for path in _character_directory.keys():
			if _character_directory[path]['resource'] == character:
				name = path
				break
		if name.count(" ") > 0:
			name = '"' + name + '"'
		if not portrait.is_empty():
			return name+" ("+portrait+"): "+text_to_use
		return name+": "+text_to_use
	elif text.begins_with('['):
		text_to_use = '\\'+text_to_use
	else:
		for event in Engine.get_main_loop().get_meta("dialogic_event_cache", []):
			if not event is DialogicTextEvent and event.is_valid_event(text):
				text_to_use = '\\'+text
				continue
	return text_to_use


func from_text(string:String) -> void:
	_character_directory = {}
	if Engine.is_editor_hint() == false:
		_character_directory = Dialogic.character_directory
	else:
		_character_directory = self.get_meta("editor_character_directory")
	
	# load default character
	if !_character_from_directory.is_empty() and _character_directory != null and _character_directory.size() > 0:
		if _character_from_directory in _character_directory.keys():
			character = _character_directory[_character_from_directory]['resource']
	
	var result := regex.search(string)
	if result and !result.get_string('name').is_empty():
		var name := result.get_string('name').strip_edges()
		if name == '_':
			character = null
		elif _character_directory != null and _character_directory.size() > 0:
			character = null
			if _character_directory.has(name):
				character = _character_directory[name]['resource']
			else:
				name = name.replace('"', "")
				# First do a full search to see if more of the path is there then necessary:
				for character in _character_directory:
					if name in _character_directory[character]['full_path']:
						character = _character_directory[character]['resource']
						break
				
				# If it doesn't exist,  at runtime we'll consider it a guest and create a temporary character
				if character == null:
					if Engine.is_editor_hint() == false:
						character = DialogicCharacter.new()
						character.display_name = name
						var entry: Dictionary = {}
						entry['resource'] = character
						entry['full_path'] = "runtime://" + name
						_character_directory[name] = entry

		if !result.get_string('portrait').is_empty():
			portrait = result.get_string('portrait').strip_edges().trim_prefix('(').trim_suffix(')')
		
	if result:
		text = result.get_string('text').replace("\\\n", "\n").replace('\\:', ':').strip_edges().trim_prefix('\\')
		if text == '<Empty Text Event>':
			text = ""


func is_valid_event(string:String) -> bool:
	return true


func is_string_full_event(string:String) -> bool:
	return !string.ends_with('\\')


# this is only here to provide a list of default values
# this way the module manager can add custom default overrides to this event.
func get_shortcode_parameters() -> Dictionary:
	return {
		#param_name 	: property_info
		"character"		: {"property": "_character_from_directory", "default": ""},
		"portrait"		: {"property": "portrait", 					"default": ""},
	}

################################################################################
## 						TRANSLATIONS
################################################################################

func _get_translatable_properties() -> Array:
	return ['text']


func _get_property_original_translation(property:String) -> String:
	match property:
		'text':
			return text
	return ''


################################################################################
## 						EVENT EDITOR
################################################################################

func build_event_editor():
	add_header_edit('_character_from_directory', ValueType.COMPLEX_PICKER, 
			{'file_extension' 	: '.dch', 
			'suggestions_func' 	: get_character_suggestions, 
			'empty_text' 		: '(No one)',
			'icon' 				: load("res://addons/dialogic/Editor/Images/Resources/character.svg")}, 'do_any_characters_exist()')
	add_header_edit('portrait', ValueType.COMPLEX_PICKER,  
			{'suggestions_func' : get_portrait_suggestions, 
			'placeholder' 		: "(Don't change)", 
			'icon' 				: load("res://addons/dialogic/Editor/Images/Resources/portrait.svg"),
			'collapse_when_empty':true,}, 
			'character != null and !has_no_portraits()')
	add_body_edit('text', ValueType.MULTILINE_TEXT, {'autofocus':true})

func do_any_characters_exist() -> bool:
	return !Engine.get_main_loop().get_meta('dialogic_character_directory', {}).is_empty()

func has_no_portraits() -> bool:
	return character and character.portraits.is_empty()


func get_character_suggestions(search_text:String) -> Dictionary:
	var suggestions := {}
	
	#override the previous _character_directory with the meta, specifically for searching otherwise new nodes wont work
	_character_directory = Engine.get_main_loop().get_meta('dialogic_character_directory')
	
	var icon = load("res://addons/dialogic/Editor/Images/Resources/character.svg")
	suggestions['(No one)'] = {'value':null, 'editor_icon':["GuiRadioUnchecked", "EditorIcons"]}
	
	for resource in _character_directory.keys():
		suggestions[resource] = {
				'value' 	: resource, 
				'tooltip' 	: _character_directory[resource]['full_path'], 
				'icon' 		: icon.duplicate()}
	return suggestions
	

func get_portrait_suggestions(search_text:String) -> Dictionary:
	var suggestions := {}
	var icon = load("res://addons/dialogic/Editor/Images/Resources/portrait.svg")
	suggestions["Don't change"] = {'value':'', 'editor_icon':["GuiRadioUnchecked", "EditorIcons"]}
	if character != null:
		for portrait in character.portraits:
			suggestions[portrait] = {'value':portrait, 'icon':icon}
	return suggestions


####################### CODE COMPLETION ########################################
################################################################################

var completion_text_character_getter_regex := RegEx.new()
var completion_text_effects := {}
func _get_code_completion(CodeCompletionHelper:Node, TextNode:TextEdit, line:String, word:String, symbol:String) -> void:
	if completion_text_character_getter_regex.get_pattern().is_empty():
		completion_text_character_getter_regex.compile("(\"[^\"]*\"|[^\\s:]*)")
	
	if completion_text_effects.is_empty():
		for idx in DialogicUtil.get_indexers():
			for effect in idx._get_text_effects():
				completion_text_effects[effect['command']] = effect
	
	if not ':' in line.substr(0, TextNode.get_caret_column()) and symbol == '(':
		var character := completion_text_character_getter_regex.search(line).get_string().trim_prefix('"').trim_suffix('"')
		
		CodeCompletionHelper.suggest_portraits(TextNode, character)
	if symbol == '[':
		suggest_bbcode(TextNode)
		for effect in completion_text_effects.values():
			if effect.get('arg', false):
				TextNode.add_code_completion_option(CodeEdit.KIND_MEMBER, effect.command, effect.command+'=', TextNode.syntax_highlighter.normal_color, TextNode.get_theme_icon("RichTextEffect", "EditorIcons"))
			else:
				TextNode.add_code_completion_option(CodeEdit.KIND_MEMBER, effect.command, effect.command, TextNode.syntax_highlighter.normal_color, TextNode.get_theme_icon("RichTextEffect", "EditorIcons"), ']')
	if symbol == '{':
		CodeCompletionHelper.suggest_variables(TextNode)
	
	if symbol == '=':
		if CodeCompletionHelper.get_line_untill_caret(line).ends_with('[portrait='):
			var character := completion_text_character_getter_regex.search(line).get_string('name')
			CodeCompletionHelper.suggest_portraits(TextNode, character, ']')


func _get_start_code_completion(CodeCompletionHelper:Node, TextNode:TextEdit) -> void:
	CodeCompletionHelper.suggest_characters(TextNode, CodeEdit.KIND_CLASS, true)


func suggest_bbcode(text:CodeEdit):
	for i in [['b (bold)', 'b'], ['i (italics)', 'i'], ['color', 'color='], ['font size','font_size=']]:
		text.add_code_completion_option(CodeEdit.KIND_MEMBER, i[0], i[1],  text.syntax_highlighter.normal_color, text.get_theme_icon("RichTextEffect", "EditorIcons"),)
		text.add_code_completion_option(CodeEdit.KIND_CLASS, 'end '+i[0], '/'+i[1],  text.syntax_highlighter.normal_color, text.get_theme_icon("RichTextEffect", "EditorIcons"), ']')
	for i in [['new event', 'n'],['new event (same box)', 'n+']]:
		text.add_code_completion_option(CodeEdit.KIND_MEMBER, i[0], i[1],  text.syntax_highlighter.normal_color, text.get_theme_icon("ArrowRight", "EditorIcons"),)

#################### SYNTAX HIGHLIGHTING #######################################
################################################################################

var text_effects := ""
var text_effects_regex := RegEx.new()
func load_text_effects():
	if text_effects.is_empty():
		for idx in DialogicUtil.get_indexers():
			for effect in idx._get_text_effects():
				text_effects+= effect['command']+'|'
		text_effects += "b|i|u|s|code|p|center|left|right|fill|n\\+|n|indent|url|img|font|font_size|opentype_features|color|bg_color|fg_color|outline_size|outline_color|table|cell|ul|ol|lb|rb|br"
	if text_effects_regex.get_pattern().is_empty():
		text_effects_regex.compile("(?<!\\\\)\\[\\s*/?(?<command>"+text_effects+")\\s*(=\\s*(?<value>.+?)\\s*)?\\]")


var text_random_word_regex := RegEx.new()
var text_effect_color := Color('#898276')
func _get_syntax_highlighting(Highlighter:SyntaxHighlighter, dict:Dictionary, line:String) -> Dictionary:
	load_text_effects()
	if text_random_word_regex.get_pattern().is_empty():
		text_random_word_regex.compile("(?<!\\\\)\\<[^\\[\\>]+(\\/[^\\>]*)\\>")
	
	var result := regex.search(line)
	if !result:
		return dict
	if Highlighter.mode == Highlighter.Modes.FULL_HIGHLIGHTING:
		if result.get_string('name'):
			dict[result.get_start('name')] = {"color":Highlighter.character_name_color}
			dict[result.get_end('name')] = {"color":Highlighter.normal_color}
		if result.get_string('portrait'):
			dict[result.get_start('portrait')] = {"color":Highlighter.character_portrait_color}
			dict[result.get_end('portrait')] = {"color":Highlighter.normal_color}
	if result.get_string('text'):
		var effects_result := text_effects_regex.search_all(line)
		for eff in effects_result:
			dict[eff.get_start()] = {"color":text_effect_color}
			dict[eff.get_end()] = {"color":Highlighter.normal_color}
		dict = Highlighter.color_region(dict, Highlighter.variable_color, line, '{', '}', result.get_start('text'))

		for replace_mod_match in text_random_word_regex.search_all(result.get_string('text')):
			var color :Color = Highlighter.string_color
			color = color.lerp(Highlighter.normal_color, 0.4)
			dict[replace_mod_match.get_start()+result.get_start('text')] = {'color':Highlighter.string_color}
			var offset := 1
			for b in replace_mod_match.get_string().trim_suffix('>').trim_prefix('<').split('/'):
				color.h = wrap(color.h+0.2, 0, 1)
				dict[replace_mod_match.get_start()+result.get_start('text')+offset] = {'color':color}
				offset += len(b)
				dict[replace_mod_match.get_start()+result.get_start('text')+offset] = {'color':Highlighter.string_color}
				offset += 1
			dict[replace_mod_match.get_end()+result.get_start('text')] = {'color':Highlighter.normal_color}
	return dict
