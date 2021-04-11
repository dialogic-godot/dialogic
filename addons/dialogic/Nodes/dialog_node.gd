tool
extends Control
class_name DialogicNode

var last_mouse_mode = null
var input_next: String = 'ui_accept'
var dialog_index: int = 0
var finished: bool = false
var text_speed = 0.02 # Higher = lower speed
var waiting_for_answer: bool = false
var waiting_for_input: bool = false
var waiting = false
var preview = false
var definitions = {}
var definition_visible = false

var settings
var current_theme
var current_timeline := ''

## The timeline to load when starting the scene
export(String, "TimelineDropdown") var timeline: String
## Should we clear saved data (definitions and timeline progress) on start?
export(bool) var reset_saves = true
## Should we show debug information when running?
export(bool) var debug_mode = true

signal event_start(type, event)
signal event_end(type)
signal dialogic_signal(value)

var dialog_resource
var characters

onready var ChoiceButton = load("res://addons/dialogic/Nodes/ChoiceButton.tscn")
onready var Portrait = load("res://addons/dialogic/Nodes/Portrait.tscn")
var dialog_script = {}
var questions #for keeping track of the questions answered

onready var tween_node = $TextBubble/Tween

# Used to detect timeline change
var runtime_id


## *****************************************************************************
##								PUBLIC METHODS
## *****************************************************************************

## Starts the dialog for the given timeline.
##
## This is exactly the same as using the editor:
## you can drag and drop the scene located at /addons/dialogic/Dialog.tscn 
## and set the current timeline via the inspector.
##
## @param given_timeline		The timeline to load. You can provide the timeline name or the filename.
## @param reset					True to reset dialogic saved data such as definitions.
## @param debug					Debug is disabled by default but can be enabled if needed.
func start(given_timeline: String, reset: bool=true, debug: bool=false):
	show()
	reset_saves = reset
	debug_mode = debug
	runtime_id = DialogicUtil.generate_random_id()
	_load_definitions()
	_stop_close_dialog()
	if not given_timeline.empty():
		dialog_script = null
		for t in DialogicUtil.get_timeline_list():
			if t['name'] == given_timeline or t['file'] == given_timeline:
				dialog_script = _set_current_dialog(t['file'])
		if dialog_script == null:
			dialog_script = {
				"events":[{
					"character":"",
					"portrait":"",
					"text":"[color=red][Dialogic Error][/color] Could not load dialog '[color=red]" + given_timeline + "[/color]'. It seems like the timeline doesn't exists. Maybe the name is wrong?"
				}]
			}
	elif dialog_script.keys().size() == 0:
		dialog_script = {
			"events":[{
				"character":"",
				"portrait":"",
				"text":"[color=red][Dialogic Error][/color] No timeline specified."
			}]
		}
	if not Engine.is_editor_hint():
		_init_dialog()


## Same as the start method, but using the last timeline saved.
## 
## @param fallback				The timeline to load in case no save is found.
## @param debug					Debug is disabled by default but can be enabled if needed.
func start_from_save(fallback: String, debug: bool=false):
	var last = DialogicSingleton.get_current_timeline()
	if last.empty():
		last = fallback
	start(last, false, debug)


func load_preview(theme: String):
	pass


## *****************************************************************************
##								PRIVATE METHODS
## *****************************************************************************

func _load_definitions():
	if not Engine.is_editor_hint():
		if reset_saves:
			DialogicSingleton.init(reset_saves)
		definitions = DialogicSingleton.get_definitions()
	else:
		definitions = DialogicResources.get_default_definitions()


func _load_config_files():
	settings = DialogicResources.get_settings_config()
	var theme_file = 'res://addons/dialogic/Editor/ThemeEditor/default-theme.cfg'
	if settings.has_section('theme'):
		theme_file = settings.get_value('theme', 'default')
	current_theme = _load_theme(theme_file)


