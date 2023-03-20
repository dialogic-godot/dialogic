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
		return ""
	set(value): 
		_character_from_directory = value
		if value in _character_directory.keys():
			character = _character_directory[value]['resource']
## Used by [_character_from_directory] to fetch the unique name_identifier or resource.
var _character_directory: Dictionary = {}


################################################################################
## 						EXECUTION
################################################################################

func _execute() -> void:
	if (not character or character.custom_info.get('style', '').is_empty()) and dialogic.has_subsystem('Styles'):
		# if previous characters had a custom style change back to base style 
		if dialogic.current_state_info.get('base_style') != dialogic.current_state_info.get('style'):
			dialogic.Styles.change_style(dialogic.current_state_info.get('base_style', 'Default'))
	
	if character:
		if dialogic.has_subsystem('Styles') and character.custom_info.get('style', null):
			dialogic.Styles.change_style(character.custom_info.style)
		
		dialogic.Text.update_name_label(character)
		
		if portrait and dialogic.has_subsystem('Portraits') and dialogic.Portraits.is_character_joined(character):
				dialogic.Portraits.change_portrait(character, portrait)
		var check_portrait = portrait if !portrait.is_empty() else dialogic.current_state_info['portraits'].get(character.resource_path, {}).get('portrait', '')
		if check_portrait and character.portraits.get(check_portrait, {}).get('sound_mood', '') in character.custom_info.get('sound_moods', {}):
			dialogic.Text.update_typing_sound_mood(character.custom_info.get('sound_moods', {}).get(character.portraits[check_portrait].get('sound_mood', {}), {}))
		elif !character.custom_info.get('sound_mood_default', '').is_empty():
			dialogic.Text.update_typing_sound_mood(character.custom_info.get('sound_moods', {}).get(character.custom_info.get('sound_mood_default')))
	else:
		dialogic.Text.update_name_label(null)
	
	# this will only do something if the rpg portrait mode is enabled
	if dialogic.has_subsystem('Portraits'):
		dialogic.Portraits.update_rpg_portrait_mode(character, portrait)
	
	# RENDER DIALOG
	var final_text: String = get_property_translated('text')
	if dialogic.has_subsystem('VAR'):
		final_text = dialogic.VAR.parse_variables(final_text)
	if dialogic.has_subsystem('Glossary'):
		final_text = dialogic.Glossary.parse_glossary(final_text)
	
	final_text = dialogic.Text.update_dialog_text(final_text)
	
	#Plays the audio region for the current line.
	if dialogic.has_subsystem('Voice') and dialogic.Voice.is_voiced(dialogic.current_event_idx):
		dialogic.Voice.play_voice()
	
	await dialogic.Text.text_finished
	
	#end of dialog
	if dialogic.has_subsystem('Choices') and dialogic.Choices.is_question(dialogic.current_event_idx):
		dialogic.Text.show_next_indicators(true)
		dialogic.Choices.show_current_choices()
		dialogic.current_state = dialogic.states.AWAITING_CHOICE
	elif Dialogic.Text.should_autoadvance():
		dialogic.Text.show_next_indicators(false, true)
		# In this case continuing is handled by the input script.
	else:
		dialogic.Text.show_next_indicators()
		finish()
	if dialogic.has_subsystem('History'):
		if character:
			dialogic.History.store_simple_history_entry(final_text, event_name, {'character':character.display_name, 'character_color':character.color})
		else:
			dialogic.History.store_simple_history_entry(final_text, event_name)
		dialogic.History.event_was_read(self)

################################################################################
## 						INITIALIZE
################################################################################

func _init() -> void:
	event_name = "Text"
	set_default_color('Color1')
	event_category = Category.Main
	event_sorting_index = 0
	help_page_path = "https://dialogic.coppolaemilio.com/documentation/Events/000/"
	continue_at_end = false


################################################################################
## 						SAVING/LOADING
################################################################################

func to_text() -> String:
	var text_to_use := text.replace('\n', '\\\n')
	text_to_use = text_to_use.replace(':', '\\:')
	if character:
		var name = ""
		for path in _character_directory.keys():
			if _character_directory[path]['resource'] == character:
				name = path
				break
		if name.count(" ") > 0:
			name = '"' + name + '"'
		if not portrait.is_empty():
			return name+" ("+portrait+"): "+text_to_use
		return name+": "+text_to_use
	return text_to_use


func from_text(string:String) -> void:
	_character_directory = {}
	if Engine.is_editor_hint() == false:
		_character_directory = Dialogic.character_directory
	else:
		_character_directory = self.get_meta("editor_character_directory")
	var reg := RegEx.new()
	
	# Reference regex without Godot escapes: ((")?(?<name>(?(2)[^"\n]*|[^(: \n]*))(?(2)"|)(\W*\((?<portrait>.*)\))?\s*(?<!\\):)?(?<text>(.|\n)*)
	reg.compile("((\")?(?<name>(?(2)[^\"\\n]*|[^(: \\n]*))(?(2)\"|)(\\W*\\((?<portrait>.*)\\))?\\s*(?<!\\\\):)?(?<text>(.|\\n)*)")
	var result := reg.search(string)
	if result and !result.get_string('name').is_empty():
		var name := result.get_string('name').strip_edges()
		
		if _character_directory != null:
			if _character_directory.size() > 0:
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
			portrait = result.get_string('portrait').strip_edges()
	
	if result:
		text = result.get_string('text').replace("\\\n", "\n").replace('\\:', ':').strip_edges()


func is_valid_event(string:String) -> bool:
	return true


func is_string_full_event(string:String) -> bool:
	return !string.ends_with('\\')


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
	add_header_edit('_character_from_directory', ValueType.ComplexPicker, '', '', 
			{'file_extension' 	: '.dch', 
			'suggestions_func' 	: get_character_suggestions, 
			'empty_text' 		: '(No one)',
			'icon' 				: load("res://addons/dialogic/Editor/Images/Resources/character.svg")}, 'do_any_characters_exist()')
	add_header_edit('portrait', ValueType.ComplexPicker, '', '', 
			{'suggestions_func' : get_portrait_suggestions, 
			'placeholder' 		: "(Don't change)", 
			'icon' 				: load("res://addons/dialogic/Editor/Images/Resources/portrait.svg")}, 
			'character != null and !has_no_portraits()')
	add_body_edit('text', ValueType.MultilineText)

func do_any_characters_exist() -> bool:
	return !DialogicUtil.list_resources_of_type(".dch").is_empty()

func has_no_portraits() -> bool:
	return character and character.portraits.is_empty()


func get_character_suggestions(search_text:String) -> Dictionary:
	var suggestions := {}
	
	#override the previous _character_directory with the meta, specifically for searching otherwise new nodes wont work
	_character_directory = Engine.get_meta('dialogic_character_directory')
	
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
