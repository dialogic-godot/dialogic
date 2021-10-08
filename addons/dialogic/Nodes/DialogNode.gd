tool
extends Control

## -----------------------------------------------------------------------------
## 						VARIABLES
## -----------------------------------------------------------------------------

### STARTING
## The timeline to load when starting the scene
var timeline: String

### MODE
var preview: bool = false
# Should we show debug information when running:
var debug_mode := true


### STATE FLAGS
var finished: bool = false
var waiting_for_answer: bool = false
var waiting_for_input: bool = false
# used in events to disable continuing:
var waiting: bool = false
var while_dialog_animation: bool = false
var do_fade_in := true
var dialog_faded_in_already = false
# true if the glossary popup is visible: # TODO rename
var definition_visible: bool = false
# used to reset the mouse mode after questions:
var last_mouse_mode = null


### SETTINGS
var input_next: String = 'ui_accept'
var settings: ConfigFile
var custom_events = {}


### DATA
var definitions = {}
var characters

# Parsing results
var questions #for keeping track of the questions answered

### CURRENT STATE
var current_timeline: String = ''
var dialog_script: Dictionary = {}
var current_event: Dictionary
var dialog_index: int = 0

var current_background = ""

# Theme and Audio
var current_theme: ConfigFile
var audio_data = {}

# References
var button_container = null

## -----------------------------------------------------------------------------
## 						SCENES
## -----------------------------------------------------------------------------

onready var ChoiceButton = load("res://addons/dialogic/Nodes/ChoiceButton.tscn")
onready var Portrait = load("res://addons/dialogic/Nodes/Portrait.tscn")
onready var Background = load("res://addons/dialogic/Nodes/Background.tscn")


## -----------------------------------------------------------------------------
## 						SIGNALS
## -----------------------------------------------------------------------------

# Event end/start
signal event_start(type, event)
signal event_end(type)
# Text Signals
signal text_complete(text_data)
# Timeline end/start
signal timeline_start(timeline_name)
signal timeline_end(timeline_name)
# Custom user signal
signal dialogic_signal(value)



## -----------------------------------------------------------------------------
## -----------------------------------------------------------------------------
## 						SCRIPT
## -----------------------------------------------------------------------------
## -----------------------------------------------------------------------------

func _ready():
	# Set this dialog as the latest (used for saving)
	Engine.get_main_loop().set_meta('latest_dialogic_node', self)
	
	# Loading the config files
	load_config_files()
	update_custom_events()
	
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
	$TextBubble.connect("letter_written", self, "_on_letter_written")
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
		if do_fade_in: _hide_dialog()
		_init_dialog()


# loads the definitions, themes and settings
func load_config_files():
	
	# defintiions
	if not Engine.is_editor_hint():
		definitions = Dialogic._get_definitions()
	else:
		definitions = DialogicResources.get_default_definitions()
	
	# settings
	settings = DialogicResources.get_settings_config()
	
	# theme
	var theme_file = 'res://addons/dialogic/Editor/ThemeEditor/default-theme.cfg'
	if settings.has_section('theme'):
		theme_file = settings.get_value('theme', 'default')
	current_theme = load_theme(theme_file)



## -----------------------------------------------------------------------------
## 						CUSTOM EVENTS
## -----------------------------------------------------------------------------
func update_custom_events() -> void:
	custom_events = {}
	
	var path:String = DialogicResources.get_working_directories()["CUSTOM_EVENTS_DIR"]
	
	var dir = Directory.new()
	if dir.open(path) == OK:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		# goes through all the folders in the custom events folder
		while file_name != "":
			# if it found a folder
			if dir.current_is_dir() and not file_name in ['.', '..']:
				
				# look through that folder
				#print("Found custom event folder: " + file_name)
				var event = load(path.plus_file(file_name).plus_file('EventBlock.tscn')).instance()
				if event:
					custom_events[event.event_data['event_id']] = {
						'event_script' :path.plus_file(file_name).plus_file('event_'+event.event_data['event_id']+'.gd'),
						'event_name' : event.event_name,
					}
					event.queue_free()
				else:
					print("[D] An error occurred when trying to access a custom event.")

				
			else:
				pass # files in the directory are ignored
			file_name = dir.get_next()
	else:
		print("[D] An error occurred when trying to access the custom event folder.")


## -----------------------------------------------------------------------------
## 						VISUALS
## -----------------------------------------------------------------------------

