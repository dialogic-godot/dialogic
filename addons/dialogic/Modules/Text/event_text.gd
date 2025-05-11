@tool
class_name DialogicTextEvent
extends DialogicEvent

## Event that stores text. Can be said by a character.
## Should be shown by a DialogicNode_DialogText.


### Settings

## This is the content of the text event.
## It is supposed to be displayed by a DialogicNode_DialogText node.
## That means you can use bbcode, but also some custom commands.
var text := ""
## If this is not null, the given character (as a resource) will be associated with this event.
## The DialogicNode_NameLabel will show the characters display_name. If a typing sound is setup,
## it will play.
var character: DialogicCharacter = null
## If a character is set, this setting can change the portrait of that character.
var portrait := ""

### Helpers

## Used to set the character resource from the unique name identifier and vice versa
var character_identifier: String:
	get:
		if character:
			var identifier := character.get_identifier()
			if not identifier.is_empty():
				return identifier
		return character_identifier
	set(value):
		character_identifier = value
		character = DialogicResourceUtil.get_character_resource(value)
		if (not character) or (character and not character.portraits.has(portrait)):
			portrait = ""
			ui_update_needed.emit()

var regex := RegEx.create_from_string(r'\s*((")?(?<name>(?(2)[^"\n]*|[^(: \n]*))(?(2)"|)(\W*(?<portrait>\(.*\)))?\s*(?<!\\):)?(?<text>(.|\n)*)')
var split_regex := RegEx.create_from_string(r"((\[n\]|\[n\+\])?((?!(\[n\]|\[n\+\]))(.|\n))+)")

enum States {REVEALING, IDLE, DONE}
var state := States.IDLE
signal advance


#region EXECUTION
################################################################################

func _clear_state() -> void:
	dialogic.current_state_info.erase('text_sub_idx')
	_disconnect_signals()


func _execute() -> void:
	if text.is_empty():
		finish()
		return


	## Change Portrait and Active Speaker
	if dialogic.has_subsystem("Portraits"):
		if character:

			dialogic.Portraits.change_speaker(character, portrait)

			if portrait and dialogic.Portraits.is_character_joined(character):
				dialogic.Portraits.change_character_portrait(character, portrait)

		else:
			dialogic.Portraits.change_speaker(null)

	## Change and Type Sound Mood
	if character:
		dialogic.Text.update_name_label(character)

		var current_portrait: String = portrait
		if portrait.is_empty():
			current_portrait = dialogic.current_state_info["portraits"].get(character.get_identifier(), {}).get("portrait", "")

		var current_portrait_sound_mood: String = character.portraits.get(current_portrait, {}).get("sound_mood", "")
		dialogic.Text.update_typing_sound_mood_from_character(character, current_portrait_sound_mood)

	else:
		dialogic.Text.update_name_label(null)
		dialogic.Text.update_typing_sound_mood()


	## Handle style changes
	if dialogic.has_subsystem("Styles"):
		var current_base_style: String = dialogic.current_state_info.get("base_style")
		var current_style: String = dialogic.current_state_info.get("style", "")
		var character_style: String = "" if not character else character.custom_info.get("style", "")

		## Change back to base style, if another characters style is currently used
		if (not character or character_style.is_empty()) and (current_base_style != current_style):
			dialogic.Styles.change_style(dialogic.current_state_info.get("base_style", "Default"))
			await dialogic.get_tree().process_frame

		## Change to the characters style if this character has one
		elif character and not character_style.is_empty():
			dialogic.Styles.change_style(character_style, false)
			await dialogic.get_tree().process_frame

	_connect_signals()

	var character_name_text := dialogic.Text.get_character_name_parsed(character)
	var final_text: String = get_property_translated('text')
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

	dialogic.current_state_info['text_sub_idx'] = dialogic.current_state_info.get('text_sub_idx', -1)

	var reveal_next_segment: bool = dialogic.current_state_info['text_sub_idx'] == -1

	for section_idx in range(min(max(0, dialogic.current_state_info['text_sub_idx']), len(split_text)-1), len(split_text)):
		dialogic.Inputs.block_input(ProjectSettings.get_setting('dialogic/text/text_reveal_skip_delay', 0.1))

		if reveal_next_segment:
			dialogic.Text.hide_next_indicators()

			dialogic.current_state_info['text_sub_idx'] = section_idx

			var segment: String = dialogic.Text.parse_text(split_text[section_idx][0])
			var is_append: bool = split_text[section_idx][1]

			final_text = segment
			dialogic.Text.about_to_show_text.emit({'text':final_text, 'character':character, 'portrait':portrait, 'append': is_append})

			await dialogic.Text.update_textbox(final_text, false)

			state = States.REVEALING
			_try_play_current_line_voice()
			final_text = dialogic.Text.update_dialog_text(final_text, false, is_append)

			dialogic.Text.text_started.emit({'text':final_text, 'character':character, 'portrait':portrait, 'append': is_append})

			_mark_as_read(character_name_text, final_text)

			# We must skip text animation before we potentially return when there
			# is a Choice event.
			if dialogic.Inputs.auto_skip.enabled:
				dialogic.Text.skip_text_reveal()
			else:
				await dialogic.Text.text_finished

			state = States.IDLE
		else:
			reveal_next_segment = true

		# Handling potential Choice Events.
		if section_idx == len(split_text)-1 and dialogic.has_subsystem('Choices') and dialogic.Choices.is_question(dialogic.current_event_idx):
			dialogic.Text.show_next_indicators(true)

			finish()
			return

		elif dialogic.Inputs.auto_advance.is_enabled():
			dialogic.Text.show_next_indicators(false, true)
			dialogic.Inputs.auto_advance.start()
		else:
			dialogic.Text.show_next_indicators()

		if section_idx == len(split_text)-1:
			state = States.DONE

		# If Auto-Skip is enabled and there are multiple parts of this text
		# we need to skip the text after the defined time per event.
		if dialogic.Inputs.auto_skip.enabled:
			await dialogic.Inputs.start_autoskip_timer()

			# Check if Auto-Skip is still enabled.
			if not dialogic.Inputs.auto_skip.enabled:
				await advance

		else:
			await advance


	finish()