func _resize_main():
	# This function makes sure that the dialog is displayed at the correct
	# size and position in the screen. 
	if Engine.is_editor_hint() == false:
		set_global_position(Vector2(0,0))
		if ProjectSettings.get_setting("display/window/stretch/mode") != '2d':
			set_deferred('rect_size', get_viewport().size)
		_dprint("Viewport", get_viewport().size)
	$TextBubble.rect_position.x = (rect_size.x / 2) - ($TextBubble.rect_size.x / 2)
	if current_theme != null:
		$TextBubble.rect_position.y = (rect_size.y) - ($TextBubble.rect_size.y) - current_theme.get_value('box', 'bottom_gap', 40)


func _set_current_dialog(dialog_path: String):
	current_timeline = dialog_path
	var dialog_script = DialogicResources.get_timeline_json(dialog_path)
	# All this parse events should be happening in the same loop ideally
	# But until performance is not an issue I will probably stay lazy
	# And keep adding different functions for each parsing operation.
	if settings.has_section_key('dialog', 'auto_color_names'):
		if settings.get_value('dialog', 'auto_color_names'):
			dialog_script = _parse_characters(dialog_script)
	else:
		dialog_script = _parse_characters(dialog_script)
	
	dialog_script = _parse_text_lines(dialog_script)
	dialog_script = _parse_branches(dialog_script)
	return dialog_script


func _parse_characters(dialog_script):
	var names = DialogicUtil.get_character_list()
	# I should use regex here, but this is way easier :)
	if names.size() > 0:
		var index = 0
		for t in dialog_script['events']:
			if t.has('text'):
				for n in names:
					if n.has('name'):
						dialog_script['events'][index]['text'] = t['text'].replace(n['name'],
							'[color=#' + n['color'].to_html() + ']' + n['name'] + '[/color]'
						)
			index += 1
	return dialog_script


func _parse_text_lines(unparsed_dialog_script: Dictionary) -> Dictionary:
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
			if event['text'] == '' and remove_empty_messages == true:
				pass
			elif '\n' in event['text'] and preview == false and split_new_lines == true:
				var lines = event['text'].split('\n')
				var i = 0
				for line in lines:
					var _e = {
						'text': lines[i],
						'character': event['character'],
						'portrait': event['portrait']
					}
					new_events.append(_e)
					i += 1
			else:
				new_events.append(event)
		else:
			new_events.append(event)

	parsed_dialog['events'] = new_events

	return parsed_dialog


func _parse_alignment(text):
	var alignment = current_theme.get_value('text', 'alignment', 'Left')
	var fname = current_theme.get_value('settings', 'name', 'none')
	if alignment == 'Center':
		text = '[center]' + text + '[/center]'
	elif alignment == 'Right':
		text = '[right]' + text + '[/right]'
	return text


func _parse_branches(dialog_script: Dictionary) -> Dictionary:
	questions = [] # Resetting the questions

	# Return the same thing if it doesn't have events
	if dialog_script.has('events') == false:
		return dialog_script

	var parser_queue = [] # This saves the last question opened, and it gets removed once it was consumed by a endbranch event
	var event_id: int = 0 # The current id for jumping later on
	var question_id: int = 0 # identifying the questions to assign options to it
	for event in dialog_script['events']:
		if event.has('question'):
			event['event_id'] = event_id
			event['question_id'] = question_id
			event['answered'] = false
			question_id += 1
			questions.append(event)
			parser_queue.append(event)

		if event.has('condition'):
			event['event_id'] = event_id
			event['question_id'] = question_id
			event['answered'] = false
			question_id += 1
			questions.append(event)
			parser_queue.append(event)

		if event.has('choice'):
			var opened_branch = parser_queue.back()
			dialog_script['events'][opened_branch['event_id']]['options'].append({
				'question_id': opened_branch['question_id'],
				'label': event['choice'],
				'event_id': event_id,
				})
			event['question_id'] = opened_branch['question_id']

		if event.has('endbranch'):
			event['event_id'] = event_id
			var opened_branch = parser_queue.pop_back()
			event['end_branch_of'] = opened_branch['question_id']
			dialog_script['events'][opened_branch['event_id']]['end_id'] = event_id
		event_id += 1

	return dialog_script


