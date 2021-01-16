tool
extends Control

var input_next: String = 'ui_accept'
var dialog_index: int = 0
var finished: bool = false
var text_speed = 0.02 # Higher = lower speed
var waiting_for_answer: bool = false
var waiting_for_input: bool = false
var glossary_visible: bool = false
var settings

#export(String) var timeline: String # Timeline-var-replace

export(String, "TimelineDropdown") var timeline: String
signal dialogic_signal(value)

var dialog_resource
var characters


onready var ChoiceButton = load("res://addons/dialogic/Nodes/ChoiceButton.tscn")
onready var Portrait = load("res://addons/dialogic/Nodes/Portrait.tscn")
var dialog_script = {}
var questions #for keeping track of the questions answered


func _ready():
	# Checking if the dialog should read the code from a external file
	if timeline != '':
		dialog_script = set_current_dialog('/' + timeline + '.json')
	
	# Connecting resize signal
	get_viewport().connect("size_changed", self, "resize_main")
	resize_main()
	
	# Setting everything up for the node to be default
	$TextBubble/NameLabel.text = ''
	$Background.visible = false
	$TextBubble/RichTextLabel.meta_underlined = false
	$GlossaryInfo.visible = false
	
	# Getting the character information
	characters = DialogicUtil.get_character_list()
	
	load_theme()
	load_dialog()


func resize_main():
	if Engine.is_editor_hint() == false:
		set_global_position(Vector2(0,0))
		rect_size = get_viewport().size


func set_current_dialog(dialog_path):
	var dialog_script = DialogicUtil.load_json(DialogicUtil.get_path('TIMELINE_DIR', dialog_path))
	dialog_script = parse_branches(dialog_script)
	return dialog_script


func parse_branches(unparsed_dialog_script: Dictionary) -> Dictionary:
	var parsed_dialog: Dictionary = unparsed_dialog_script
	questions = [] # Resetting the questions 
	var new_events: Array = []
	var event_id: int = 0
	var closed_question_index: int = 0
	for event in unparsed_dialog_script['events']:
		if event.has('question'):
			# recording the existance of a question
			questions.append({
				'event_id': event_id,
				'answered': false,
				'text': event['question'],
				'index': questions.size()
			})
		if event.has('choice'):
			var parent_question_id = questions.size() - closed_question_index - 1
			var c_question = questions[parent_question_id]
			
			event['question_id'] = c_question['index']
			new_events[c_question['event_id']]['options'].append({
				'question_id': c_question['index'],
				'label': event['choice'],
				'event_id': event_id
				})
		
		if event.has('endchoice'):
			var c_question = questions[questions.size() - closed_question_index - 1]
			print('closing question ', c_question)
			new_events[c_question['event_id']]['question_id'] = closed_question_index
			c_question['end_id'] = event_id
			closed_question_index += 1
		
		new_events.append(event)
		event_id += 1

	#print('----------------- Parsed events -------------------')
	#print(parsed_dialog)
	#print('------------------- Questions ---------------------')
	#print(questions)
	#print('---------------------------------------------------')
	parsed_dialog['events'] = new_events
	return parsed_dialog


func parse_text(text):
	# This will parse the text and automatically format some of your available variables
	var end_text = text
	
	# for character variables
	#if '{' and '}' in end_text:
	#	for c in characters: #dialog_resource.characters:
	#		if c.name in end_text:
	#			end_text = end_text.replace('{' + c.name + '}',
	#				'[color=#' + c.color.to_html() + ']' + c.name + '[/color]'
	#			)
		
	var c_variable
	#for key in dialog_resource.custom_variables.keys():
	#	c_variable = dialog_resource.custom_variables[key]
	#	# If it is a dictionary, get the label key
	#	if typeof(c_variable) == TYPE_DICTIONARY:
	#		if c_variable.has('label'):
	#			if '.value' in end_text:
	#				end_text = end_text.replace(key + '.value', c_variable['value'])
	#			end_text = end_text.replace('[' + key + ']', c_variable['label'])
	#	# Otherwise, just replace the value
	#	else:
	#		end_text = end_text.replace('[' + key + ']', c_variable)
	return end_text


