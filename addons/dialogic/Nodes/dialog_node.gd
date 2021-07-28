tool
extends Control

var last_mouse_mode = null
var input_next: String = 'ui_accept'
var dialog_index: int = 0
var finished: bool = false
var waiting_for_answer: bool = false
var waiting_for_input: bool = false
var waiting: bool = false
var preview: bool = false
var definitions: Dictionary = {}
var definition_visible: bool = false
var while_dialog_animation: bool = false

var settings: ConfigFile
var current_theme: ConfigFile
var current_timeline: String = ''
var current_event: Dictionary

## The timeline to load when starting the scene
export(String, "TimelineDropdown") var timeline: String
## Should we clear saved data (definitions and timeline progress) on start?
export(bool) var reset_saves = true
## Should we show debug information when running?
export(bool) var debug_mode = true

# Event end/start
signal event_start(type, event)
signal event_end(type)
# Timeline end/start
signal timeline_start(timeline_name)
signal timeline_end(timeline_name)
# Custom user signal
signal dialogic_signal(value)

var dialog_resource
var characters

onready var ChoiceButton = load("res://addons/dialogic/Nodes/ChoiceButton.tscn")
onready var Portrait = load("res://addons/dialogic/Nodes/Portrait.tscn")
onready var Background = load("res://addons/dialogic/Nodes/Background.tscn")
var dialog_script: Dictionary = {}
var questions #for keeping track of the questions answered


func _ready():
	# Loading the config files
	load_config_files()
	
	# Checking if the dialog should read the code from a external file
	if not timeline.empty():
		set_current_dialog(timeline)
	elif dialog_script.keys().size() == 0:
		dialog_script = {
			"events":[
				{'event_id':'dialogic_001',
				"character":"","portrait":"",
				"text":"[Dialogic Error] No timeline specified."}]
		}
	# Load the dialog directly from GDscript
	else:
		load_dialog()
	
	# Connecting resize signal
	get_viewport().connect("size_changed", self, "resize_main")
	resize_main()
	
	# Connecting some other timers
	$OptionsDelayedInput.connect("timeout", self, '_on_OptionsDelayedInput_timeout')

	# Setting everything up for the node to be default
	$DefinitionInfo.visible = false
	$TextBubble.connect("text_completed", self, "_on_text_completed")
	$TextBubble/RichTextLabel.connect('meta_hover_started', self, '_on_RichTextLabel_meta_hover_started')
	$TextBubble/RichTextLabel.connect('meta_hover_ended', self, '_on_RichTextLabel_meta_hover_ended')
	
	# Getting the character information
	characters = DialogicUtil.get_character_list()

	if Engine.is_editor_hint():
		if preview:
			get_parent().connect("resized", self, "resize_main")
			_init_dialog()
			$DefinitionInfo.in_theme_editor = true
	else:
		# Calls _init_dialog() after animation is over
		open_dialog_animation(current_theme.get_value('animation', 'show_time', 0.5)) 


func load_config_files():
	if not Engine.is_editor_hint():
		if reset_saves:
			DialogicUtil.get_singleton('DialogicSingleton', self).init(reset_saves)
		definitions = DialogicUtil.get_singleton('DialogicSingleton', self).get_definitions()
	else:
		definitions = DialogicResources.get_default_definitions()
	settings = DialogicResources.get_settings_config()
	var theme_file = 'res://addons/dialogic/Editor/ThemeEditor/default-theme.cfg'
	if settings.has_section('theme'):
		theme_file = settings.get_value('theme', 'default')
	current_theme = load_theme(theme_file)


func resize_main():
	# This function makes sure that the dialog is displayed at the correct
	# size and position in the screen.
	var reference = rect_size
	if not Engine.is_editor_hint():
		set_global_position(Vector2(0,0))
		reference = get_viewport().get_visible_rect().size

	$Options.rect_position.x = (reference.x / 2) - ($Options.rect_size.x / 2)
	$Options.rect_position.y = (reference.y / 2) - ($Options.rect_size.y / 2)
	
	$TextBubble.rect_position.x = (reference.x / 2) - ($TextBubble.rect_size.x / 2)
	if current_theme != null:
		$TextBubble.rect_position.y = (reference.y) - ($TextBubble.rect_size.y) - current_theme.get_value('box', 'bottom_gap', 40)
	
	
	var pos_x = 0
	if current_theme.get_value('background', 'full_width', false):
		if preview:
			pos_x = get_parent().rect_global_position.x
		$TextBubble/TextureRect.rect_global_position.x = pos_x
		$TextBubble/ColorRect.rect_global_position.x = pos_x
		$TextBubble/TextureRect.rect_size.x = reference.x
		$TextBubble/ColorRect.rect_size.x = reference.x
	else:
		$TextBubble/TextureRect.rect_global_position.x = $TextBubble.rect_global_position.x
		$TextBubble/ColorRect.rect_global_position.x = $TextBubble.rect_global_position.x
		$TextBubble/TextureRect.rect_size.x = $TextBubble.rect_size.x
		$TextBubble/ColorRect.rect_size.x = $TextBubble.rect_size.x
	
	var background = get_node_or_null('Background')
	if background != null:
		background.rect_size = reference
	
	var portraits = get_node_or_null('Portraits')
	if portraits != null:
		portraits.rect_position.x = reference.x / 2
		portraits.rect_position.y = reference.y


