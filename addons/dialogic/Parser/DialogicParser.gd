extends Node
class_name DialogicParser


# adds name coloring to the dialog texts
static func parse_characters(dialog_script):
	var characters = DialogicUtil.get_character_list()
	var event_index := 0
	for event in dialog_script['events']:
		# if this is a text or question event
		if event.get('event_id') in ['dialogic_001', 'dialogic_010']:
			var text :String = event.get({'dialogic_001':'text', 'dialogic_010':'question'}[event.get('event_id')], '')
			for character in characters:
				# check whether to use the name or the display name
				var char_names = [character.get('name')]
				if character.get('data', {}).get('display_name_bool', false):
					if character.get('display_name'): char_names.append(character.get('display_name'))
				if character.get('data', {}).get('nickname_bool', false):
					for nickname in character.get('data').get('nickname', '').split(',', true, 0):
						if nickname.strip_edges():
							char_names.append(nickname.strip_edges())
				
				#Regex purposefully excludes [] as replacing those interferes with the second regex
				var escapeRegExp = "(?=[+&|!(){}^\"~*.?:\\\\-])" 
				
				var regex = RegEx.new()
				regex.compile(escapeRegExp)
				char_names = regex.sub(str(char_names), "\\", true)
				
				var regex_thing = "((\\]|^)[^\\[]*)(?<name>"+str(char_names).replace("[", "(").replace("]", ")").replace(", ", "|")+")"
				regex.compile(regex_thing)
				
				var counter = 0
				for result in regex.search_all(text):
					text = text.insert(result.get_start("name")+((9+8+8)*counter), '[color=#' + character['color'].to_html() + ']')
					text = text.insert(result.get_end("name")+9+8+((9+8+8)*counter), '[/color]')
					result = regex.search(text)
					counter += 1
				
				dialog_script['events'][event_index][{'dialogic_001':'text', 'dialogic_010':'question'}[event.get('event_id')]] = text
		
		event_index += 1

	return dialog_script


# removes empty lines, splits message at new lines
static func parse_text_lines(unparsed_dialog_script: Dictionary, preview:bool = false) -> Dictionary:
	var parsed_dialog: Dictionary = unparsed_dialog_script
	var new_events: Array = []
	var settings = DialogicResources.get_settings_config()
	var split_new_lines = settings.get_value('dialog', 'new_lines', true)
	var remove_empty_messages = settings.get_value('dialog', 'remove_empty_messages', true)

	# Return the same thing if it doesn't have events
	if unparsed_dialog_script.has('events') == false:
		return unparsed_dialog_script

	# Parsing
	for event in unparsed_dialog_script['events']:
		if event.has('text') and event.has('character') and event.has('portrait'):
			if event['text'].empty() and remove_empty_messages:
				pass
			elif '\n' in event['text'] and preview == false and split_new_lines:
				var lines = event['text'].split('\n')
				var counter = 0 
				for line in lines:
					if not line.empty():
						var n_event = {
							'event_id':'dialogic_001',
							'text': line,
							'character': event['character'],
							'portrait': event['portrait'],
						}
						#assigning voices to the new events 
						if event.has('voice_data'):
							if event['voice_data'].has(str(counter)):
								n_event['voice_data'] = {'0':event['voice_data'][str(counter)]}
						new_events.append(n_event)
					counter += 1 
			else:
				new_events.append(event)
		else:
			new_events.append(event)

	parsed_dialog['events'] = new_events

	return parsed_dialog


# returns the text but with BBcode for glossary and the values of the variables
static func parse_definitions(current_dialog, text: String, variables: bool = true, glossary: bool = true):
	var final_text: String = text
	if not current_dialog.preview:
		current_dialog.definitions = Dialogic._get_definitions()
	if variables:
		final_text = _insert_variable_definitions(current_dialog, text)
	if glossary and current_dialog._should_show_glossary():
		final_text = _insert_glossary_definitions(current_dialog, final_text)
	return final_text