func _process(_delta):
	$TextBubble/NextIndicator.visible = finished
	if glossary_visible: 
		if get_local_mouse_position().x - $GlossaryInfo.rect_size.x < 0:
			$GlossaryInfo.rect_global_position = get_global_mouse_position() - Vector2(0, $GlossaryInfo.rect_size.y)
		else:
			$GlossaryInfo.rect_global_position = get_global_mouse_position() - $GlossaryInfo.rect_size
	if Engine.is_editor_hint() == false:
		# Multiple choices
		if waiting_for_answer:
			$Options.visible = finished
		else:
			$Options.visible = false
		
		if Input.is_action_just_pressed(input_next):
			if $TextBubble/Tween.is_active():
				# Skip to end if key is pressed during the text animation
				$TextBubble/Tween.seek(999)
				finished = true
			else:
				if waiting_for_answer == false and waiting_for_input == false:
					load_dialog()


func show_dialog():
	visible = true


func start_text_tween():
	# This will start the animation that makes the text appear letter by letter
	var tween_duration = text_speed * $TextBubble/RichTextLabel.get_total_character_count()
	$TextBubble/Tween.interpolate_property(
		$TextBubble/RichTextLabel, "percent_visible", 0, 1, tween_duration,
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT
	)
	$TextBubble/Tween.start()


func update_name(character, color='FFFFFF'):
	if character.has('name'):
		var parsed_name = character['name']
		if character.has('display_name'):
			if character['display_name'] != '':
				parsed_name = character['display_name']
		if character.has('color'):
			color = character['color'].to_html()
		$TextBubble/NameLabel.bbcode_text = '[color=#' + color + ']' + parsed_name + '[/color]'
	else:
		$TextBubble/NameLabel.bbcode_text = ''
	return true


func update_text(text):
	# Updating the text and starting the animation from 0
	$TextBubble/RichTextLabel.bbcode_text = parse_text(text)
	$TextBubble/RichTextLabel.percent_visible = 0
	
	# The call to this function needs to be deferred. 
	# More info: https://github.com/godotengine/godot/issues/36381
	call_deferred("start_text_tween")
	return true


func load_dialog(skip_add = false):
	# This will load the next entry in the dialog_script array.
	if dialog_script.has('events'):
		if dialog_index < dialog_script['events'].size():
			event_handler(dialog_script['events'][dialog_index])
		else:
			if Engine.is_editor_hint() == false:
				queue_free()
	if skip_add == false:
		dialog_index += 1


func reset_dialog_extras():
	$TextBubble/NameLabel.bbcode_text = ''


func get_character(character_id):
	for c in characters:
		if c['file'] == character_id:
			return c
	return {}


func event_handler(event: Dictionary):
	# Handling an event and updating the available nodes accordingly. 
	reset_dialog_extras()
	match event:
		{'text', 'character'}, {'text', 'character', ..}:
			show_dialog()
			finished = false
			var character_data = get_character(event['character'])
			update_name(character_data)
			grab_portrait_focus(character_data)
			update_text(event['text'])
		{'question', ..}:
			show_dialog()
			finished = false
			waiting_for_answer = true
			if event.has('name'):
				update_name(event['name'])
			update_text(event['question'])
			if event.has('options'):
				for o in event['options']:
					add_choice_button(o)
		{'choice', 'question_id'}:
			var current_question = questions[event['question_id']]
			if current_question['answered']:
				# If the option is for an answered question, skip to the end of it.
				dialog_index = current_question['end_id']
				load_dialog(true)
			else:
				# It should never get here, but if it does, go to the next place.
				go_to_next_event()
		{'input', ..}:
			show_dialog()
			finished = false
			waiting_for_input = true
			update_text(event['input'])
			$TextInputDialog.window_title = event['window_title']
			$TextInputDialog.popup_centered()
			$TextInputDialog.connect("confirmed", self, "_on_input_set", [event['variable']])
		{'action', ..}:
			if event['action'] == 'leaveall':
				if event['character'] == '[All]':
					for p in $Portraits.get_children():
						p.fade_out()
				else:
					for p in $Portraits.get_children():
						if p.character_data['file'] == event['character']:
							p.fade_out()
					
				go_to_next_event()
			elif event['action'] == 'join':
				if event['character'] == '':
					go_to_next_event()
				else:
					var character_data = get_character(event['character'])
					var exists = grab_portrait_focus(character_data)
					if exists == false:
						var p = Portrait.instance()
						p.character_data = character_data
						# Todo: get current expression instead of 'Default'
						p.init('Default', get_character_position(event['position']))
						$Portraits.add_child(p)
						p.fade_in()
						go_to_next_event()
		#{'action'}:
		#	if event['action'] == 'game_end':
		#		get_tree().quit()
		#	if event['action'] == 'focusout_portraits':
		#		for p in $Portraits.get_children():
		#			p.focusout()
		#		dialog_index += 1
		#		load_dialog(true)
		{'scene'}:
			get_tree().change_scene(event['scene'])
		{'background'}:
			$Background.visible = true
			$Background.texture = load(event['background'])
			dialog_index += 1
			load_dialog(true)
		{'audio'}, {'audio', 'file'}:
			if event['audio'] == 'play':
				$FX/AudioStreamPlayer.stream = load(event['file'])
				$FX/AudioStreamPlayer.play()
			# Todo: audio stop
			go_to_next_event()
		{'endchoice'}:
			go_to_next_event()
		{'change_scene'}:
			get_tree().change_scene(event['change_scene'])
		{'emit_signal'}:
			print('[!] Emitting signal: ', event['emit_signal'])
			emit_signal("dialogic_signal", event['emit_signal'])
		{'close_dialog'}:
			queue_free()
		{'change_timeline'}:
			dialog_script = set_current_dialog('/' + event['change_timeline'])
			dialog_index = 0
			load_dialog(true)
		_:
			visible = false
			print('Other event. ', event)


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
		load_dialog()
		print('[!] Input selected: ', input_value)
		print('[!] dialog variables: ', dialog_resource.custom_variables)