# This function makes sure that the dialog is displayed at the correct
# size and position in the screen.
func resize_main():
	var reference = rect_size
	if not Engine.is_editor_hint():
		set_global_position(Vector2(0,0))
		reference = get_viewport().get_visible_rect().size
	
	# Update box position
	var anchor = current_theme.get_value('box', 'anchor', 9)
	# TODO: remove backups in 2.0
	var gap_v = current_theme.get_value('box', 'box_margin_v', current_theme.get_value('box', 'bottom_gap', 40))
	var gap_h = current_theme.get_value('box', 'box_margin_h', current_theme.get_value('box', 'bottom_gap', 40))
	# first the y position
	if anchor in [0,1,2]: # TOP
		$TextBubble.rect_position.y = gap_h
	elif anchor in [4,5,6]: # CENTER
		$TextBubble.rect_position.y = (reference.y/2)-($TextBubble.rect_size.y/2)
	else:
		$TextBubble.rect_position.y = (reference.y) - ($TextBubble.rect_size.y)-gap_h
	
	# now x position
	if anchor in [0,4,8]: # LEFT
		$TextBubble.rect_position.x = gap_v
	elif anchor in [1,5,9]: # CENTER
		$TextBubble.rect_position.x = (reference.x / 2) - ($TextBubble.rect_size.x / 2)
	else:
		$TextBubble.rect_position.x = reference.x - ($TextBubble.rect_size.x) - gap_v
	
	# Update TextBubble background size
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
	
	# Button positioning
	var button_anchor = current_theme.get_value('buttons', 'anchor', 5)
	var anchor_vertical = 1
	var anchor_horizontal = 1
	# OMG WHY IS TIHS NOT A MATCH I CAN'T BELIEVE YOU, WHY YOU DOING THIS TO ME
	if button_anchor == 0:
		anchor_vertical = 0
		anchor_horizontal = 0
	elif button_anchor == 1:
		anchor_vertical = 0
	elif button_anchor == 2:
		anchor_vertical = 0
		anchor_horizontal = 2
	# Number skip because of the separator
	elif button_anchor == 4:
		anchor_horizontal = 0
	elif button_anchor == 6:
		anchor_horizontal = 2
	# Number skip because of the separator
	elif button_anchor == 8:
		anchor_vertical = 2
		anchor_horizontal = 0
	elif button_anchor == 9:
		anchor_vertical = 2
	elif button_anchor == 10:
		anchor_vertical = 2
		anchor_horizontal = 2
	
	var theme_choice_offset = current_theme.get_value('buttons', 'offset', Vector2(0,0))
	var position_offset = Vector2(0,0)
	
	if anchor_horizontal == 0:
		position_offset.x = (reference.x / 2) * -1
	elif anchor_horizontal == 1:
		position_offset.x = 0
	elif anchor_horizontal == 2:
		position_offset.x = (reference.x / 2)

	if anchor_vertical == 0:
		position_offset.y -= (reference.y / 2)
	elif anchor_vertical == 1:
		position_offset.y += 0
	elif anchor_vertical == 2:
		position_offset.y += (reference.y / 2)
	
	$Options.rect_global_position = Vector2(0,0) + theme_choice_offset + position_offset
	$Options.rect_size = reference

	
	# Background positioning
	var background = get_node_or_null('Background')
	if background != null:
		background.rect_size = reference
	
	var portraits = get_node_or_null('Portraits')
	if portraits != null:
		portraits.rect_position.x = reference.x / 2
		portraits.rect_position.y = reference.y

# calls resize_main
func deferred_resize(current_size, result):
	$TextBubble.rect_size = result
	if current_size != $TextBubble.rect_size:
		resize_main()

# loads the given theme file
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
	
	if theme.get_value('buttons', 'layout', 0) == 0:
		button_container = VBoxContainer.new()
	else:
		button_container = HBoxContainer.new()
	button_container.name = 'ButtonContainer'
	button_container.alignment = 1
	
	for n in $Options.get_children():
		n.queue_free()
	$Options.add_child(button_container)
	
	load_audio(theme)
	
	return theme


## -----------------------------------------------------------------------------
## 						AUDIO
## -----------------------------------------------------------------------------

