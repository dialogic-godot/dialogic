@tool
extends DialogicEvent
class_name DialogicTextEvent


var Text:String = ""
var Character : DialogicCharacter
var Portrait = ""

var _character_from_directory: String: 
	get:
		for item in _character_directory.keys():
			if _character_directory[item]['resource'] == Character:
				return item
				break
		return ""
	set(value): 
		_character_from_directory = value
		if value in _character_directory.keys():
			Character = _character_directory[value]['resource']

var _character_directory: Dictionary = {}

func _execute() -> void:
	if (not Character or Character.custom_info.get('theme', '').is_empty()) and dialogic.has_subsystem('Themes'):
		# if previous characters had a custom theme change back to base theme 
		if dialogic.current_state_info.get('base_theme') != dialogic.current_state_info.get('theme'):
			dialogic.Themes.change_theme(dialogic.current_state_info.get('base_theme', 'Default'))
	
	if Character:
		if dialogic.has_subsystem('Themes') and Character.custom_info.get('theme', null):
			dialogic.Themes.change_theme(Character.custom_info.theme)
		
		dialogic.Text.update_name_label(Character)
		
		if Portrait and dialogic.has_subsystem('Portraits') and dialogic.Portraits.is_character_joined(Character):
				dialogic.Portraits.change_portrait(Character, Portrait)
		var check_portrait = Portrait if !Portrait.is_empty() else dialogic.current_state_info['portraits'].get(Character.resource_path, {}).get('portrait', '')
		if check_portrait and Character.portraits.get(check_portrait, {}).get('sound_mood', '') in Character.custom_info.get('sound_moods', {}):
			dialogic.Text.update_typing_sound_mood(Character.custom_info.get('sound_moods', {}).get(Character.portraits[check_portrait].get('sound_mood', {}), {}))
		elif !Character.custom_info.get('sound_mood_default', '').is_empty():
			dialogic.Text.update_typing_sound_mood(Character.custom_info.get('sound_moods', {}).get(Character.custom_info.get('sound_mood_default')))
	else:
		dialogic.Text.update_name_label(null)
	
	# this will only do something if the rpg portrait mode is enabled
	if dialogic.has_subsystem('Portraits'):
		dialogic.Portraits.update_rpg_portrait_mode(Character, Portrait)
	
	#RENDER DIALOG
	#Placeholder wrap. Replace with a loop iterating over text event's lines. - KvaGram
	var index:int = 0
	if true:
		var final_text :String = get_translated_text()
		if dialogic.has_subsystem('VAR'):
			final_text = dialogic.VAR.parse_variables(final_text)
		if dialogic.has_subsystem('Glossary'):
			final_text = dialogic.Glossary.parse_glossary(final_text)
		
		dialogic.Text.update_dialog_text(dialogic.Text.color_names(final_text))
		
		#Plays the audio region for the current line.
		if dialogic.has_subsystem('Voice') and dialogic.Voice.is_voiced(dialogic.current_event_idx):
			dialogic.Voice.play_voice_region(index) #voice data is set by voice event.
		
		await dialogic.Text.text_finished
	
	#end of dialog
	if dialogic.has_subsystem('Choices') and dialogic.Choices.is_question(dialogic.current_event_idx):
		dialogic.Text.show_next_indicators(true)
		dialogic.Choices.show_current_choices()
		dialogic.current_state = dialogic.states.AWAITING_CHOICE
	elif DialogicUtil.get_project_setting('dialogic/text/autocontinue', false):
		dialogic.Text.show_next_indicators(false, true)
		var wait:float = DialogicUtil.get_project_setting('dialogic/text/autocontinue_delay', 1)
		# if voiced, grab remaining time left on the voiceed line's audio region - KvaGram
		if dialogic.has_subsystem('Voice') and dialogic.Voice.is_Voiced(dialogic.current_event_idx):
			#autocontinue settings is set as minimal. change or keep this? - Kvagram
			wait = max(wait, dialogic.Voice.getRemainingTime())
		await dialogic.get_tree().create_timer(wait).timeout
		dialogic.handle_next_event()
	else:
		dialogic.Text.show_next_indicators()
		finish()

func get_required_subsystems() -> Array:
	return [
				{'name':'Text',
				'subsystem': get_script().resource_path.get_base_dir().plus_file('Subsystem_Text.gd'),
				'settings': get_script().resource_path.get_base_dir().plus_file('Settings_DialogText.tscn'),
				'character_main':get_script().resource_path.get_base_dir().plus_file('CharacterEdit_TypingSounds.tscn')
				},
			]

################################################################################
## 						INITIALIZE
################################################################################