func _mark_as_read(character_name_text: String, final_text: String) -> void:
	if dialogic.has_subsystem('History'):
		if character:
			dialogic.History.store_simple_history_entry(final_text, event_name, {'character':character_name_text, 'character_color':character.color})
		else:
			dialogic.History.store_simple_history_entry(final_text, event_name)
		dialogic.History.mark_event_as_visited()


func _connect_signals() -> void:
	if not dialogic.Inputs.dialogic_action.is_connected(_on_dialogic_input_action):
		dialogic.Inputs.dialogic_action.connect(_on_dialogic_input_action)

		dialogic.Inputs.auto_skip.toggled.connect(_on_auto_skip_enable)

	if not dialogic.Inputs.auto_advance.autoadvance.is_connected(_on_dialogic_input_autoadvance):
		dialogic.Inputs.auto_advance.autoadvance.connect(_on_dialogic_input_autoadvance)


## If the event is done, this method can clean-up signal connections.
func _disconnect_signals() -> void:
	if dialogic.Inputs.dialogic_action.is_connected(_on_dialogic_input_action):
		dialogic.Inputs.dialogic_action.disconnect(_on_dialogic_input_action)
	if dialogic.Inputs.auto_advance.autoadvance.is_connected(_on_dialogic_input_autoadvance):
		dialogic.Inputs.auto_advance.autoadvance.disconnect(_on_dialogic_input_autoadvance)
	if dialogic.Inputs.auto_skip.toggled.is_connected(_on_auto_skip_enable):
		dialogic.Inputs.auto_skip.toggled.disconnect(_on_auto_skip_enable)


## Tries to play the voice clip for the current line.
func _try_play_current_line_voice() -> void:
	# If Auto-Skip is enabled and we skip voice clips, we don't want to play.
	if (dialogic.Inputs.auto_skip.enabled
	and dialogic.Inputs.auto_skip.skip_voice):
		return

	# Plays the audio region for the current line.
	if (dialogic.has_subsystem('Voice')
	and dialogic.Voice.is_voiced(dialogic.current_event_idx)):
		dialogic.Voice.play_voice()


func _on_dialogic_input_action() -> void:
	match state:
		States.REVEALING:
			if dialogic.Text.is_text_reveal_skippable():
				dialogic.Text.skip_text_reveal()
				dialogic.Inputs.stop_timers()
		_:
			if dialogic.Inputs.manual_advance.is_enabled():
				advance.emit()
				dialogic.Inputs.stop_timers()


func _on_dialogic_input_autoadvance() -> void:
	if state == States.IDLE or state == States.DONE:
		advance.emit()


func _on_auto_skip_enable(enabled: bool) -> void:
	if not enabled:
		return

	match state:
		States.DONE:
			await dialogic.Inputs.start_autoskip_timer()

			# If Auto-Skip is still enabled, advance the text.
			if dialogic.Inputs.auto_skip.enabled:
				advance.emit()

		States.REVEALING:
			dialogic.Text.skip_text_reveal()