# creates a list of questions to be used at the end of choices
static func parse_branches(current_dialog, dialog_script: Dictionary) -> Dictionary:
	current_dialog.questions = [] # Resetting the questions

	# Return the same thing if it doesn't have events
	if dialog_script.has('events') == false:
		return dialog_script

	var parser_queue = [] # This saves the last question opened, and it gets removed once it was consumed by a endbranch event
	var event_idx: int = 0 # The current id for jumping later on
	var question_idx: int = 0 # identifying the questions to assign options to it
	for event in dialog_script['events']:
		if event['event_id'] == 'dialogic_011':
			var opened_branch = parser_queue.back()
			var option = {
				'question_idx': opened_branch['question_idx'],
				'label': parse_definitions(current_dialog, event['choice'], true, false),
				'event_idx': event_idx,
				}
			if event.has('condition') and event.has('definition') and event.has('value'):
				option = {
					'question_idx': opened_branch['question_idx'],
					'label': parse_definitions(current_dialog, event['choice'], true, false),
					'event_idx': event_idx,
					'condition': event['condition'],
					'definition': event['definition'],
					'value': event['value'],
					}
			else:
				option = {
					'question_idx': opened_branch['question_idx'],
					'label': parse_definitions(current_dialog, event['choice'], true, false),
					'event_idx': event_idx,
					'condition': '',
					'definition': '',
					'value': '',
					}
			dialog_script['events'][opened_branch['event_idx']]['options'].append(option)
			event['question_idx'] = opened_branch['question_idx']
		elif event['event_id'] == 'dialogic_010':
			event['event_idx'] = event_idx
			event['question_idx'] = question_idx
			event['answered'] = false
			question_idx += 1
			current_dialog.questions.append(event)
			parser_queue.append(event)
		elif event['event_id'] == 'dialogic_012':
			event['event_idx'] = event_idx
			event['question_idx'] = question_idx
			event['answered'] = false
			question_idx += 1
			current_dialog.questions.append(event)
			parser_queue.append(event)
		elif event['event_id'] == 'dialogic_013' and parser_queue:
			event['event_idx'] = event_idx
			var opened_branch = parser_queue.pop_back()
			event['end_branch_of'] = opened_branch['question_idx']
			dialog_script['events'][opened_branch['event_idx']]['end_idx'] = event_idx
		event_idx += 1

	return dialog_script


static func parse_anchors(current_dialog):
	current_dialog.anchors = {}
	var idx = 0
	for event in current_dialog.dialog_script['events']:
		if event['event_id'] == 'dialogic_015':
			current_dialog.anchors[event['id']] = idx
		idx += 1


# adds the alignment BBCode to text events
static func parse_alignment(current_dialog, text):
	var alignment = current_dialog.current_theme.get_value('text', 'alignment', 0)
	var fname = current_dialog.current_theme.get_value('settings', 'name', 'none')
	if alignment in [1,4,7]:
		text = '[center]' + text + '[/center]'
	elif alignment in [2,5,8]:
		text = '[right]' + text + '[/right]'
	return text


# adds the values of the variables
static func _insert_variable_definitions(current_dialog, text: String):
	var final_text := text;
	
	# Regex for searching text inside brackets []
	var regex = RegEx.new()
	regex.compile('\\[(.*?)\\]')
	var result = regex.search_all(final_text)
	if result:
		for res in result:
			var r_string = res.get_string()
			# Choosing a random word if there is a list like [word1,word2,word3,word4]
			if ',' in r_string:
				var r_string_array = r_string.replace('[', '').replace(']', '').split(',')
				var new_word = r_string_array[randi() % r_string_array.size()]
				# Check if the random selected word is a variable that exists and get the value
				for d in current_dialog.definitions['variables']:
					var name : String = d['name']
					if new_word == d['name']:
						new_word = str(d['value'])
				# Replace the old string with the new word
				final_text = final_text.replace(r_string, new_word)
			else:
				# Replace the name of a value [whatever] with the result
				var r_string_array = r_string.replace('[', '').replace(']', '')
				
				# Find the ID if it's got an absolute path
				if '/' in r_string_array:
					var variable_id=Dialogic._get_variable_from_file_name(r_string_array)
					for d in current_dialog.definitions['variables']:
						if d['id'] == variable_id:
							final_text = final_text.replace(r_string, d['value'])
				else:					
					for d in current_dialog.definitions['variables']:
						if d['name'] == r_string_array:
							final_text = final_text.replace(r_string, d['value'])
	
	return final_text

# adds the BBCode for the glossary words
static func _insert_glossary_definitions(current_dialog, text: String):
	var color = current_dialog.current_theme.get_value('definitions', 'color', '#ffbebebe')
	var final_text := text
	# I should use regex here, but this is way easier :)
	for d in current_dialog.definitions['glossary']:
		final_text = final_text.replace(d['name'],
			'[url=' + d['id'] + ']' +
			'[color=' + color + ']' + d['name'] + '[/color]' +
			'[/url]'
		)
	return final_text
