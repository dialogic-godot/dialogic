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
var dialog_script: Dictionary = {}
var questions #for keeping track of the questions answered


func _ready():
	# Loading the config files
	load_config_files()
	
	# Checking if the dialog should read the code from a external file
	if not timeline.empty():
		dialog_script = set_current_dialog(timeline)
	elif dialog_script.keys().size() == 0:
		dialog_script = {
			"events":[{"character":"","portrait":"",
			"text":"[Dialogic Error] No timeline specified."}]
		}
	
	# Connecting resize signal
	get_viewport().connect("size_changed", self, "resize_main")
	resize_main()

	# Setting everything up for the node to be default
	$DefinitionInfo.visible = false
	$TextBubble.connect("text_completed", self, "_on_text_completed")
	$TextBubble/RichTextLabel.connect('meta_hover_started', self, '_on_RichTextLabel_meta_hover_started')
	$TextBubble/RichTextLabel.connect('meta_hover_ended', self, '_on_RichTextLabel_meta_hover_ended')

	# Getting the character information
	characters = DialogicUtil.get_character_list()

	if Engine.is_editor_hint():
		if preview:
			_init_dialog()
	else:
		_init_dialog()


func load_config_files():
	if not Engine.is_editor_hint():
		if reset_saves:
			DialogicSingleton.init(reset_saves)
		definitions = DialogicSingleton.get_definitions()
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
	
	
	var background = get_node_or_null('Background')
	if background != null:
		background.rect_size = reference
	
	var portraits = get_node_or_null('Portraits')
	if portraits != null:
		portraits.rect_position.x = reference.x / 2
		portraits.rect_position.y = reference.y


func set_current_dialog(dialog_path: String):
	current_timeline = dialog_path
	var dialog_script = DialogicResources.get_timeline_json(dialog_path)
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
	var names = DialogicUtil.get_character_list()
	# I should use regex here, but this is way easier :)
	if names.size() > 0:
		var index = 0
		for t in dialog_script['events']:
			if t.has('text'):
				for n in names:
					var name_end_check = [' ', ',', '.', '?', '!', "'"]
					if n.has('name'):
						for c in name_end_check:
							dialog_script['events'][index]['text'] = t['text'].replace(n['name'] + c,
								'[color=#' + n['color'].to_html() + ']' + n['name'] + '[/color]' + c
							)
						if n.has('nickname') and n['nickname'] != '':
							var nicknames_array = n['nickname'].split(",", true, 0)
							for c in name_end_check:
								for nn in nicknames_array:
									dialog_script['events'][index]['text'] = t['text'].replace(nn + c,
										'[color=#' + n['color'].to_html() + ']' + nn + '[/color]' + c
									)
			index += 1
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
	var event_id: int = 0 # The current id for jumping later on
	var question_id: int = 0 # identifying the questions to assign options to it
	for event in dialog_script['events']:
		if event.has('choice'):
			var opened_branch = parser_queue.back()
			var option = {
				'question_id': opened_branch['question_id'],
				'label': event['choice'],
				'event_id': event_id,
				}
			if event.has('condition') and event.has('definition') and event.has('value'):
				option = {
					'question_id': opened_branch['question_id'],
					'label': event['choice'],
					'event_id': event_id,
					'condition': event['condition'],
					'definition': event['definition'],
					'value': event['value'],
					}
			else:
				option = {
					'question_id': opened_branch['question_id'],
					'label': event['choice'],
					'event_id': event_id,
					'condition': '',
					'definition': '',
					'value': '',
					}
			dialog_script['events'][opened_branch['event_id']]['options'].append(option)
			event['question_id'] = opened_branch['question_id']
		elif event.has('question'):
			event['event_id'] = event_id
			event['question_id'] = question_id
			event['answered'] = false
			question_id += 1
			questions.append(event)
			parser_queue.append(event)
		elif event.has('condition'):
			event['event_id'] = event_id
			event['question_id'] = question_id
			event['answered'] = false
			question_id += 1
			questions.append(event)
			parser_queue.append(event)
		elif event.has('endbranch'):
			event['event_id'] = event_id
			var opened_branch = parser_queue.pop_back()
			event['end_branch_of'] = opened_branch['question_id']
			dialog_script['events'][opened_branch['event_id']]['end_id'] = event_id
		event_id += 1

	return dialog_script


func _should_show_glossary():
	if current_theme != null:
		return current_theme.get_value('definitions', 'show_glossary', true)
	return true