func load_audio(theme):
	# Audio
	var default_audio_file = "res://addons/dialogic/Example Assets/Sound Effects/Beep.wav"
	var default_audio_data = {
		'enable': false,
		'path': default_audio_file,
		'volume': 0.0,
		'volume_rand_range': 0.0,
		'pitch': 1.0,
		'pitch_rand_range': 0.0,
		'allow_interrupt': true,
		'audio_bus': AudioServer.get_bus_name(0)
	}

	for audio_node in $FX/Audio.get_children():
		var name = audio_node.name.to_lower()
		audio_data[name] = theme.get_value('audio', name, default_audio_data)
	
		var file_system = Directory.new()
		if file_system.dir_exists(audio_data[name].path):
			audio_node.load_samples_from_folder(audio_data[name].path)
		elif file_system.file_exists(audio_data[name].path) or file_system.file_exists(audio_data[name].path + '.import'):
			audio_node.samples = [load(audio_data[name].path)]
		
		audio_node.set_volume_db(audio_data[name].volume)
		audio_node.random_volume_range = audio_data[name].volume_rand_range
		audio_node.set_pitch_scale(audio_data[name].pitch)
		audio_node.random_pitch_range = audio_data[name].pitch_rand_range
		audio_node.set_bus(audio_data[name].audio_bus)

func play_audio(name):
	var node = $FX/Audio.get_node(name.capitalize())
	name = name.to_lower()
	if audio_data[name].enable:
		if audio_data[name].allow_interrupt or not node.is_playing():
			node.play()


## -----------------------------------------------------------------------------
## 					LOADING/PARSING DIALOG
## -----------------------------------------------------------------------------
# load a timeline file and start parsing
func set_current_dialog(dialog_path: String):
	current_timeline = dialog_path
	dialog_script = DialogicResources.get_timeline_json(dialog_path)
	return load_dialog()

# set the dialog script directly
func set_dialog_script(value):
	dialog_script = value

# starts all necessary parsing
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

# adds name coloring to the dialog texts
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
				
				#Regex purposefully excludes [] as replacing those interferes with the second regex
				var escapeRegExp = "(?=[+&|!(){}^\"~*.?:\\\\-])" 
				
				var regex = RegEx.new()
				regex.compile(escapeRegExp)
				char_names = regex.sub(str(char_names), "\\", true)
				
				var regex_thing = str(char_names).replace("[", "(").replace("]", ")").replace(", ", "|")+'\\b'
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

# removes empty lines, splits message at new lines
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

# adds the alignment BBCode to text events
func parse_alignment(text):
	var alignment = current_theme.get_value('text', 'alignment', 'Left')
	var fname = current_theme.get_value('settings', 'name', 'none')
	if alignment == 'Center':
		text = '[center]' + text + '[/center]'
	elif alignment == 'Right':
		text = '[right]' + text + '[/right]'
	return text

# creates a list of questions to be used at the end of choices
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

# returns the text but with BBcode for glossary and the values of the variables
func parse_definitions(text: String, variables: bool = true, glossary: bool = true):
	var final_text: String = text
	if not preview:
		definitions = Dialogic._get_definitions()
	if variables:
		final_text = _insert_variable_definitions(text)
	if glossary and _should_show_glossary():
		final_text = _insert_glossary_definitions(final_text)
	return final_text

# adds the values of the variables
func _insert_variable_definitions(text: String):
	var final_text := text;
	for d in definitions['variables']:
		var name : String = d['name'];
		final_text = final_text.replace('[' + name + ']', d['value'])
	return final_text;

# adds the BBCode for the glossary words
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


## -----------------------------------------------------------------------------
## 					MAIN GAME-LOGIC 
## -----------------------------------------------------------------------------
# checks if NextIndicator and ChoiceButtons should be visible
func _process(delta):
	$TextBubble/NextIndicatorContainer/NextIndicator.visible = finished
	if button_container.get_child_count() > 0:
		$TextBubble/NextIndicatorContainer/NextIndicator.visible = false # Hide if question 
		if waiting_for_answer and Input.is_action_just_released(input_next):
			button_container.get_child(0).grab_focus()
	
	# Hide if no input is required
	if current_event.has('text'):
		if '[nw]' in current_event['text'] or '[nw=' in current_event['text']:
			$TextBubble/NextIndicatorContainer/NextIndicator.visible = false
	
	# Hide if fading in
	if while_dialog_animation:
		$TextBubble/NextIndicatorContainer/NextIndicator.visible = false

