@tool
extends DialogicEvent
class_name DialogicTextEvent


var Text:String = ""
var Character:DialogicCharacter
var Portrait = ""

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
		if Character.portraits.get(check_portrait, {}).get('sound_mood', '') in Character.custom_info.get('sound_moods', {}):
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
		if dialogic.has_subsystem('VAR'):
			dialogic.Text.update_dialog_text(dialogic.Text.color_names(dialogic.VAR.parse_variables(get_translated_text())))
		else:
			dialogic.Text.update_dialog_text(dialogic.Text.color_names(get_translated_text()))
		
		#Plays the audio region for the current line.
		if dialogic.has_subsystem('Voice') and dialogic.Voice.isVoiced(dialogic.current_event_idx):
			dialogic.Voice.playVoiceRegion(index) #voice data is set by voice event.
		
		# Wait for text to finish revealing
		while true:
			await dialogic.state_changed
			if dialogic.current_state == dialogic.states.IDLE:
				break
	#end of dialog
	
	if dialogic.has_subsystem('Choices') and dialogic.Choices.is_question(dialogic.current_event_idx):
		dialogic.Choices.show_current_choices()
		dialogic.current_state = dialogic.states.AWAITING_CHOICE
	elif DialogicUtil.get_project_setting('dialogic/text/autocontinue', false):
		var wait:float = DialogicUtil.get_project_setting('dialogic/text/autocontinue_delay', 1)
		# if voiced, grab remaining time left on the voiceed line's audio region - KvaGram
		if dialogic.has_subsystem('Voice') and dialogic.Voice.is_Voiced(dialogic.current_event_idx):
			#autocontinue settings is set as minimal. change or keep this? - Kvagram
			wait = max(wait, dialogic.Voice.getRemainingTime())
		await dialogic.get_tree().create_timer(wait).timeout
		dialogic.handle_next_event()
	else:
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
		if Portrait and not Portrait.is_empty():
			return Character.name+" ("+Portrait+"): "+Text.replace("\n", "\\\n")
		return Character.name+": "+Text.replace("\n", "\\\n")
	return Text.replace("\n", "\\\n")

## THIS HAS TO READ ALL THE DATA FROM THE SAVED STRING (see above) 
func load_from_string_to_store(string:String):
	var reg = RegEx.new()
	reg.compile("((?<name>[^:()\\n]*)?(?=(\\([^()]*\\))?:)(\\((?<portrait>[^()]*)\\))?)?:?(?<text>(.|(?<=\\\\)\\n)+)")
	var result = reg.search(string)
	if result and !result.get_string('name').is_empty():
		var character = DialogicUtil.guess_resource('.dch', result.get_string('name').strip_edges())
		if character:
			Character = load(character)
		else:
			Character = null
			#print("When importing timeline, we couldn't identify what character you meant with ", result.get_string('name'), ".")
		if !result.get_string('portrait').is_empty():
			Portrait = result.get_string('portrait').strip_edges()
	
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
	add_header_edit('Character', ValueType.ComplexPicker, 'Character:', '', {'file_extension':'.dch','suggestions_func':[self, 'get_character_suggestions'], 'empty_text':'Noone','icon':load("res://addons/dialogic/Editor/Images/Resources/character.svg")})
	add_header_edit('Portrait', ValueType.ComplexPicker, '', '', {'suggestions_func':[self, 'get_portrait_suggestions'], 'placeholder':"Don't change", 'icon':load("res://addons/dialogic/Editor/Images/Resources/Portrait.svg")}, 'Character')
	add_body_edit('Text', ValueType.MultilineText)


func get_character_suggestions(search_text:String):
	var suggestions = {}
	var resources = DialogicUtil.list_resources_of_type('.dch')
	suggestions['Noone'] = {'value':'', 'editor_icon':["GuiRadioUnchecked", "EditorIcons"]}
	
	for resource in resources:
		if search_text.is_empty() or search_text.to_lower() in DialogicUtil.pretty_name(resource).to_lower():
			suggestions[DialogicUtil.pretty_name(resource)] = {'value':resource, 'tooltip':resource, 'icon':load("res://addons/dialogic/Editor/Images/Resources/character.svg")}
	return suggestions

func get_portrait_suggestions(search_text):
	var suggestions = {}
	suggestions["Don't change"] = {'value':'', 'editor_icon':["GuiRadioUnchecked", "EditorIcons"]}
	if Character != null:
		for portrait in Character.portraits:
			if search_text.is_empty() or search_text.to_lower() in portrait.to_lower():
				suggestions[portrait] = {'value':portrait, 'icon':load("res://addons/dialogic/Editor/Images/Resources/Portrait.svg")}
	return suggestions