func set_current_dialog(dialog_path: String):
	current_timeline = dialog_path
	dialog_script = DialogicResources.get_timeline_json(dialog_path)
	return load_dialog()
	
	
func load_dialog():
	# All this parse events should be happening in the same loop ideally
	# But until performance is not an issue I will probably stay lazy
	# And keep adding different functions for each parsing operation.
	if settings.has_section_key('dialog', 'auto_color_names'):
		if settings.get_value('dialog', 'auto_color_names'):
			dialog_script = parse_characters(dialog_script)
	else:
		dialog_script = parse_characters(dialog_script)
	dialog_script = parse_text_lines(dialog_script)
	dialog_script = parse_branches(dialog_script)
	return dialog_script


func parse_characters(dialog_script):
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
					char_names.append(character.get('display_name'))
				if character.get('data', {}).get('nickname_bool', false):
					for nickname in character.get('data').get('nickname', '').split(',', true, 0):
						char_names.append(nickname.strip_edges())
				
				var regex_thing = str(char_names).replace("[", "(").replace("]", ")").replace(", ", "|")+'\\b'
				var regex = RegEx.new()
				regex.compile(regex_thing)
				
				var counter = 0
				for result in regex.search_all(text):
					text = text.insert(result.get_start()+((9+8+8)*counter), '[color=#' + character['color'].to_html() + ']')
					text = text.insert(result.get_end()+9+8+((9+8+8)*counter), '[/color]')
					result = regex.search(text)
					counter += 1
				dialog_script['events'][event_index][{'dialogic_001':'text', 'dialogic_010':'question'}[event.get('event_id')]] = text
		
		event_index += 1

	return dialog_script


func parse_text_lines(unparsed_dialog_script: Dictionary) -> Dictionary:
	var parsed_dialog: Dictionary = unparsed_dialog_script
	var new_events: Array = []
	var split_new_lines = true
	var remove_empty_messages = true

	# Return the same thing if it doesn't have events
	if unparsed_dialog_script.has('events') == false:
		return unparsed_dialog_script

	# Getting extra settings
	if settings.has_section_key('dialog', 'remove_empty_messages'):
		remove_empty_messages = settings.get_value('dialog', 'remove_empty_messages')
	if settings.has_section_key('dialog', 'new_lines'):
		split_new_lines = settings.get_value('dialog', 'new_lines')

	# Parsing
	for event in unparsed_dialog_script['events']:
		if event.has('text') and event.has('character') and event.has('portrait'):
			if event['text'].empty() and remove_empty_messages == true:
				pass
			elif '\n' in event['text'] and preview == false and split_new_lines == true:
				var lines = event['text'].split('\n')
				for line in lines:
					if not line.empty():
						new_events.append({
							'event_id':'dialogic_001',
							'text': line,
							'character': event['character'],
							'portrait': event['portrait']
						})
			else:
				new_events.append(event)
		else:
			new_events.append(event)

	parsed_dialog['events'] = new_events

	return parsed_dialog


func parse_alignment(text):
	var alignment = current_theme.get_value('text', 'alignment', 'Left')
	var fname = current_theme.get_value('settings', 'name', 'none')
	if alignment == 'Center':
		text = '[center]' + text + '[/center]'
	elif alignment == 'Right':
		text = '[right]' + text + '[/right]'
	return text