# checks for the "input_next" action
func _input(event: InputEvent) -> void:
	if not Engine.is_editor_hint() and event.is_action_pressed(input_next) and not waiting:
		if not $TextBubble.is_finished():
			# Skip to end if key is pressed during the text animation
			$TextBubble.skip()
			# Cut the voice 
			$FX/CharacterVoice.stop_voice()
		else:
			if waiting_for_answer == false and waiting_for_input == false and while_dialog_animation == false:
				$FX/CharacterVoice.stop_voice() # stop the current voice as well 
				play_audio("passing")
				_load_next_event()
		if settings.has_section_key('dialog', 'propagate_input'):
			var propagate_input: bool = settings.get_value('dialog', 'propagate_input')
			if not propagate_input:
				get_tree().set_input_as_handled()

# when the text finished showing
# plays audio, adds buttons, handles [nw]
func _on_text_completed():
	emit_signal('text_complete', current_event)
	
	play_audio('waiting')
	
	finished = true
	
	# Add the choice buttons for questions
	if current_event.has('options'):
		var waiting_until_options_enabled = float(settings.get_value('input', 'delay_after_options', 0.1))
		$OptionsDelayedInput.start(waiting_until_options_enabled)

		for o in current_event['options']:
			add_choice_button(o)
	
	if current_event.has('text'):
		# [p] needs more work
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


# emits timeline_start and handles autosaving
func on_timeline_start():
	if not Engine.is_editor_hint():
		if settings.get_value('saving', 'autosave', true):
			# save to the default slot
			Dialogic.save('', true)
	# TODO remove event_start in 2.0
	emit_signal("event_start", "timeline", current_timeline)
	emit_signal("timeline_start", current_timeline)

# emits timeline_end and handles autosaving
func on_timeline_end():
	if not Engine.is_editor_hint():
		if settings.get_value('saving', 'autosave', true):
			# save to the default slot
			Dialogic.save('', true)
	# TODO remove event_end in 2.0
	emit_signal("event_end", "timeline")
	emit_signal("timeline_end", current_timeline)
	dprint('[D] Timeline End')

# does checks and calls the above functions
func _emit_timeline_signals():
	if dialog_script.has('events'):
		if dialog_index == 0:
			on_timeline_start()
		elif _is_dialog_finished():
			on_timeline_end()


# resets dialog_index and starts first event
func _init_dialog():
	dialog_index = 0
	_load_event()

# jumps to the event at the given index
func _load_event_at_index(index: int):
	dialog_index = index
	_load_event()

# loads the next event
func _load_next_event():
	dialog_index += 1
	_load_event()

# returns true if dialog_index is outside of the events indexes
func _is_dialog_finished():
	return dialog_index >= dialog_script['events'].size()

# calls the event_handler 
func _load_event():
	_emit_timeline_signals()
	_hide_definition_popup()
	
	if dialog_script.has('events'):
		if not _is_dialog_finished():
			# CHECK IF NECESSARY!
			var func_state = event_handler(dialog_script['events'][dialog_index])
			#if (func_state is GDScriptFunctionState):
			#	print(func_state)
			#	yield(func_state, "completed")
		elif not Engine.is_editor_hint():
			# Do not free the dialog if we are in the preview
			queue_free()