#endregion


#region INITIALIZE
################################################################################

func _init() -> void:
	event_name = "Text"
	set_default_color('Color1')
	event_category = "Main"
	event_sorting_index = 0
	expand_by_default = true
	help_page_path = "https://docs.dialogic.pro/writing-texts.html"



################################################################################
## 						SAVING/LOADING
################################################################################

func to_text() -> String:
	var result := text.replace('\n', '\\\n')
	result = result.replace(':', '\\:')
	if result.is_empty():
		result = "<Empty Text Event>"

	if character or character_identifier:
		var name := character_identifier
		if character:
			name = character.get_identifier()
		if name.count(" ") > 0:
			name = '"' + name + '"'
		if not portrait.is_empty():
			result =  name+" ("+portrait+"): "+result
		else:
			result = name+": "+result
	for event in DialogicResourceUtil.get_event_cache():
		if not event is DialogicTextEvent and event.is_valid_event(result):
			result = '\\'+result
			break

	return result


func from_text(string:String) -> void:
	# Load default character
	# This is only of relevance if the default has been overriden (usually not)
	character = DialogicResourceUtil.get_character_resource(character_identifier)

	var result := regex.search(string.trim_prefix('\\'))

	if result.get_string('portrait'):
		portrait = result.get_string('portrait').strip_edges().trim_prefix('(').trim_suffix(')')

	if result and not result.get_string('name').is_empty():
		var name := result.get_string('name').strip_edges()

		if name == '_':
			character = null
		else:
			character = DialogicResourceUtil.get_character_resource(name)

			if character == null:
				if Engine.is_editor_hint() == false:
					character = DialogicCharacter.new()
					character.display_name = name
					character.set_identifier(name)
					if portrait:
						character.color = Color(portrait)
				else:
					character_identifier = name

	if not result:
		return

	text = result.get_string('text').replace("\\\n", "\n").replace('\\:', ':').strip_edges().trim_prefix('\\')
	if text == '<Empty Text Event>':
		text = ""


func is_valid_event(_string:String) -> bool:
	return true


func is_string_full_event(string:String) -> bool:
	return !string.ends_with('\\')


# this is only here to provide a list of default values
# this way the module manager can add custom default overrides to this event.
func get_shortcode_parameters() -> Dictionary:
	return {
		#param_name 	: property_info
		"character"		: {"property": "character_identifier", "default": ""},
		"portrait"		: {"property": "portrait", 					"default": ""},
	}
#endregion


#region TRANSLATIONS
################################################################################

func _get_translatable_properties() -> Array:
	return ['text']


func _get_property_original_translation(property:String) -> String:
	match property:
		'text':
			return text
	return ''


#endregion


#region EVENT EDITOR
################################################################################

func _enter_visual_editor(editor:DialogicEditor):
	editor.opened.connect(func(): ui_update_needed.emit())


func build_event_editor() -> void:
	add_header_edit('character_identifier', ValueType.DYNAMIC_OPTIONS,
			{'file_extension' 	: '.dch',
			'mode'				: 2,
			'suggestions_func' 	: get_character_suggestions,
			'placeholder' 		: '(No one)',
			'icon' 				: load("res://addons/dialogic/Editor/Images/Resources/character.svg")}, 'do_any_characters_exist()')
	add_header_edit('portrait', ValueType.DYNAMIC_OPTIONS,
			{'suggestions_func' : get_portrait_suggestions,
			'placeholder' 		: "(Don't change)",
			'icon' 				: load("res://addons/dialogic/Editor/Images/Resources/portrait.svg"),
			'collapse_when_empty': true,},
			'should_show_portrait_selector()')
	add_body_edit('text', ValueType.MULTILINE_TEXT, {'autofocus':true})


func should_show_portrait_selector() -> bool:
	return character and not character.portraits.is_empty() and not character.portraits.size() == 1


func do_any_characters_exist() -> bool:
	return not DialogicResourceUtil.get_character_directory().is_empty()


func get_character_suggestions(search_text:String) -> Dictionary:
	var suggestions := DialogicUtil.get_character_suggestions(search_text, character, true, false, editor_node)
	if search_text and not search_text in suggestions:
		suggestions[search_text] = {
			"value":search_text,
			"tooltip": "A temporary character, created on the spot.",
			"editor_icon":["GuiEllipsis", "EditorIcons"]}
	return suggestions

func get_portrait_suggestions(search_text:String) -> Dictionary:
	return DialogicUtil.get_portrait_suggestions(search_text, character, true, "Don't change")

#endregion


#region CODE COMPLETION
################################################################################