func parse_branches(dialog_script: Dictionary) -> Dictionary:
	questions = [] # Resetting the questions

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
				'label': parse_definitions(event['choice'], true, false),
				'event_idx': event_idx,
				}
			if event.has('condition') and event.has('definition') and event.has('value'):
				option = {
					'question_idx': opened_branch['question_idx'],
					'label': parse_definitions(event['choice'], true, false),
					'event_idx': event_idx,
					'condition': event['condition'],
					'definition': event['definition'],
					'value': event['value'],
					}
			else:
				option = {
					'question_idx': opened_branch['question_idx'],
					'label': parse_definitions(event['choice'], true, false),
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
			questions.append(event)
			parser_queue.append(event)
		elif event['event_id'] == 'dialogic_012':
			event['event_idx'] = event_idx
			event['question_idx'] = question_idx
			event['answered'] = false
			question_idx += 1
			questions.append(event)
			parser_queue.append(event)
		elif event['event_id'] == 'dialogic_013':
			event['event_idx'] = event_idx
			var opened_branch = parser_queue.pop_back()
			event['end_branch_of'] = opened_branch['question_idx']
			dialog_script['events'][opened_branch['event_idx']]['end_idx'] = event_idx
		event_idx += 1

	return dialog_script


func _should_show_glossary():
	if current_theme != null:
		return current_theme.get_value('definitions', 'show_glossary', true)
	return true


func parse_definitions(text: String, variables: bool = true, glossary: bool = true):
	var final_text: String = text
	if not preview:
		definitions = DialogicUtil.get_singleton('DialogicSingleton', self).get_definitions()
	if variables:
		final_text = _insert_variable_definitions(text)
	if glossary and _should_show_glossary():
		final_text = _insert_glossary_definitions(final_text)
	return final_text


func _insert_variable_definitions(text: String):
	var final_text := text;
	for d in definitions['variables']:
		var name : String = d['name'];
		final_text = final_text.replace('[' + name + ']', d['value'])
	return final_text;
	
	
func _insert_glossary_definitions(text: String):
	var color = current_theme.get_value('definitions', 'color', '#ffbebebe')
	var final_text := text;
	# I should use regex here, but this is way easier :)
	for d in definitions['glossary']:
		final_text = final_text.replace(d['name'],
			'[url=' + d['id'] + ']' +
			'[color=' + color + ']' + d['name'] + '[/color]' +
			'[/url]'
		)
	return final_text;


func _process(delta):
	$TextBubble/NextIndicatorContainer/NextIndicator.visible = finished
	if $Options.get_child_count() > 0:
		$TextBubble/NextIndicatorContainer/NextIndicator.visible = false # Hide if question 
		if waiting_for_answer and Input.is_action_just_released(input_next):
			$Options.get_child(0).grab_focus()
	
	# Hide if no input is required
	if current_event.has('text'):
		if '[nw]' in current_event['text'] or '[nw=' in current_event['text']:
			$TextBubble/NextIndicatorContainer/NextIndicator.visible = false
	
	# Hide if fading in
	if while_dialog_animation:
		$TextBubble/NextIndicatorContainer/NextIndicator.visible = false


func _input(event: InputEvent) -> void:
	if not Engine.is_editor_hint() and event.is_action_pressed(input_next) and not waiting:
		if not $TextBubble.is_finished():
			# Skip to end if key is pressed during the text animation
			$TextBubble.skip()
		else:
			if waiting_for_answer == false and waiting_for_input == false and while_dialog_animation == false:
				_load_next_event()
		if settings.has_section_key('dialog', 'propagate_input'):
			var propagate_input: bool = settings.get_value('dialog', 'propagate_input')
			if not propagate_input:
				get_tree().set_input_as_handled()


func show_dialog():
	visible = true


func set_dialog_script(value):
	dialog_script = value


func update_name(character) -> void:
	if character.has('name'):
		var parsed_name = character['name']
		if character.has('display_name'):
			if character['display_name'] != '':
				parsed_name = character['display_name']
		parsed_name = parse_definitions(parsed_name, true, false)
		$TextBubble.update_name(parsed_name, character.get('color', Color.white), current_theme.get_value('name', 'auto_color', true))
	else:
		$TextBubble.update_name('')


func update_text(text: String) -> String:
	if settings.has_section_key('dialog', 'translations') and settings.get_value('dialog', 'translations'):
		text = tr(text)
	var final_text = parse_definitions(parse_alignment(text))
	final_text = final_text.replace('[br]', '\n')

	$TextBubble.update_text(final_text)
	return final_text


func _on_text_completed():
	finished = true
	
	var waiting_until_options_enabled = float(settings.get_value('input', 'delay_after_options', 0.1))
	$OptionsDelayedInput.start(waiting_until_options_enabled)
		
	if current_event.has('options'):
		for o in current_event['options']:
			add_choice_button(o)
	if current_event.has('text'):
		# [p] needs more work
		#if '[p]' in current_event['text']: 
		#	yield(get_tree().create_timer(2), "timeout")
		
		# Setting the timer for how long to wait in the [nw] events
		if '[nw]' in current_event['text'] or '[nw=' in current_event['text']:
			var waiting_time = 2
			var current_index = dialog_index
			if '[nw=' in current_event['text']: # Regex stuff
				var regex = RegEx.new()
				regex.compile("\\[nw=(.+?)\\](.*?)")
				var result = regex.search(current_event['text'])
				var wait_settings = result.get_string()
				waiting_time = float(wait_settings.split('=')[1])
			
			yield(get_tree().create_timer(waiting_time), "timeout")
			if dialog_index == current_index:
				_load_next_event()



func on_timeline_start():
	if not Engine.is_editor_hint():
		if settings.get_value('saving', 'save_definitions_on_start', true):
			DialogicUtil.get_singleton('DialogicSingleton', self).save_definitions()
		if settings.get_value('saving', 'save_current_timeline', true):
			DialogicUtil.get_singleton('DialogicSingleton', self).set_current_timeline(current_timeline)
	# TODO remove event_start in 2.0
	emit_signal("event_start", "timeline", current_timeline)
	emit_signal("timeline_start", current_timeline)


func on_timeline_end():
	if not Engine.is_editor_hint():
		if settings.get_value('saving', 'save_definitions_on_end', true):
			DialogicUtil.get_singleton('DialogicSingleton', self).save_definitions()
		if settings.get_value('saving', 'clear_current_timeline', true):
			DialogicUtil.get_singleton('DialogicSingleton', self).set_current_timeline('')
	# TODO remove event_end in 2.0
	emit_signal("event_end", "timeline")
	emit_signal("timeline_end", current_timeline)
	dprint('[D] Timeline End')


func _init_dialog():
	dialog_index = 0
	_load_event()


func _load_event_at_index(index: int):
	dialog_index = index
	_load_event()


func _load_next_event():
	dialog_index += 1
	_load_event()


func _is_dialog_starting():
	return dialog_index == 0


func _is_dialog_finished():
	return dialog_index >= dialog_script['events'].size()


func _load_event():
	_emit_timeline_signals()
	_hide_definition_popup()
	
	if dialog_script.has('events'):
		if not _is_dialog_finished():
			var func_state = event_handler(dialog_script['events'][dialog_index])
			if (func_state is GDScriptFunctionState):
				yield(func_state, "completed")
		elif not Engine.is_editor_hint():
			# Do not free the dialog if we are in the preview
			queue_free()


func _emit_timeline_signals():
	if dialog_script.has('events'):
		if _is_dialog_starting():
			on_timeline_start()
		elif _is_dialog_finished():
			on_timeline_end()


func _hide_definition_popup():
	definition_visible = false
	$DefinitionInfo.visible = definition_visible


func get_character(character_id):
	for c in characters:
		if c['file'] == character_id:
			return c
	return {}


func event_handler(event: Dictionary):
	# Handling an event and updating the available nodes accordingly.
	$TextBubble.reset()
	reset_options()
	
	dprint('[D] Current Event: ', event)
	current_event = event
	match event['event_id']:
		# MAIN EVENTS
		# Text Event
		'dialogic_001':
			emit_signal("event_start", "text", event)
			show_dialog()
			finished = false
			if event.has('character'):
				var character_data = get_character(event['character'])
				update_name(character_data)
				grab_portrait_focus(character_data, event)
			update_text(event['text'])
		# Join event
		'dialogic_002':
			## PLEASE UPDATE THIS! BUT HOW? 
			emit_signal("event_start", "action", event)
			if event['character'] == '':# No character found on the event. Skip.
				_load_next_event()
			else:
				var character_data = get_character(event['character'])
				var exists = grab_portrait_focus(character_data)
				if exists:
					for portrait in $Portraits.get_children():
						if portrait.character_data == character_data:
							portrait.move_to_position(get_character_position(event['position']))
							portrait.set_mirror(event.get('mirror', false))
				else:
					var p = Portrait.instance()
					var char_portrait = event['portrait']
					if char_portrait == '':
						char_portrait = 'Default'
					
					if char_portrait == '[Definition]' and event.has('port_defn'):
						var portrait_definition = event['port_defn']
						if portrait_definition != '':
							for d in DialogicResources.get_default_definitions()['variables']:
								if d['id'] == portrait_definition:
									char_portrait = d['value']
									break
					
					if current_theme.get_value('settings', 'single_portrait_mode', false):
						p.single_portrait_mode = true
					p.character_data = character_data
					p.init(char_portrait)
					p.set_mirror(event.get('mirror', false))
					$Portraits.add_child(p)
					p.move_to_position(get_character_position(event['position']))
			_load_next_event()
		# Character Leave event 
		'dialogic_003':
			## PLEASE UPDATE THIS! BUT HOW? 
			emit_signal("event_start", "action", event)
			if event['character'] == '[All]':
				characters_leave_all()
			else:
				for p in $Portraits.get_children():
					if p.character_data['file'] == event['character']:
						p.fade_out()
			_load_next_event()
		
		# LOGIC EVENTS
		# Question event
		'dialogic_010':
			emit_signal("event_start", "question", event)
			show_dialog()
			finished = false
			waiting_for_answer = true
			if event.has('name'):
				update_name(event['name'])
			elif event.has('character'):
				var character_data = get_character(event['character'])
				update_name(character_data)
				grab_portrait_focus(character_data, event)
			update_text(event['question'])
		# Choice event
		'dialogic_011':
			emit_signal("event_start", "choice", event)
			for q in questions:
				if q['question_idx'] == event['question_idx']:
					if q['answered']:
						# If the option is for an answered question, skip to the end of it.
						_load_event_at_index(q['end_idx'])
		# Condition event
		'dialogic_012':
			# Treating this conditional as an option on a regular question event
			var def_value = null
			var current_question = questions[event['question_idx']]
			
			for d in definitions['variables']:
				if d['id'] == event['definition']:
					def_value = d['value']
			
			var condition_met = def_value != null and _compare_definitions(def_value, event['value'], event['condition']);
			
			current_question['answered'] = !condition_met
			if !condition_met:
				# condition not met, skipping branch
				_load_event_at_index(current_question['end_idx'])
			else:
				# condition met, entering branch
				_load_next_event()
		# End Branch event
		'dialogic_013':
			emit_signal("event_start", "endbranch", event)
			_load_next_event()
		# Set Value event
		'dialogic_014':
			emit_signal("event_start", "set_value", event)
			var operation = '='
			if 'operation' in event and not event['operation'].empty():
				operation = event["operation"]
			var value = event['set_value']
			if event.get('set_random', false):
				value = str(randi()%int(event.get("random_upper_limit", 100)-event.get('random_lower_limit', 0))+event.get('random_lower_limit', 0))
			DialogicUtil.get_singleton('DialogicSingleton', self).set_variable_from_id(event['definition'], value, operation)
			_load_next_event()
		
		# TIMELINE EVENTS
		# Change Timeline event
		'dialogic_020':
			dialog_script = set_current_dialog(event['change_timeline'])
			_init_dialog()
		# Change Backround event
		'dialogic_021':
			emit_signal("event_start", "background", event)
			var fade_time = event.get('fade_duration', 1)
			var value = event.get('background', '')
			var background = get_node_or_null('Background')
			
			if background != null:
				background.name = 'BackgroundFadingOut'
				background.fade_out(fade_time)
			
			background = Background.instance()
			background.name = 'Background'
			
			if value != '':
				add_child(background)
				background.create_tween()
				if value.ends_with('.tscn'):
					var bg_scene = load(event['background'])
					bg_scene = bg_scene.instance()
					background.modulate = Color(1,1,1,0)
					background.fade_in(fade_time)
					background.add_child(bg_scene)
				else:
					background.texture = load(value)
					background.create_tween()
					background.fade_in(fade_time)
				call_deferred('resize_main') # Executing the resize main to update the background size

			_load_next_event()
		# Close Dialog event
		'dialogic_022':
			emit_signal("event_start", "close_dialog", event)
			var transition_duration = event.get('transition_duration', 1.0)
			transition_duration = transition_duration
			close_dialog_event(transition_duration)
			while_dialog_animation = true
			var background = get_node_or_null('Background')
			if background != null:
				background.name = 'BackgroundFadingOut'
				background.fade_out(transition_duration)
		# Wait seconds event
		'dialogic_023':
			emit_signal("event_start", "wait", event)
			$TextBubble.visible = false
			waiting = true
			yield(get_tree().create_timer(event['wait_seconds']), "timeout")
			waiting = false
			$TextBubble.visible = true
			emit_signal("event_end", "wait")
			_load_next_event()
		# Set Theme event
		'dialogic_024':
			emit_signal("event_start", "set_theme", event)
			if event['set_theme'] != '':
				current_theme = load_theme(event['set_theme'])
			_load_next_event()
		
		# Set Glossary event
		'dialogic_025':
			emit_signal("event_start", "set_glossary", event)
			if event['glossary_id']:
				DialogicUtil.get_singleton('DialogicSingleton', self).set_glossary_from_id(event['glossary_id'], event['title'], event['text'],event['extra'])
			_load_next_event()
		# AUDIO EVENTS
		# Audio event
		'dialogic_030':
			emit_signal("event_start", "audio", event)
			if event['audio'] == 'play' and 'file' in event.keys() and not event['file'].empty():
				var audio = get_node_or_null('AudioEvent')
				if audio == null:
					audio = AudioStreamPlayer.new()
					audio.name = 'AudioEvent'
					add_child(audio)
				if event.has('audio_bus'):
					if AudioServer.get_bus_index(event['audio_bus']) >= 0:
						audio.bus = event['audio_bus']
				if event.has('volume'):
					audio.volume_db = event['volume']
				audio.stream = load(event['file'])
				audio.play()
			else:
				var audio = get_node_or_null('AudioEvent')
				if audio != null:
					audio.stop()
					audio.queue_free()
			_load_next_event()
		# Background Music event
		'dialogic_031':
			emit_signal("event_start", "background-music", event)
			if event['background-music'] == 'play' and 'file' in event.keys() and not event['file'].empty():
				$FX/BackgroundMusic.crossfade_to(event['file'], event.get('audio_bus', 'Master'), event.get('volume', 0), event.get('fade_length', 1))
			else:
				$FX/BackgroundMusic.fade_out(event.get('fade_length', 1))
			_load_next_event()
		
		# GODOT EVENTS
		# Emit signal event
		'dialogic_040':
			dprint('[!] Emitting signal: dialogic_signal(', event['emit_signal'], ')')
			emit_signal("dialogic_signal", event['emit_signal'])
			_load_next_event()
		# Change Scene event
		'dialogic_041':
			if event.has('scene'):
				get_tree().change_scene(event['scene'])
			elif event.has('change_scene'):
				get_tree().change_scene(event['change_scene'])
		# Call Node event
		'dialogic_042':
			dprint('[!] Call Node signal: dialogic_signal(call_node) ', var2str(event['call_node']))
			emit_signal("event_start", "call_node", event)
			$TextBubble.visible = false
			waiting = true
			var target = get_node_or_null(event['call_node']['target_node_path'])
			if not target:
				target = get_tree().root.get_node_or_null(event['call_node']['target_node_path'])
			var method_name = event['call_node']['method_name']
			var args = event['call_node']['arguments']
			if (not args is Array):
				args = []

			if (target != null):
				if (target.has_method(method_name)):
					if (args.empty()):
						var func_result = target.call(method_name)
						if (func_result is GDScriptFunctionState):
							yield(func_result, "completed")
					else:
						var func_result = target.call(method_name, args)
						if (func_result is GDScriptFunctionState):
							yield(func_result, "completed")

			waiting = false
			$TextBubble.visible = true
			_load_next_event()
		_:
			visible = false
			dprint('[D] Other event. ', event)
	
	$Options.visible = waiting_for_answer


func reset_options():
	# Clearing out the options after one was selected.
	for option in $Options.get_children():
		option.queue_free()


func _should_add_choice_button(option: Dictionary):
	if not option['definition'].empty():
		var def_value = null
		for d in definitions['variables']:
			if d['id'] == option['definition']:
				def_value = d['value']
		return def_value != null and _compare_definitions(def_value, option['value'], option['condition']);
	else:
		return true


func use_custom_choice_button():
	return current_theme.get_value('buttons', 'use_custom', false) and not current_theme.get_value('buttons', 'custom_path', "").empty()


func use_native_choice_button():
	return current_theme.get_value('buttons', 'use_native', false)


func get_custom_choice_button(label: String):
	var theme = current_theme
	var custom_path = current_theme.get_value('buttons', 'custom_path', "")
	var CustomChoiceButton = load(custom_path)
	var button = CustomChoiceButton.instance()
	button.text = label
	return button


func get_classic_choice_button(label: String):
	var theme = current_theme
	var button : Button = ChoiceButton.instance()
	button.text = label
	button.set_meta('input_next', input_next)
	
	# Removing the blue selected border
	button.set('custom_styles/focus', StyleBoxEmpty.new())
	# Text
	button.set('custom_fonts/font', DialogicUtil.path_fixer_load(theme.get_value('text', 'font', "res://addons/dialogic/Example Assets/Fonts/DefaultFont.tres")))

	if not use_native_choice_button():
		if theme.get_value('buttons', 'fixed', false):
			var size = theme.get_value('buttons', 'fixed_size', Vector2(130,40))
			button.rect_min_size = size
			button.rect_size = size
		
		$Options.set('custom_constants/separation', theme.get_value('buttons', 'gap', 20))
		
		# Different styles
		var default_background = 'res://addons/dialogic/Example Assets/backgrounds/background-2.png'
		var default_style = [
			false,               # 0 $TextColor/CheckBox
			Color.white,         # 1 $TextColor/ColorPickerButton
			false,               # 2 $FlatBackground/CheckBox
			Color.black,         # 3 $FlatBackground/ColorPickerButton
			true,               # 4 $BackgroundTexture/CheckBox
			default_background,  # 5 $BackgroundTexture/Button
			false,               # 6 $TextureModulation/CheckBox
			Color.white,         # 7 $TextureModulation/ColorPickerButton
		]
		
		var style_normal = theme.get_value('buttons', 'normal', default_style)
		var style_hover = theme.get_value('buttons', 'hover', default_style)
		var style_pressed = theme.get_value('buttons', 'pressed', default_style)
		var style_disabled = theme.get_value('buttons', 'disabled', default_style)
		
		# Text color
		var default_color = Color(theme.get_value('text', 'color', '#ffffff'))
		button.set('custom_colors/font_color', default_color)
		button.set('custom_colors/font_color_hover', default_color.lightened(0.2))
		button.set('custom_colors/font_color_pressed', default_color.darkened(0.2))
		button.set('custom_colors/font_color_disabled', default_color.darkened(0.8))
		
		if style_normal[0]:
			button.set('custom_colors/font_color', style_normal[1])
		if style_hover[0]:
			button.set('custom_colors/font_color_hover', style_hover[1])
		if style_pressed[0]:
			button.set('custom_colors/font_color_pressed', style_pressed[1])
		if style_disabled[0]:
			button.set('custom_colors/font_color_disabled', style_disabled[1])
		

		# Style normal
		button_style_setter('normal', style_normal, button, theme)
		button_style_setter('hover', style_hover, button, theme)
		button_style_setter('pressed', style_pressed, button, theme)
		button_style_setter('disabled', style_disabled, button, theme)
	return button


func button_style_setter(section, data, button, theme):
	var style_box = StyleBoxTexture.new()
	if data[2]:
		# I'm using a white texture to do the flat style because otherwise the padding doesn't work.
		style_box.set('texture', DialogicUtil.path_fixer_load("res://addons/dialogic/Images/Plugin/white-texture.png"))
		style_box.set('modulate_color', data[3])
	else:
		if data[4]:
			style_box.set('texture', DialogicUtil.path_fixer_load(data[5]))
		if data[6]:
			style_box.set('modulate_color', data[7])
	
	# Padding
	var padding = theme.get_value('buttons', 'padding', Vector2(5,5))
	style_box.set('margin_left', padding.x)
	style_box.set('margin_right',  padding.x)
	style_box.set('margin_top', padding.y)
	style_box.set('margin_bottom', padding.y)
	button.set('custom_styles/' + section, style_box)


func add_choice_button(option: Dictionary):
	if not _should_add_choice_button(option):
		return
	
	var button
	if use_custom_choice_button():
		button = get_custom_choice_button(option['label'])
	else:
		button = get_classic_choice_button(option['label'])
	
	if use_native_choice_button() or use_custom_choice_button():
		$Options.set('custom_constants/separation', current_theme.get_value('buttons', 'gap', 20))
	$Options.add_child(button)
	
	# Selecting the first button added
	if $Options.get_child_count() == 1:
		button.grab_focus()
	
	button.set_meta('event_idx', option['event_idx'])
	button.set_meta('question_idx', option['question_idx'])

	if Input.get_mouse_mode() != Input.MOUSE_MODE_VISIBLE:
		last_mouse_mode = Input.get_mouse_mode()
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE) # Make sure the cursor is visible for the options selection