func _parse_definitions(text: String, variables: bool = true, glossary: bool = true):
	if Engine.is_editor_hint():
		# Loading variables again to avoid issues in the preview dialog
		_load_definitions()
		_load_config_files()

	var final_text: String = text
	if variables:
		final_text = _insert_variable_definitions(text)
	if glossary:
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

func _show_dialog():
	visible = true


func _on_Tween_tween_completed(object, key):
	finished = true


func _update_name(character, color: Color = Color.white) -> void:
	if character.has('name'):
		var parsed_name = character['name']
		if character.has('display_name'):
			if character['display_name'] != '':
				parsed_name = character['display_name']
		if character.has('color'):
			color = character['color']
		parsed_name = _parse_definitions(parsed_name, true, false)
		$TextBubble/NameLabel.visible = true
		# Hack to reset the size
		$TextBubble/NameLabel.rect_min_size = Vector2(0, 0)
		$TextBubble/NameLabel.rect_size = Vector2(-1, 40)
		# Setting the color and text
		$TextBubble/NameLabel.text = parsed_name
		if current_theme.get_value('name', 'auto_color', true):
			$TextBubble/NameLabel.set('custom_colors/font_color', color)
	else:
		$TextBubble/NameLabel.visible = false


func _update_text(text):
	# Updating the text and starting the animation from 0
	text = _parse_alignment(text)
	$TextBubble/RichTextLabel.bbcode_text = _parse_definitions(text)
	$TextBubble/RichTextLabel.percent_visible = 0

	# The call to this function needs to be deferred.
	# More info: https://github.com/godotengine/godot/issues/36381
	call_deferred("_start_text_tween")
	return true


func _start_text_tween():
	# This will start the animation that makes the text appear letter by letter
	var tween_duration = text_speed * $TextBubble/RichTextLabel.get_total_character_count()
	tween_node.interpolate_property(
		$TextBubble/RichTextLabel, "percent_visible", 0, 1, tween_duration,
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT
	)
	tween_node.start()


func _on_timeline_start():
	if not Engine.is_editor_hint():
		DialogicSingleton.save_definitions()
		DialogicSingleton.set_current_timeline(current_timeline)
	emit_signal("event_start", "timeline", current_timeline)


func _on_timeline_end():
	if not Engine.is_editor_hint():
		DialogicSingleton.save_definitions()
		DialogicSingleton.set_current_timeline('')
	emit_signal("event_end", "timeline")


func _init_dialog():
	dialog_index = 0
	_load_event()


func _load_event_at_index(index: int, current_runtime_id: String):
	if current_runtime_id == runtime_id:
		dialog_index = index
		_load_event()


func _load_next_event(current_runtime_id: String):
	# The entire event reading system should be refactored... but not today!
	if current_runtime_id == runtime_id:
		dialog_index += 1
		_load_event()


func _load_event():
	# Emitting signals
	if dialog_script.has('events'):
		if dialog_index == 0:
			_on_timeline_start()
		elif dialog_index == dialog_script['events'].size():
			_on_timeline_end()

	# Hiding definitions popup
	definition_visible = false
	$DefinitionInfo.visible = definition_visible

	# This will load the next entry in the dialog_script array.
	if dialog_script.has('events') and dialog_index < dialog_script['events'].size():
		var func_state = _event_handler(dialog_script['events'][dialog_index])
		if (func_state is GDScriptFunctionState):
			yield(func_state, "completed")
	else:
		_close_dialog_event()