func reset_options():
	# Clearing out the options after one was selected.
	for option in $Options.get_children():
		option.queue_free()


func add_choice_button(option):
	var button = ChoiceButton.instance()
	button.text = option['label']
	# Text
	button.set('custom_fonts/font', load(settings['theme_font']))
	
	button.set('custom_colors/font_color', Color(settings['theme_text_color']))
	button.set('custom_colors/font_color_hover', Color(settings['theme_text_color']))
	button.set('custom_colors/font_color_pressed', Color(settings['theme_text_color']))
	
	# This part makes me cry
	var current_color = settings['button_text_color']
	
	if settings['button_text_color_enabled']:
		button.set('custom_colors/font_color', Color(settings['button_text_color']))
		button.set('custom_colors/font_color_hover', Color(settings['button_text_color']))
		button.set('custom_colors/font_color_pressed', Color(settings['button_text_color']))
	# Background
	
	button.get_node('ColorRect').color = Color(settings['button_background'])
	button.get_node('ColorRect').visible = settings['button_background_visible']

	button.get_node('TextureRect').texture = load(settings['button_image'])
	button.get_node('TextureRect').visible = settings['button_image_visible']
	
	button.get_node('ColorRect').set('margin_left', -1 * settings['button_offset_x'])
	button.get_node('ColorRect').set('margin_right',  settings['button_offset_x'])
	button.get_node('ColorRect').set('margin_top', -1 * settings['button_offset_y'])
	button.get_node('ColorRect').set('margin_bottom', settings['button_offset_y'])
	
	button.get_node('TextureRect').set('margin_left', -1 * settings['button_offset_x'])
	button.get_node('TextureRect').set('margin_right',  settings['button_offset_x'])
	button.get_node('TextureRect').set('margin_top', -1 * settings['button_offset_y'])
	button.get_node('TextureRect').set('margin_bottom', settings['button_offset_y'])
	
	$Options.set('custom_constants/separation', settings['button_separation'] + (settings['button_offset_y']*2))

	button.connect("pressed", self, "answer_question", [button, option['event_id'], option['question_id']])
	
	$Options.add_child(button)

func answer_question(i, event_id, question_id):
	print('[!] Going to ', event_id + 1, i, 'question_id:', question_id)
	print('')
	waiting_for_answer = false
	dialog_index = event_id + 1
	questions[question_id]['answered'] = true
	print('    dialog_index = ', dialog_index)
	reset_options()
	load_dialog()


func _on_option_selected(option, variable, value):
	dialog_resource.custom_variables[variable] = value
	waiting_for_answer = false
	reset_options()
	load_dialog()
	print('[!] Option selected: ', option.text, ' value= ' , value)
	#print(dialog_resource.custom_variables)


func _on_Tween_tween_completed(object, key):
	#$TextBubble/RichTextLabel.meta_underlined = true
	finished = true