func answer_question(i, event_idx, question_idx):
	if $TextBubble.is_finished():
		dprint('[!] Going to ', event_idx + 1, i, 'question_idx:', question_idx)
		waiting_for_answer = false
		questions[question_idx]['answered'] = true
		reset_options()
		_load_event_at_index(event_idx + 1)
		if last_mouse_mode != null:
			Input.set_mouse_mode(last_mouse_mode) # Revert to last mouse mode when selection is done
			last_mouse_mode = null


func _on_option_selected(option, variable, value):
	dialog_resource.custom_variables[variable] = value
	waiting_for_answer = false
	reset_options()
	_load_next_event()
	dprint('[!] Option selected: ', option.text, ' value= ' , value)


func grab_portrait_focus(character_data, event: Dictionary = {}) -> bool:
	var exists = false
	var visually_focus = true
	if settings.has_section_key('dialog', 'dim_characters'):
		visually_focus = settings.get_value('dialog', 'dim_characters')

	for portrait in $Portraits.get_children():
		if portrait.character_data == character_data:
			exists = true
			
			if visually_focus:
				portrait.focus()
			if event.has('portrait'):
				if event['portrait'] != '':
					portrait.set_portrait(event['portrait'])
		else:
			if visually_focus:
				portrait.focusout()
	return exists