func _event_handler(event: Dictionary):
	# Handling an event and updating the available nodes accordingly.
	_reset_dialog_extras()
	_reset_options()
	
	var current_runtime_id = runtime_id
	
	_dprint('[D] Current Event: ', event)
	match event:
		{'text', 'character', 'portrait'}:
			emit_signal("event_start", "text", event)
			_show_dialog()
			finished = false
			var character_data = _get_character(event['character'])
			_update_name(character_data)
			_grab_portrait_focus(character_data, event)
			_update_text(event['text'])
		{'question', 'question_id', 'options', ..}:
			emit_signal("event_start", "question", event)
			_show_dialog()
			finished = false
			waiting_for_answer = true
			if event.has('name'):
				_update_name(event['name'])
			_update_text(event['question'])
			if event.has('options'):
				for o in event['options']:
					_add_choice_button(o)
		{'choice', 'question_id'}:
			emit_signal("event_start", "choice", event)
			for q in questions:
				if q['question_id'] == event['question_id']:
					if q['answered']:
						# If the option is for an answered question, skip to the end of it.
						_load_event_at_index(q['end_id'], current_runtime_id)
		{'input', ..}:
			emit_signal("event_start", "input", event)
			_show_dialog()
			finished = false
			waiting_for_input = true
			_update_text(event['input'])
			$TextInputDialog.window_title = event['window_title']
			$TextInputDialog.popup_centered()
			$TextInputDialog.connect("confirmed", self, "_on_input_set", [event['variable']])
		{'action', ..}:
			emit_signal("event_start", "action", event)
			if event['action'] == 'leaveall':
				if event['character'] == '[All]':
					_characters_leave_all()
				else:
					for p in $Portraits.get_children():
						if p.character_data['file'] == event['character']:
							p.fade_out()

				_load_next_event(current_runtime_id)
			elif event['action'] == 'join':
				if event['character'] == '':
					_load_next_event(current_runtime_id)
				else:
					var character_data = _get_character(event['character'])
					var exists = _grab_portrait_focus(character_data)
					if exists == false:
						var p = Portrait.instance()
						var char_portrait = event['portrait']
						if char_portrait == '':
							char_portrait = 'Default'
						p.character_data = character_data
						p.init(char_portrait, _get_character_position(event['position']))
						$Portraits.add_child(p)
						p.fade_in()
				_load_next_event(current_runtime_id)
		{'scene'}:
			get_tree().change_scene(event['scene'])
			_load_next_event(current_runtime_id)
		{'background'}:
			emit_signal("event_start", "background", event)
			$Background.visible = true
			$Background.texture = null
			if ($Background.get_child_count() > 0):
				for c in $Background.get_children():
					c.get_parent().remove_child(c)
					c.queue_free()
			if (event['background'].ends_with('.tscn')):
				var bg_scene = load(event['background'])
				if (bg_scene):
					bg_scene = bg_scene.instance()
					$Background.add_child(bg_scene)
			elif (event['background'] != ''):
				$Background.texture = load(event['background'])
			_load_next_event(current_runtime_id)
		{'audio'}, {'audio', 'file'}:
			emit_signal("event_start", "audio", event)
			if event['audio'] == 'play' and 'file' in event.keys() and not event['file'].empty():
				$FX/AudioStreamPlayer.stream = load(event['file'])
				$FX/AudioStreamPlayer.play()
			else:
				$FX/AudioStreamPlayer.stop()
			_load_next_event(current_runtime_id)
		{'background-music'}, {'background-music', 'file'}:
			emit_signal("event_start", "background-music", event)
			if event['background-music'] == 'play' and 'file' in event.keys() and not event['file'].empty():
				$FX/BackgroundMusic.crossfade_to(event['file'])
			else:
				$FX/BackgroundMusic.fade_out()
			_load_next_event(current_runtime_id)
		{'endbranch', ..}:
			emit_signal("event_start", "endbranch", event)
			_load_next_event(current_runtime_id)
		{'change_scene'}:
			get_tree().change_scene(event['change_scene'])
			_load_next_event(current_runtime_id)
		{'emit_signal', ..}:
			_dprint('[!] Emitting signal: dialogic_signal(', event['emit_signal'], ')')
			emit_signal("dialogic_signal", event['emit_signal'])
			_load_next_event(current_runtime_id)
		{'close_dialog'}:
			emit_signal("event_start", "close_dialog", event)
			_close_dialog_event()
		{'set_theme'}:
			emit_signal("event_start", "set_theme", event)
			if event['set_theme'] != '':
				current_theme = _load_theme(event['set_theme'])
			_load_next_event(current_runtime_id)
		{'wait_seconds'}:
			emit_signal("event_start", "wait", event)
			_wait_seconds(event['wait_seconds'])
			waiting = true
		{'change_timeline'}:
			dialog_script = _set_current_dialog(event['change_timeline'])
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
				_load_event_at_index(current_question['end_id'], current_runtime_id)
			else:
				# condition met, entering branch
				_load_next_event(current_runtime_id)
		{'set_value', 'definition', ..}:
			emit_signal("event_start", "set_value", event)
			var operation = '='
			if 'operation' in event and not event['operation'].empty():
				operation = event["operation"]
			DialogicSingleton.set_variable_from_id(event['definition'], event['set_value'], operation)
			_load_next_event(current_runtime_id)
		{'call_node', ..}:
			_dprint('[!] Call Node signal: dialogic_signal(call_node) ', var2str(event['call_node']))
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
			_load_next_event(current_runtime_id)
		_:
			visible = false
			_dprint('Other event. ', event)
	$Options.visible = waiting_for_answer