func parse_definitions(text: String, variables: bool = true, glossary: bool = true):
	var final_text: String = text
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
	if waiting_for_answer and Input.is_action_just_released(input_next):
		if $Options.get_child_count() > 0:
			$Options.get_child(0).grab_focus()


func _input(event: InputEvent) -> void:
	if not Engine.is_editor_hint() and event.is_action_pressed(input_next) and not waiting:
		if not $TextBubble.is_finished():
			# Skip to end if key is pressed during the text animation
			$TextBubble.skip()
		else:
			if waiting_for_answer == false and waiting_for_input == false:
				_load_next_event()
		if settings.has_section_key('dialog', 'propagate_input'):
			var propagate_input: bool = settings.get_value('dialog', 'propagate_input')
			if not propagate_input:
				get_tree().set_input_as_handled()


func show_dialog():
	visible = true


func update_name(character) -> void:
	if character.has('name'):
		var parsed_name = character['name']
		var color = Color.white
		if character.has('display_name'):
			if character['display_name'] != '':
				parsed_name = character['display_name']
		if character.has('color'):
			color = character['color']
		parsed_name = parse_definitions(parsed_name, true, false)
		$TextBubble.update_name(parsed_name, color, current_theme.get_value('name', 'auto_color', true))
	else:
		$TextBubble.update_name('')


func update_text(text: String) -> String:
	var final_text = parse_definitions(parse_alignment(text))
	final_text = final_text.replace('[br]', '\n')
	$TextBubble.update_text(final_text)
	return final_text


func _on_text_completed():
	finished = true
	if current_event.has('options'):
		for o in current_event['options']:
			add_choice_button(o)


func on_timeline_start():
	if not Engine.is_editor_hint():
		if settings.get_value('saving', 'save_definitions_on_start', true):
			DialogicSingleton.save_definitions()
		if settings.get_value('saving', 'save_current_timeline', true):
			DialogicSingleton.set_current_timeline(current_timeline)
	# TODO remove event_start in 2.0
	emit_signal("event_start", "timeline", current_timeline)
	emit_signal("timeline_start", current_timeline)