func get_character_position(positions) -> String:
	if positions['0']:
		return 'left'
	if positions['1']:
		return 'center_left'
	if positions['2']:
		return 'center'
	if positions['3']:
		return 'center_right'
	if positions['4']:
		return 'right'
	return 'left'


func deferred_resize(current_size, result):
	#var result = theme.get_value('box', 'size', Vector2(910, 167))
	$TextBubble.rect_size = result
	if current_size != $TextBubble.rect_size:
		resize_main()


func load_theme(filename):
	var theme = DialogicResources.get_theme_config(filename)

	# Box size
	call_deferred('deferred_resize', $TextBubble.rect_size, theme.get_value('box', 'size', Vector2(910, 167)))

	# HERE
	var settings_input = settings.get_value('input', 'default_action_key', '[Default]')
	var theme_input = theme.get_value('settings', 'action_key', '[Default]')
	
	input_next = 'ui_accept'
	if settings_input != '[Default]':
		input_next = settings_input
	if theme_input != '[Default]':
		input_next = theme_input

	
	$TextBubble.load_theme(theme)
	
	$DefinitionInfo.load_theme(theme)
	return theme


func _on_RichTextLabel_meta_hover_started(meta):
	var correct_type = false
	for d in definitions['glossary']:
		if d['id'] == meta:
			$DefinitionInfo.load_preview({
				'title': d['title'],
				'body': parse_definitions(d['text'], true, false), # inserts variables but not other glossary items!
				'extra': d['extra'],
			})
			correct_type = true
			dprint('[D] Hovered over glossary entry: ', d)

	if correct_type:
		definition_visible = true
		$DefinitionInfo.visible = definition_visible
		# Adding a timer to avoid a graphical glitch
		$DefinitionInfo/Timer.stop()