func _reset_dialog_extras():
	$TextBubble/NameLabel.text = ''
	$TextBubble/NameLabel.visible = false


func _get_character(character_id):
	for c in characters:
		if c['file'] == character_id:
			return c
	return {}


func _on_input_set(variable):
	var input_value = $TextInputDialog/LineEdit.text
	if input_value == '':
		$TextInputDialog.popup_centered()
	else:
		dialog_resource.custom_variables[variable] = input_value
		waiting_for_input = false
		$TextInputDialog/LineEdit.text = ''
		$TextInputDialog.disconnect("confirmed", self, '_on_input_set')
		$TextInputDialog.visible = false
		_load_next_event(runtime_id)
		_dprint('[!] Input selected: ', input_value)
		_dprint('[!] dialog variables: ', dialog_resource.custom_variables)


func _reset_options():
	# Clearing out the options after one was selected.
	for option in $Options.get_children():
		option.queue_free()


func _add_choice_button(option):
	var theme = current_theme

	var button = ChoiceButton.instance()
	button.text = option['label']
	# Text
	button.set('custom_fonts/font', DialogicUtil.path_fixer_load(theme.get_value('text', 'font', "res://addons/dialogic/Example Assets/Fonts/DefaultFont.tres")))

	if not theme.get_value('buttons', 'use_native', false):
		var text_color = Color(theme.get_value('text', 'color', "#ffffffff"))
		button.set('custom_colors/font_color', text_color)
		button.set('custom_colors/font_color_hover', text_color)
		button.set('custom_colors/font_color_pressed', text_color)

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
		
		$Options.set('custom_constants/separation', theme.get_value('buttons', 'gap', 20))

	button.connect("pressed", self, "_answer_question", [button, option['event_id'], option['question_id']])

	$Options.add_child(button)

	if Input.get_mouse_mode() != Input.MOUSE_MODE_VISIBLE:
		last_mouse_mode = Input.get_mouse_mode()
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE) # Make sure the cursor is visible for the options selection


func _answer_question(i, event_id, question_id):
	_dprint('[!] Going to ', event_id + 1, i, 'question_id:', question_id)
	_dprint('')
	waiting_for_answer = false
	dialog_index = event_id
	questions[question_id]['answered'] = true
	_dprint('    dialog_index = ', dialog_index)
	_reset_options()
	_load_next_event(runtime_id)
	if last_mouse_mode != null:
		Input.set_mouse_mode(last_mouse_mode) # Revert to last mouse mode when selection is done
		last_mouse_mode = null


func _on_option_selected(option, variable, value):
	dialog_resource.custom_variables[variable] = value
	waiting_for_answer = false
	_reset_options()
	_load_next_event(runtime_id)
	_dprint('[!] Option selected: ', option.text, ' value= ' , value)


func _on_TextInputDialog_confirmed():
	pass # Replace with function body.


func _grab_portrait_focus(character_data, event: Dictionary = {}) -> bool:
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


func _get_character_position(positions) -> String:
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


func _deferred_resize(current_size, result):
	#var result = theme.get_value('box', 'size', Vector2(910, 167))
	$TextBubble.rect_size = result
	if current_size != $TextBubble.rect_size:
		_resize_main()