var completion_text_character_getter_regex := RegEx.new()
var completion_text_effects := {}
func _get_code_completion(CodeCompletionHelper:Node, TextNode:TextEdit, line:String, _word:String, symbol:String) -> void:
	if completion_text_character_getter_regex.get_pattern().is_empty():
		completion_text_character_getter_regex.compile("(\"[^\"]*\"|[^\\s:]*)")

	if completion_text_effects.is_empty():
		for idx in DialogicUtil.get_indexers():
			for effect in idx._get_text_effects():
				completion_text_effects[effect['command']] = effect

	if not ':' in line.substr(0, TextNode.get_caret_column()) and symbol == '(':
		var completion_character := completion_text_character_getter_regex.search(line).get_string().trim_prefix('"').trim_suffix('"')
		CodeCompletionHelper.suggest_portraits(TextNode, completion_character)

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
			var completion_character := completion_text_character_getter_regex.search(line).get_string('name')
			CodeCompletionHelper.suggest_portraits(TextNode, completion_character, ']')


func _get_start_code_completion(CodeCompletionHelper:Node, TextNode:TextEdit) -> void:
	CodeCompletionHelper.suggest_characters(TextNode, CodeEdit.KIND_CLASS, self)


func suggest_bbcode(TextNode:CodeEdit):
	for i in [['b (bold)', 'b'], ['i (italics)', 'i'], ['color', 'color='], ['font size','font_size=']]:
		TextNode.add_code_completion_option(CodeEdit.KIND_MEMBER, i[0], i[1],  TextNode.syntax_highlighter.normal_color, TextNode.get_theme_icon("RichTextEffect", "EditorIcons"),)
		TextNode.add_code_completion_option(CodeEdit.KIND_CLASS, 'end '+i[0], '/'+i[1],  TextNode.syntax_highlighter.normal_color, TextNode.get_theme_icon("RichTextEffect", "EditorIcons"), ']')
	for i in [['new event', 'n'],['new event (same box)', 'n+']]:
		TextNode.add_code_completion_option(CodeEdit.KIND_MEMBER, i[0], i[1],  TextNode.syntax_highlighter.normal_color, TextNode.get_theme_icon("ArrowRight", "EditorIcons"),)

#endregion


#region SYNTAX HIGHLIGHTING
################################################################################

var text_effects := ""
var text_effects_regex := RegEx.new()
func load_text_effects() -> void:
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
		text_random_word_regex.compile(r"(?<!\\)\<[^\>]+(\/[^\>]*)\>")

	var result := regex.search(line)
	if not result:
		return dict
	if Highlighter.mode == Highlighter.Modes.FULL_HIGHLIGHTING:
		if result.get_string('name'):
			dict[result.get_start('name')] = {"color":Highlighter.character_name_color}
			dict[result.get_end('name')] = {"color":Highlighter.normal_color}
		if result.get_string('portrait'):
			dict[result.get_start('portrait')] = {"color":Highlighter.character_portrait_color}
			dict[result.get_end('portrait')] = {"color":Highlighter.normal_color}
	if result.get_string('text'):

		## Color the random selection modifier
		for replace_mod_match in text_random_word_regex.search_all(result.get_string('text')):
			var color: Color = Highlighter.string_color
			color = color.lerp(Highlighter.normal_color, 0.4)
			dict[replace_mod_match.get_start()+result.get_start('text')] = {'color':Highlighter.string_color}
			var offset := 1
			for b:RegExMatch in RegEx.create_from_string(r"(\[[^\]]*\]|[^\/]|\/\/)+").search_all(replace_mod_match.get_string().trim_prefix("<").trim_suffix(">")):
				color.h = wrap(color.h+0.2, 0, 1)
				dict[replace_mod_match.get_start()+result.get_start('text')+offset] = {'color':color}
				offset += len(b.get_string())
				dict[replace_mod_match.get_start()+result.get_start('text')+offset] = {'color':Highlighter.string_color}
				offset += 1
			dict[replace_mod_match.get_end()+result.get_start('text')] = {'color':Highlighter.normal_color}

		## Color bbcode and text effects
		var effects_result := text_effects_regex.search_all(line)
		for eff in effects_result:
			var prev_color: Color = Highlighter.dict_get_color_at_column(dict, eff.get_start())
			dict[eff.get_start()] = {"color":text_effect_color.lerp(prev_color, 0.4)}
			dict[eff.get_end()] = {"color":prev_color}
		dict = Highlighter.color_region(dict, Highlighter.variable_color, line, '{', '}', result.get_start('text'))

	return dict

#endregion