func _on_RichTextLabel_meta_hover_ended(meta):
	# Adding a timer to avoid a graphical glitch
	$DefinitionInfo/Timer.start(0.1)


func _on_Definition_Timer_timeout():
	# Adding a timer to avoid a graphical glitch
	definition_visible = false
	$DefinitionInfo.visible = definition_visible


func dprint(string, arg1='', arg2='', arg3='', arg4='' ):
	# HAHAHA if you are here wondering what this is...
	# I ask myself the same question :')
	if debug_mode:
		print(str(string) + str(arg1) + str(arg2) + str(arg3) + str(arg4))


func _compare_definitions(def_value: String, event_value: String, condition: String):
	var condition_met = false;
	if def_value != null and event_value != null:
		# check if event_value equals a definition name and use that instead
		for d in definitions['variables']:
			if (d['name'] != '' and d['name'] == event_value):
				event_value = d['value']
				break;
		var converted_def_value = def_value
		var converted_event_value = event_value
		if def_value.is_valid_float() and event_value.is_valid_float():
			converted_def_value = float(def_value)
			converted_event_value = float(event_value)
		if condition == '':
			condition = '==' # The default condition is Equal to
		match condition:
			"==":
				condition_met = converted_def_value == converted_event_value
			"!=":
				condition_met = converted_def_value != converted_event_value
			">":
				condition_met = converted_def_value > converted_event_value
			">=":
				condition_met = converted_def_value >= converted_event_value
			"<":
				condition_met = converted_def_value < converted_event_value
			"<=":
				condition_met = converted_def_value <= converted_event_value
	#print('comparing definition: ', def_value, ',', event_value, ',', condition, ' - ', condition_met)
	return condition_met