func _load_theme(filename):
	var theme = DialogicResources.get_theme_config(filename)

	# Box size
	call_deferred('_deferred_resize', $TextBubble.rect_size, theme.get_value('box', 'size', Vector2(910, 167)))

	# Text
	var theme_font = DialogicUtil.path_fixer_load(theme.get_value('text', 'font', 'res://addons/dialogic/Example Assets/Fonts/DefaultFont.tres'))
	$TextBubble/RichTextLabel.set('custom_fonts/normal_font', theme_font)
	$TextBubble/NameLabel.set('custom_fonts/font', theme_font)

	var text_color = Color(theme.get_value('text', 'color', '#ffffffff'))
	$TextBubble/RichTextLabel.set('custom_colors/default_color', text_color)
	$TextBubble/NameLabel.set('custom_colors/font_color', text_color)

	$TextBubble/RichTextLabel.set('custom_colors/font_color_shadow', Color('#00ffffff'))
	$TextBubble/NameLabel.set('custom_colors/font_color_shadow', Color('#00ffffff'))

	if theme.get_value('text', 'shadow', false):
		var text_shadow_color = Color(theme.get_value('text', 'shadow_color', '#9e000000'))
		$TextBubble/RichTextLabel.set('custom_colors/font_color_shadow', text_shadow_color)

	var shadow_offset = theme.get_value('text', 'shadow_offset', Vector2(2,2))
	$TextBubble/RichTextLabel.set('custom_constants/shadow_offset_x', shadow_offset.x)
	$TextBubble/RichTextLabel.set('custom_constants/shadow_offset_y', shadow_offset.y)
	

	# Text speed
	text_speed = theme.get_value('text','speed', 2) * 0.01

	# Margin
	var text_margin = theme.get_value('text', 'margin', Vector2(20, 10))
	$TextBubble/RichTextLabel.set('margin_left', text_margin.x)
	$TextBubble/RichTextLabel.set('margin_right', text_margin.x * -1)
	$TextBubble/RichTextLabel.set('margin_top', text_margin.y)
	$TextBubble/RichTextLabel.set('margin_bottom', text_margin.y * -1)

	# Backgrounds
	$TextBubble/TextureRect.texture = DialogicUtil.path_fixer_load(theme.get_value('background','image', "res://addons/dialogic/Example Assets/backgrounds/background-2.png"))
	$TextBubble/ColorRect.color = Color(theme.get_value('background','color', "#ff000000"))

	if theme.get_value('background', 'modulation', false) == true:
		$TextBubble/TextureRect.modulate = Color(theme.get_value('background', 'modulation_color', '#ffffffff'))
	else:
		$TextBubble/TextureRect.modulate = Color('#ffffffff')

	$TextBubble/ColorRect.visible = theme.get_value('background', 'use_color', false)
	$TextBubble/TextureRect.visible = theme.get_value('background', 'use_image', true)

	# Next image
	$TextBubble/NextIndicator.texture = DialogicUtil.path_fixer_load(theme.get_value('next_indicator', 'image', 'res://addons/dialogic/Example Assets/next-indicator/next-indicator.png'))
	input_next = theme.get_value('settings', 'action_key', 'ui_accept')

	# Definitions
	var definitions_font = DialogicUtil.path_fixer_load(theme.get_value('definitions', 'font', "res://addons/dialogic/Example Assets/Fonts/GlossaryFont.tres"))
	$DefinitionInfo/VBoxContainer/Title.set('custom_fonts/normal_font', definitions_font)
	$DefinitionInfo/VBoxContainer/Content.set('custom_fonts/normal_font', definitions_font)
	$DefinitionInfo/VBoxContainer/Extra.set('custom_fonts/normal_font', definitions_font)
	
	# Character Name
	$TextBubble/NameLabel/ColorRect.visible = theme.get_value('name', 'background_visible', false)
	$TextBubble/NameLabel/ColorRect.color = Color(theme.get_value('name', 'background', '#282828'))
	$TextBubble/NameLabel/TextureRect.visible = theme.get_value('name', 'image_visible', false)
	$TextBubble/NameLabel/TextureRect.texture = DialogicUtil.path_fixer_load(theme.get_value('name','image', "res://addons/dialogic/Example Assets/backgrounds/background-2.png"))
	var name_shadow_offset = theme.get_value('name', 'shadow_offset', Vector2(2,2))
	if theme.get_value('name', 'shadow_visible', true):
		$TextBubble/NameLabel.set('custom_colors/font_color_shadow', Color(theme.get_value('name', 'shadow', '#9e000000')))
		$TextBubble/NameLabel.set('custom_constants/shadow_offset_x', name_shadow_offset.x)
		$TextBubble/NameLabel.set('custom_constants/shadow_offset_y', name_shadow_offset.y)
	$TextBubble/NameLabel.rect_position.y = theme.get_value('name', 'bottom_gap', 48) * -1
	if theme.get_value('name', 'modulation', false) == true:
		$TextBubble/NameLabel/TextureRect.modulate = Color(theme.get_value('name', 'modulation_color', '#ffffffff'))
	else:
		$TextBubble/NameLabel/TextureRect.modulate = Color('#ffffffff')
	
	# Setting next indicator animation
	$TextBubble/NextIndicator.self_modulate = Color('#ffffff')
	$TextBubble/NextIndicator/AnimationPlayer.play(
		theme.get_value('next_indicator', 'animation', 'Up and down')
	)
	
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
			_dprint(d)

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