func on_timeline_end():
	if not Engine.is_editor_hint():
		if settings.get_value('saving', 'save_definitions_on_end', true):
			DialogicSingleton.save_definitions()
		if settings.get_value('saving', 'clear_current_timeline', true):
			DialogicSingleton.set_current_timeline('')
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
	match event:
		{'text', 'character', 'portrait'}:
			emit_signal("event_start", "text", event)
			show_dialog()
			finished = false
			var character_data = get_character(event['character'])
			update_name(character_data)
			grab_portrait_focus(character_data, event)
			update_text(event['text'])
		{'question', 'question_id', 'options', ..}:
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
		{'choice', 'question_id'}:
			emit_signal("event_start", "choice", event)
			for q in questions:
				if q['question_id'] == event['question_id']:
					if q['answered']:
						# If the option is for an answered question, skip to the end of it.
						_load_event_at_index(q['end_id'])
		{'action', ..}:
			emit_signal("event_start", "action", event)
			if event['action'] == 'leaveall':
				if event['character'] == '[All]':
					characters_leave_all()
				else:
					for p in $Portraits.get_children():
						if p.character_data['file'] == event['character']:
							p.fade_out()
				_load_next_event()
			elif event['action'] == 'join':
				if event['character'] == '':
					_load_next_event()
				else:
					var character_data = get_character(event['character'])
					var exists = grab_portrait_focus(character_data)
					if exists == false:
						var p = Portrait.instance()
						var char_portrait = event['portrait']
						if char_portrait == '':
							char_portrait = 'Default'
						p.character_data = character_data
						p.init(char_portrait, get_character_position(event['position']), event.get('mirror', false))
						$Portraits.add_child(p)
						p.fade_in()
				_load_next_event()
		{'scene'}:
			get_tree().change_scene(event['scene'])
		{'background'}:
			emit_signal("event_start", "background", event)
			var background = get_node_or_null('Background')
			if event['background'] == '' and background != null:
				background.queue_free()
			else:
				if background == null:
					background = TextureRect.new()
					background.expand = true
					background.name = 'Background'
					background.anchor_right = 1
					background.anchor_bottom = 1
					background.stretch_mode = TextureRect.STRETCH_SCALE
					background.show_behind_parent = true
					background.mouse_filter = Control.MOUSE_FILTER_IGNORE
					call_deferred('resize_main') # Executing the resize main to update the background size
					
					add_child(background)
				background.texture = null
				if (background.get_child_count() > 0):
					for c in background.get_children():
						c.get_parent().remove_child(c)
						c.queue_free()
				if (event['background'].ends_with('.tscn')):
					var bg_scene = load(event['background'])
					if (bg_scene):
						bg_scene = bg_scene.instance()
						background.add_child(bg_scene)
				elif (event['background'] != ''):
					background.texture = load(event['background'])
			_load_next_event()
		{'audio'}, {'audio', 'file', ..}:
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
		{'background-music'}, {'background-music', 'file',..}:
			emit_signal("event_start", "background-music", event)
			if event['background-music'] == 'play' and 'file' in event.keys() and not event['file'].empty():
				$FX/BackgroundMusic.crossfade_to(event['file'], event.get('audio_bus', 'Master'), event.get('volume', 0), event.get('fade_length', 1))
			else:
				$FX/BackgroundMusic.fade_out(event.get('fade_length', 1))
			_load_next_event()
		{'endbranch', ..}:
			emit_signal("event_start", "endbranch", event)
			_load_next_event()
		{'change_scene'}:
			get_tree().change_scene(event['change_scene'])
		{'emit_signal', ..}:
			dprint('[!] Emitting signal: dialogic_signal(', event['emit_signal'], ')')
			emit_signal("dialogic_signal", event['emit_signal'])
			_load_next_event()
		{'close_dialog', ..}:
			emit_signal("event_start", "close_dialog", event)
			var transition_duration = 1.0
			if event.has('transition_duration'):
				transition_duration = event['transition_duration']
			close_dialog_event(transition_duration)
		{'set_theme'}:
			emit_signal("event_start", "set_theme", event)
			if event['set_theme'] != '':
				current_theme = load_theme(event['set_theme'])
			_load_next_event()
		{'wait_seconds'}:
			emit_signal("event_start", "wait", event)
			wait_seconds(event['wait_seconds'])
			waiting = true
		{'change_timeline'}:
			dialog_script = set_current_dialog(event['change_timeline'])
			_init_dialog()
		{'condition', 'definition', 'value', 'question_id', ..}:
			# Treating this conditional as an option on a regular question event
			var def_value = null
			var current_question = questions[event['question_id']]
			
			for d in definitions['variables']:
				if d['id'] == event['definition']:
					def_value = d['value']
			
			var condition_met = def_value != null and _compare_definitions(def_value, event['value'], event['condition']);
			
			current_question['answered'] = !condition_met
			if !condition_met:
				# condition not met, skipping branch
				_load_event_at_index(current_question['end_id'])
			else:
				# condition met, entering branch
				_load_next_event()
		{'set_value', 'definition', ..}:
			emit_signal("event_start", "set_value", event)
			var operation = '='
			if 'operation' in event and not event['operation'].empty():
				operation = event["operation"]
			DialogicSingleton.set_variable_from_id(event['definition'], event['set_value'], operation)
			_load_next_event()
		{'call_node', ..}:
			dprint('[!] Call Node signal: dialogic_signal(call_node) ', var2str(event['call_node']))
			emit_signal("event_start", "call_node", event)
			$TextBubble.visible = false
			waiting = true
			var target = get_node_or_null(event['call_node']['target_node_path'])
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
	if not option['condition'].empty() and not option['definition'].empty() and not option['value'].empty():
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
	# Text
	button.set('custom_fonts/font', DialogicUtil.path_fixer_load(theme.get_value('text', 'font', "res://addons/dialogic/Example Assets/Fonts/DefaultFont.tres")))

	if not use_native_choice_button():
		var text_color = Color(theme.get_value('text', 'color', "#ffffffff"))
		button.set('custom_colors/font_color', text_color)
		button.set('custom_colors/font_color_hover', text_color)
		button.set('custom_colors/font_color_pressed', text_color)
		
		if theme.get_value('buttons', 'fixed', false):
			var size = theme.get_value('buttons', 'fixed_size', Vector2(130,40))
			button.rect_min_size = size
			button.rect_size = size

		if theme.get_value('buttons', 'text_color_enabled', true):
			var button_text_color = Color(theme.get_value('buttons', 'text_color', "#ffffffff"))
			button.set('custom_colors/font_color', button_text_color)
			button.set('custom_colors/font_color_hover', button_text_color)
			button.set('custom_colors/font_color_pressed', button_text_color)

		# Background
		button.get_node('ColorRect').color = Color(theme.get_value('buttons', 'background_color', '#ff000000'))
		button.get_node('ColorRect').visible = theme.get_value('buttons', 'use_background_color', false)

		button.get_node('TextureRect').visible = theme.get_value('buttons', 'use_image', true)
		if theme.get_value('buttons', 'use_image', true):
			button.get_node('TextureRect').texture = DialogicUtil.path_fixer_load(theme.get_value('buttons', 'image', "res://addons/dialogic/Example Assets/backgrounds/background-2.png"))
			if theme.get_value('buttons', 'modulation', false):
				button.get_node('TextureRect').modulate = Color(theme.get_value('buttons', 'modulation_color', "#ffffffff"))

		var padding = theme.get_value('buttons', 'padding', Vector2(5,5))
		button.get_node('ColorRect').set('margin_left', -1 * padding.x)
		button.get_node('ColorRect').set('margin_right',  padding.x)
		button.get_node('ColorRect').set('margin_top', -1 * padding.y)
		button.get_node('ColorRect').set('margin_bottom', padding.y)

		button.get_node('TextureRect').set('margin_left', -1 * padding.x)
		button.get_node('TextureRect').set('margin_right',  padding.x)
		button.get_node('TextureRect').set('margin_top', -1 * padding.y)
		button.get_node('TextureRect').set('margin_bottom', padding.y)
		
		$Options.set('custom_constants/separation', theme.get_value('buttons', 'gap', 20) + (padding.y*2))
	else:
		button.get_node('ColorRect').visible = false
		button.get_node('TextureRect').visible = false
		button.set_flat(false)
	return button