# Handling an event and updating the available nodes accordingly.
func event_handler(event: Dictionary):
	$TextBubble.reset()
	reset_options()
	
	dprint('[D] Current Event: ', event)
	current_event = event
	match event['event_id']:
		# MAIN EVENTS
		# Text Event
		'dialogic_001':
			emit_signal("event_start", "text", event)
			fade_in_dialog()
			finished = false
			if event.has('character'):
				var character_data = get_character(event['character'])
				update_name(character_data)
				grab_portrait_focus(character_data, event)
			#voice 
			handle_voice(event)
			update_text(event['text'])
		# Join event
		'dialogic_002':
			## PLEASE UPDATE THIS! BUT HOW? 
			emit_signal("event_start", "action", event)
			if event['character'] == '':# No character found on the event. Skip.
				_load_next_event()
			else:
				var character_data = get_character(event['character'])
				if portrait_exists(character_data):
					for portrait in $Portraits.get_children():
						if portrait.character_data == character_data:
							portrait.move_to_position(get_character_position(event['position']))
							portrait.set_mirror(event.get('mirror', false))
							portrait.current_state['position'] = event['position']
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
					p.current_state['character'] = event['character']
					p.current_state['position'] = event['position']
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
			fade_in_dialog()
			finished = false
			waiting_for_answer = true
			if event.has('name'):
				update_name(event['name'])
			elif event.has('character'):
				var character_data = get_character(event['character'])
				update_name(character_data)
				grab_portrait_focus(character_data, event)
			#voice 
			handle_voice(event)
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
			Dialogic.set_variable_from_id(event['definition'], value, operation)
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
			
			current_background = event['background']
			if background != null:
				background.name = "BackgroundFadingOut"
				background.fade_out(fade_time)
				background = null
			
			if value != '':
				background = Background.instance()
				add_child(background)
				if (event['background'].ends_with('.tscn')):
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
			
			while_dialog_animation = true
			var transition_duration = event.get('transition_duration', 1.0)
			
			# fade out characters
			characters_leave_all()
			
			# fade out background
			var background = get_node_or_null('Background')
			if background != null:
				background.name = 'BackgroundFadingOut'
				background.fade_out(transition_duration)
			
			if transition_duration != 0:
				var tween = Tween.new()
				add_child(tween)
				tween.interpolate_property($TextBubble, "modulate",
					$TextBubble.modulate, Color('#00ffffff'), transition_duration,
					Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
				tween.start()
				yield(tween, "tween_all_completed")
			
			on_timeline_end()
			queue_free()
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
			resize_main()
			_load_next_event()
		# Set Glossary event
		'dialogic_025':
			emit_signal("event_start", "set_glossary", event)
			if event['glossary_id']:
				Dialogic.set_glossary_from_id(event['glossary_id'], event['title'], event['text'],event['extra'])
			_load_next_event()
		# Save event
		'dialogic_026':
			emit_signal('event_start', 'save', event)
			var custom_slot :String = event.get('custom_slot', '').strip_edges()
			if event.get('use_default_slot', true) or custom_slot == '':
				Dialogic.save()
			else:
				if custom_slot.begins_with("[") and custom_slot.ends_with("]"):
					custom_slot = custom_slot.trim_prefix("[").trim_suffix("]")
					var saved = false
					for definition in definitions['variables']:
						if definition['name'] == custom_slot:
							Dialogic.save(definition['value'])
							saved = true
					if not saved:
						print("[D] Tried to access value definition '"+custom_slot+"' for saving, but it didn't exist.")
				else:
					Dialogic.save(custom_slot)
			
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
			if event['event_id'] in custom_events.keys():
				dprint("[D] Custom event '"+custom_events[event['event_id']]['event_name']+"'")
				
				var handler = Node.new()
				handler.set_script(load(custom_events[event['event_id']]['event_script']))
				
				handler.handle_event(event, self)
				
			else:
				visible = false
				dprint('[D] No event found. Recevied data: ', event)
	
	$Options.visible = waiting_for_answer

## -----------------------------------------------------------------------------
## 					TEXTBOX-FUNCTIONALITY
## -----------------------------------------------------------------------------
# updates the Name Label
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

# shows the given text in the Text Bubble
# handles the simple translation feature
func update_text(text: String) -> String:
	if settings.has_section_key('dialog', 'translations') and settings.get_value('dialog', 'translations'):
		text = tr(text)
	var final_text = parse_definitions(parse_alignment(text))
	final_text = final_text.replace('[br]', '\n')

	$TextBubble.update_text(final_text)
	return final_text

# plays a sound
func _on_letter_written():
	play_audio('typing')


## -----------------------------------------------------------------------------
## 						CHOICE/OPTION BUTTONS
## -----------------------------------------------------------------------------

# called when a choice is selected
# hides choices, sets question as answered and jumps to the appropriate event
func answer_question(i, event_idx, question_idx):
	if $TextBubble.is_finished(): # CHECK IF NECESSARY!
		dprint('[!] Going to ', event_idx + 1, i, 'question_idx:', question_idx)
		
		play_audio("selecting")
		
		reset_options()
		
		# set flags and continue dialog
		waiting_for_answer = false
		questions[question_idx]['answered'] = true
		_load_event_at_index(event_idx + 1)
		
		# Revert to last mouse mode when selection is done
		if last_mouse_mode != null:
			Input.set_mouse_mode(last_mouse_mode) 
			last_mouse_mode = null

# deletest the choice buttons
func reset_options():
	# Clearing out the options after one was selected.
	for option in button_container.get_children():
		option.queue_free()

# adds a button for the given choice
func add_choice_button(option: Dictionary):
	if not _should_add_choice_button(option):
		return
	
	var button
	if use_custom_choice_button():
		button = get_custom_choice_button(option['label'])
	else:
		button = get_classic_choice_button(option['label'])
	
	if use_native_choice_button() or use_custom_choice_button():
		button_container.set('custom_constants/separation', current_theme.get_value('buttons', 'gap', 20))
	button_container.add_child(button)
	
	# Selecting the first button added
	if button_container.get_child_count() == 1:
		button.grab_focus()
	
	# Adding audio when focused or hovered
	button.connect('focus_entered', self, '_on_option_hovered', [button])
	button.connect('mouse_entered', self, '_on_option_focused')
	
	button.set_meta('event_idx', option['event_idx'])
	button.set_meta('question_idx', option['question_idx'])

	if Input.get_mouse_mode() != Input.MOUSE_MODE_VISIBLE:
		last_mouse_mode = Input.get_mouse_mode()
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE) # Make sure the cursor is visible for the options selection