func _wait_seconds(seconds):
	$WaitSeconds.start(seconds)
	$TextBubble.visible = false


func _on_WaitSeconds_timeout():
	emit_signal("event_end", "wait")
	waiting = false
	$WaitSeconds.stop()
	$TextBubble.visible = true
	_load_next_event(runtime_id)


func _dprint(string, arg1='', arg2='', arg3='', arg4='' ):
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


func _characters_leave_all():
	for p in $Portraits.get_children():
		p.fade_out()


func _close_dialog_event():
	var tween = $TextBubble/CloseDialog/Tween
	tween.interpolate_property($TextBubble, "modulate",
		$TextBubble.modulate, Color('#00ffffff'), 1,
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start()
	$TextBubble/CloseDialog/Timer.start(2)
	_characters_leave_all()


func _stop_close_dialog():
	$TextBubble.modulate = Color('#ffffffff')
	$TextBubble/CloseDialog/Tween.stop_all()
	$TextBubble/CloseDialog/Timer.stop()

func _on_close_dialog_timeout():
	hide()
	_on_timeline_end()


## *****************************************************************************
##								OVERRIDES
## *****************************************************************************


func _ready():
	# Loading the config files
	_load_config_files()
	
	# Connecting resize signal
	get_viewport().connect("size_changed", self, "_resize_main")
	_resize_main()

	# Setting everything up for the node to be default
	$TextBubble/NameLabel.text = ''
	$Background.visible = false
	$TextBubble/RichTextLabel.meta_underlined = false
	$DefinitionInfo.visible = false
	
	$TextBubble/CloseDialog/Timer.connect("timeout", self, '_on_close_dialog_timeout')
	tween_node.connect("tween_completed", self, '_on_Tween_tween_completed')

	# Getting the character information
	characters = DialogicUtil.get_character_list()

	# Try to start the timeline only if specified
	if not timeline.empty():
		start(timeline)


func _process(delta):
	$TextBubble/NextIndicator.visible = finished
	if waiting_for_answer and Input.is_action_just_released(input_next):
		if $Options.get_child_count() > 0:
			$Options.get_child(0).grab_focus()


func _input(event: InputEvent) -> void:
	if not Engine.is_editor_hint() and event.is_action_pressed(input_next) and not waiting:
		if tween_node.is_active():
			# Skip to end if key is pressed during the text animation
			tween_node.seek(999)
			finished = true
		else:
			if waiting_for_answer == false and waiting_for_input == false:
				_load_next_event(runtime_id)
		if settings.has_section_key('dialog', 'propagate_input'):
			var propagate_input: bool = settings.get_value('dialog', 'propagate_input')
			if not propagate_input:
				get_tree().set_input_as_handled()