func add_choice_button(option: Dictionary):
	if not _should_add_choice_button(option):
		return
	
	var button
	if use_custom_choice_button():
		button = get_custom_choice_button(option['label'])
	else:
		button = get_classic_choice_button(option['label'])
	button.connect("pressed", self, "answer_question", [button, option['event_id'], option['question_id']])

	if use_native_choice_button() or use_custom_choice_button():
		$Options.set('custom_constants/separation', current_theme.get_value('buttons', 'gap', 20))
	$Options.add_child(button)

	if Input.get_mouse_mode() != Input.MOUSE_MODE_VISIBLE:
		last_mouse_mode = Input.get_mouse_mode()
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE) # Make sure the cursor is visible for the options selection


func answer_question(i, event_id, question_id):
	dprint('[!] Going to ', event_id + 1, i, 'question_id:', question_id)
	waiting_for_answer = false
	questions[question_id]['answered'] = true
	reset_options()
	_load_event_at_index(event_id + 1)
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

	input_next = theme.get_value('settings', 'action_key', 'ui_accept')

	# Definitions
	var definitions_font = DialogicUtil.path_fixer_load(theme.get_value('definitions', 'font', "res://addons/dialogic/Example Assets/Fonts/GlossaryFont.tres"))
	$DefinitionInfo/VBoxContainer/Title.set('custom_fonts/normal_font', definitions_font)
	$DefinitionInfo/VBoxContainer/Content.set('custom_fonts/normal_font', definitions_font)
	$DefinitionInfo/VBoxContainer/Extra.set('custom_fonts/normal_font', definitions_font)
	
	$TextBubble.load_theme(theme)
	
	return theme


func _on_RichTextLabel_meta_hover_started(meta):
	var correct_type = false
	for d in definitions['glossary']:
		if d['id'] == meta:
			$DefinitionInfo.load_preview({
				'title': d['title'],
				'body': d['text'],
				'extra': d['extra'],
				'color': current_theme.get_value('definitions', 'color', '#ffbebebe'),
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


func wait_seconds(seconds):
	var timer = Timer.new()
	add_child(timer)
	timer.connect("timeout", self, '_on_WaitSeconds_timeout', [timer])
	timer.start(seconds)
	$TextBubble.visible = false


func _on_WaitSeconds_timeout(timer):
	emit_signal("event_end", "wait")
	waiting = false
	timer.stop()
	timer.queue_free()
	$TextBubble.visible = true
	_load_next_event()


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
	return condition_met


func characters_leave_all():
	var portraits = get_node_or_null('Portraits')
	if portraits != null:
		for p in portraits.get_children():
			p.fade_out()


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