func _on_TextInputDialog_confirmed():
	pass # Replace with function body.


func go_to_next_event():
	# The entire event reading system should be refactored... but not today!
	dialog_index += 1
	load_dialog(true)


func grab_portrait_focus(character_data):
	var exists = false
	for portrait in $Portraits.get_children():
		if portrait.character_data == character_data:
			exists = true
			portrait.focus()
		else:
			portrait.focusout()
	return exists


func get_character_position(positions):
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
	return 


func load_theme() -> void:
	# Loading theme properties and settings
	settings = DialogicUtil.load_settings()

	$TextBubble/RichTextLabel.set('custom_fonts/normal_font', load(settings['theme_font']))
	$TextBubble/NameLabel.set('custom_fonts/normal_font', load(settings['theme_font']))
	
	# Glossary
	$GlossaryInfo/VBoxContainer/Title.set('custom_fonts/normal_font', load(settings['theme_font']))
	$GlossaryInfo/VBoxContainer/Content.set('custom_fonts/normal_font', load(settings['theme_font']))
	$GlossaryInfo/VBoxContainer/Extra.set('custom_fonts/normal_font', load(settings['theme_font']))
	
	# Text
	if settings.has('theme_text_color'):
		$TextBubble/RichTextLabel.set('custom_colors/default_color', Color(settings['theme_text_color']))
		$TextBubble/NameLabel.set('custom_colors/default_color', Color(settings['theme_text_color']))

	$TextBubble/RichTextLabel.set('custom_colors/font_color_shadow', Color('#00ffffff'))
	$TextBubble/NameLabel.set('custom_colors/font_color_shadow', Color('#00ffffff' ))
	if settings.has('theme_text_shadow'):
		if settings['theme_text_shadow']:
			if settings.has('theme_text_shadow_color'):
				$TextBubble/RichTextLabel.set('custom_colors/font_color_shadow', Color(settings['theme_text_shadow_color']))
				$TextBubble/NameLabel.set('custom_colors/font_color_shadow', Color(settings['theme_text_shadow_color']))
				
	if settings.has('theme_shadow_offset_x'):
		$TextBubble/RichTextLabel.set('custom_constants/shadow_offset_x', settings['theme_shadow_offset_x'])
		$TextBubble/NameLabel.set('custom_constants/shadow_offset_x', settings['theme_shadow_offset_x'])
	if settings.has('theme_shadow_offset_y'):
		$TextBubble/RichTextLabel.set('custom_constants/shadow_offset_y', settings['theme_shadow_offset_y'])
		$TextBubble/NameLabel.set('custom_constants/shadow_offset_y', settings['theme_shadow_offset_y'])
	# Text speed
	if settings.has('theme_text_speed'):
		text_speed = settings['theme_text_speed'] * 0.01
	# Margin
	if settings.has('theme_text_margin'):
		$TextBubble/RichTextLabel.set('margin_top', settings['theme_text_margin'])
		$TextBubble/RichTextLabel.set('margin_bottom', settings['theme_text_margin'] * -1)
	if settings.has('theme_text_margin_h'):
		$TextBubble/RichTextLabel.set('margin_left', settings['theme_text_margin_h'])
		$TextBubble/RichTextLabel.set('margin_right', settings['theme_text_margin_h'] * -1)
	
	# Backgrounds
	$TextBubble/TextureRect.texture = load(settings['theme_background_image'])
	$TextBubble/ColorRect.color = Color(settings['theme_background_color'])
	
	$TextBubble/ColorRect.visible = settings['theme_background_color_visible']
	$TextBubble/TextureRect.visible = settings['background_texture_button_visible']
	
	# Next image
	$TextBubble/NextIndicator.texture = load(settings['theme_next_image'])
	input_next = settings['theme_action_key']


func _on_RichTextLabel_meta_hover_started(meta):
	glossary_visible = true
	$GlossaryInfo.visible = glossary_visible
	# Adding a timer to avoid a graphical glitch
	$GlossaryInfo/Timer.stop()
	

func _on_RichTextLabel_meta_hover_ended(meta):
	# Adding a timer to avoid a graphical glitch
	$GlossaryInfo/Timer.start(0.1)


func _on_Glossary_Timer_timeout():
	# Adding a timer to avoid a graphical glitch
	glossary_visible = false
	$GlossaryInfo.visible = glossary_visible