func _init() -> void:
	event_name = "Text"
	set_default_color('Color1')
	event_category = Category.MAIN
	event_sorting_index = 0
	help_page_path = "https://dialogic.coppolaemilio.com/documentation/Events/000/"
	continue_at_end = false

################################################################################
## 						SAVING/LOADING
################################################################################
## THIS RETURNS A READABLE REPRESENTATION, BUT HAS TO CONTAIN ALL DATA (This is how it's stored)
func get_as_string_to_store() -> String:
	if Character:
		var name = ""
		for path in _character_directory.keys():
			if _character_directory[path]['resource'] == Character:
				name = path
				break
		if name.count(" ") > 0:
			name = '"' + name + '"'
		if Portrait and not Portrait.is_empty():
			return name+" ("+Portrait+"): "+Text.replace("\n", "\\\n")
		return name+": "+Text.replace("\n", "\\\n")
	return Text.replace("\n", "\\\n")

## THIS HAS TO READ ALL THE DATA FROM THE SAVED STRING (see above) 
func load_from_string_to_store(string:String) -> void:
	_character_directory = {}
	if Engine.is_editor_hint() == false:
		_character_directory = Dialogic.character_directory
	else:
		_character_directory = self.get_meta("editor_character_directory")
	var reg := RegEx.new()
	
	# Reference regex without Godot escapes: ((")?(?<name>(?(2)[^"\n]*|[^(: \n]*))(?(2)"|)(\W*\((?<portrait>.*)\))?\s*(?<!\\):)?(?<text>.*)
	reg.compile("((\")?(?<name>(?(2)[^\"\\n]*|[^(: \\n]*))(?(2)\"|)(\\W*\\((?<portrait>.*)\\))?\\s*(?<!\\\\):)?(?<text>.*)")
	var result = reg.search(string)
	if result and !result.get_string('name').is_empty():
		var name = result.get_string('name').strip_edges()

		if _character_directory != null:
			if _character_directory.size() > 0:
				Character = null
				if _character_directory.has(name):
					Character = _character_directory[name]['resource']
				else:
					name = name.replace('"', "")
					# First do a full search to see if more of the path is there then necessary:
					for character in _character_directory:
						if name in _character_directory[character]['full_path']:
							Character = _character_directory[character]['resource']
							break								
					
					# If it doesn't exist,  at runtime we'll consider it a guest and create a temporary character
					if Character == null:
						if Engine.is_editor_hint() == false:
							Character = DialogicCharacter.new()
							Character.display_name = name
							var entry:Dictionary = {}
							entry['resource'] = Character
							entry['full_path'] = "runtime://" + name
							_character_directory[name] = entry
							
		if !result.get_string('portrait').is_empty():
			Portrait = result.get_string('portrait').strip_edges()
	
	if result:
		Text = result.get_string('text').replace("\\\n", "\n").strip_edges()

func is_valid_event_string(string):
	return true

func is_string_full_event(string:String) -> bool:
	return !string.ends_with('\\')

func can_be_translated():
	return true
	
func get_original_translation_text():
	return Text

func build_event_editor():
	add_header_edit('_character_from_directory', ValueType.ComplexPicker, 'Character:', '', {'file_extension':'.dch', 'suggestions_func':[self, 'get_character_suggestions'], 'empty_text':'(No one)','icon':load("res://addons/dialogic/Editor/Images/Resources/character.svg")})
	add_header_edit('Portrait', ValueType.ComplexPicker, '', '', {'suggestions_func':[self, 'get_portrait_suggestions'], 'placeholder':"Don't change", 'icon':load("res://addons/dialogic/Editor/Images/Resources/Portrait.svg")}, 'Character')
	add_body_edit('Text', ValueType.MultilineText)


func get_character_suggestions(search_text:String):
	var suggestions = {}
	var icon = load("res://addons/dialogic/Editor/Images/Resources/character.svg")
	print(search_text)
	suggestions['(No one)'] = {'value':'', 'editor_icon':["GuiRadioUnchecked", "EditorIcons"]}
	
	for resource in _character_directory.keys():
		if search_text == "" || resource.to_lower().contains(search_text.to_lower()):
			suggestions[resource] = {'value': resource, 'tooltip': _character_directory[resource]['full_path'], 'icon': icon.duplicate()}
	return suggestions
	

func get_portrait_suggestions(search_text):
	var suggestions = {}
	var icon = load("res://addons/dialogic/Editor/Images/Resources/Portrait.svg")
	suggestions["Don't change"] = {'value':'', 'editor_icon':["GuiRadioUnchecked", "EditorIcons"]}
	if Character != null:
		for portrait in Character.portraits:
			if search_text.is_empty() or search_text.to_lower() in portrait.to_lower():
				suggestions[portrait] = {'value':portrait, 'icon':icon}
	return suggestions