func characters_leave_all():
	var portraits = get_node_or_null('Portraits')
	if portraits != null:
		for p in portraits.get_children():
			p.fade_out()


func open_dialog_animation(transition_duration):
	if transition_duration > 0:
		$TextBubble.update_text('') # Clearing the text
		$TextBubble.modulate = Color(1,1,1,0)
		while_dialog_animation = true
		var tween = Tween.new()
		add_child(tween)
		tween.interpolate_property($TextBubble, "modulate",
			$TextBubble.modulate, Color(1,1,1,1), transition_duration,
			Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
		tween.start()
		tween.connect("tween_completed", self, "clean_fade_in_tween", [tween])
	else:
		_init_dialog()


func clean_fade_in_tween(object, key, node):
	node.queue_free()
	while_dialog_animation = false
	_init_dialog()


func close_dialog_event(transition_duration):
	characters_leave_all()
	if transition_duration == 0:
		_on_close_dialog_timeout()
	else:
		var tween = Tween.new()
		add_child(tween)
		tween.interpolate_property($TextBubble, "modulate",
			$TextBubble.modulate, Color('#00ffffff'), transition_duration,
			Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
		tween.start()
		var close_dialog_timer = Timer.new()
		close_dialog_timer.connect("timeout", self, '_on_close_dialog_timeout')
		add_child(close_dialog_timer)
		close_dialog_timer.start(transition_duration)


func _on_close_dialog_timeout():
	on_timeline_end()
	queue_free()


func _on_OptionsDelayedInput_timeout():
	for button in $Options.get_children():
		if button.is_connected("pressed", self, "answer_question") == false:
			button.connect("pressed", self, "answer_question", [button, button.get_meta('event_idx'), button.get_meta('question_idx')])