# checks the condition of the given option
func _should_add_choice_button(option: Dictionary):
	if not option['definition'].empty():
		var def_value = null
		for d in definitions['variables']:
			if d['id'] == option['definition']:
				def_value = d['value']
		return def_value != null and _compare_definitions(def_value, option['value'], option['condition']);
	else:
		return true

# checks the 'custom_choice_button' setting
func use_custom_choice_button():
	return current_theme.get_value('buttons', 'use_custom', false) and not current_theme.get_value('buttons', 'custom_path', "").empty()

# checks the 'native_choice_button' setting
func use_native_choice_button():
	return current_theme.get_value('buttons', 'use_native', false)

# instances a custom choice
func get_custom_choice_button(label: String):
	var theme = current_theme
	var custom_path = current_theme.get_value('buttons', 'custom_path', "")
	var CustomChoiceButton = load(custom_path)
	var button = CustomChoiceButton.instance()
	button.text = label
	return button

# instances a normal dialogic button
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
		
		button_container.set('custom_constants/separation', theme.get_value('buttons', 'gap', 20))
		
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

# adds parts of a style to the given button
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

# focuses button on hover
func _on_option_hovered(button):
	button.grab_focus()

# plays the sound
func _on_option_focused():
	play_audio("hovering")

# connects the signals after a short delay to make accidental clicking less likely
func _on_OptionsDelayedInput_timeout():
	for button in button_container.get_children():
		if button.is_connected("pressed", self, "answer_question") == false:
			button.connect("pressed", self, "answer_question", [button, button.get_meta('event_idx'), button.get_meta('question_idx')])

## -----------------------------------------------------------------------------
## 					VOICE LINE FEATURE
## -----------------------------------------------------------------------------
# plays the voice line of the event
func handle_voice(event):
	var settings_file = DialogicResources.get_settings_config()
	if not settings_file.get_value('dialog', 'text_event_audio_enable', false):
		return
	# In game only 
	if Engine.is_editor_hint():
		return
	
	if event.has('voice_data'):
		var voice_data = event['voice_data']
		if voice_data.has('0'):
			$FX/CharacterVoice.play_voice(voice_data['0'])
			return
	
	$FX/CharacterVoice.stop_voice()

## -----------------------------------------------------------------------------
## 						PORTRAITS
## -----------------------------------------------------------------------------
# defocuses all characters except the given one
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

# returns true if the a portrait for that character already exists
func portrait_exists(character_data) -> bool:
	var exists = false
	for portrait in $Portraits.get_children():
		if portrait.character_data == character_data:
			exists = true
	return exists

# converts PORTRAIT-WEIRDNESS to a word
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

# moves out all portraits
func characters_leave_all():
	var portraits = get_node_or_null('Portraits')
	if portraits != null:
		for p in portraits.get_children():
			p.fade_out()

## -----------------------------------------------------------------------------
## 						GLOSSARY POPUP
## -----------------------------------------------------------------------------
# cheks the 'show_glossary' setting
func _should_show_glossary():
	if current_theme != null:
		return current_theme.get_value('definitions', 'show_glossary', true)
	return true

# shows the glossary popup
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

# hides the glossary popup
func _on_RichTextLabel_meta_hover_ended(meta):
	# Adding a timer to avoid a graphical glitch
	$DefinitionInfo/Timer.start(0.1)

# hides the glossary popup
func _hide_definition_popup():
	definition_visible = false
	$DefinitionInfo.visible = definition_visible

# (actually) hides the glossary popup
func _on_Definition_Timer_timeout():
	# Adding a timer to avoid a graphical glitch
	definition_visible = false
	$DefinitionInfo.visible = definition_visible


## -----------------------------------------------------------------------------
## 						HELPERS
## -----------------------------------------------------------------------------
# prints multiple strings if debug_mode is true
func dprint(string, arg1='', arg2='', arg3='', arg4='' ):
	# HAHAHA if you are here wondering what this is...
	# I ask myself the same question :')
	if debug_mode:
		print(str(string) + str(arg1) + str(arg2) + str(arg3) + str(arg4))


# helper that allows to get a character by file
func get_character(character_id):
	for c in characters:
		if c['file'] == character_id:
			return c
	return {}

# returns the result of the given dialogic comparison
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



## -----------------------------------------------------------------------------
## 					DIALOG FADING
## -----------------------------------------------------------------------------
# ähm... no clue. What is this @emilio?
# TODO wtf is this name?
func _hide_dialog():
	$TextBubble.update_text('') # Clearing the text
	$TextBubble.modulate = Color(1,1,1,0)
	while_dialog_animation = true
	dialog_faded_in_already = false

# start a fade in animation
func fade_in_dialog(time = 0.5):
	visible = true
	time = current_theme.get_value('animation', 'show_time', 0.5)
	var has_tween = false
	
	if Engine.is_editor_hint() == false:
		if dialog_faded_in_already == false:
			var tween = Tween.new()
			add_child(tween)
			# The tween created ('fade_in_tween_show_time') is also reference for the $TextBubble
			# node to know if it should start showing up the letters of the dialog or not.
			tween.name = 'fade_in_tween_show_time'
			$TextBubble.modulate.a = 0
			tween.interpolate_property($TextBubble, "modulate",
				$TextBubble.modulate, Color(1,1,1,1), time,
				Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
			tween.start()
			tween.connect("tween_completed", self, "finished_fade_in_dialog", [tween])
			has_tween = true
		
		if has_tween:
			while_dialog_animation = false
			dialog_faded_in_already = true

# at the end of fade animation, reset flags
func finished_fade_in_dialog(object, key, node):
	node.queue_free()
	while_dialog_animation = false
	dialog_faded_in_already = true

## -----------------------------------------------------------------------------
## 					LOADING AND SAVING
## -----------------------------------------------------------------------------
# returns all important data in a dictionary to be saved
func get_current_state_info():
	var state = {}

	# visible characters:
	state["portraits"] = []
	for portrait in $Portraits.get_children():
		state['portraits'].append(portrait.current_state)

	# background music:
	state['background_music'] = $FX/BackgroundMusic.get_current_info()

	# current_timeline and event
	state["timeline"] = current_timeline
	state['event_idx'] = dialog_index

	# current background
	state['background'] = current_background

	return state

# loads all important data from a dictionary
func resume_state_from_info(state_info):

	# wait until the dialog node was added to the tree
	do_fade_in = false
	yield(self, "ready")
	#print(state_info)



	# load the characters
	for saved_portrait in state_info['portraits']:
		var event = saved_portrait

		# this code is ALL copied from the event_handler. So I should probably outsource it to a function...
		var character_data = get_character(event['character'])
		if portrait_exists(character_data):
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
			p.move_to_position(get_character_position(event['position']), 0)
			# this info is only used to save the state later
			p.current_state['character'] = event['character']
			p.current_state['position'] = event['position']

	# load the background music
	if state_info['background_music'] != null:
		$FX/BackgroundMusic.crossfade_to(state_info['background_music']['file'], state_info['background_music']['audio_bus'], state_info['background_music']['volume'], 1)

	# load the background image
	if state_info['background']:
		current_background = state_info['background']

		var background = Background.instance()
		call_deferred('resize_main') # Executing the resize main to update the background size

		add_child(background)

		if (current_background.ends_with('.tscn')):
			var bg_scene = load(current_background)
			if (bg_scene):
				bg_scene = bg_scene.instance()
				background.add_child(bg_scene)
		elif (current_background != ''):
			background.texture = load(current_background)

	# load the timeline and event
	set_current_dialog(state_info['timeline'])

	# mark all previous question events as "answered"
	for event_index in range(0, state_info['event_idx']):
		if dialog_script['events'][event_index]['event_id'] == 'dialogic_010':
			dialog_script['events'][event_index]['answered'] = true

	_load_event_at_index(state_info['event_idx'])
