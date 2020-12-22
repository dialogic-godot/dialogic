tool
extends Control
class_name DialogNode, "res://addons/dialogic/Images/icon.svg"

var input_next = 'ui_accept'
var dialog_index = 0
var finished = false
var text_speed = 0.02 # Higher = lower speed
var waiting_for_answer = false
var waiting_for_input = false

export(String) var timeline_id # Timeline-var-replace

var dialog_resource
export(Array, Resource) var dialog_characters

onready var Portrait = load("res://addons/dialogic/Nodes/Portrait.tscn")
var dialog_script = {}

func parse_text(text):
	# This will parse the text and automatically format some of your available variables
	var end_text = text
	
	# for character variables
	if '{' and '}' in end_text:
		for c in dialog_characters: #dialog_resource.characters:
			if c.name in end_text:
				end_text = end_text.replace('{' + c.name + '}',
					'[color=#' + c.color.to_html() + ']' + c.name + '[/color]'
				)
		
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


func _ready():
	# Checking if the dialog should read the code from a external file
	if timeline_id != '':
		dialog_script = load_json(DialogicUtil.get_path('TIMELINE_DIR', '/' + timeline_id + '.json'))
		print(dialog_script)
	
	# Setting everything up for the node to be default
	$TextBubble/NameLabel.text = ''
	$Background.visible = false
	
	# Loading theme properties and settings
	var settings = DialogicUtil.load_settings()
	if settings.has('theme_font'):
		$TextBubble/RichTextLabel.set('custom_fonts/normal_font', load(settings['theme_font']))
	# Text
	if settings.has('theme_text_color'):
		$TextBubble/RichTextLabel.set('custom_colors/default_color', Color('#' + str(settings['theme_text_color'])))
	if settings.has('theme_text_shadow'):
		if settings['theme_text_shadow']:
			if settings.has('theme_text_shadow_color'):
				$TextBubble/RichTextLabel.set('custom_colors/font_color_shadow', Color('#' + str(settings['theme_text_shadow_color'])))
	if settings.has('theme_shadow_offset_x'):
		$TextBubble/RichTextLabel.set('custom_constants/shadow_offset_x', settings['theme_shadow_offset_x'])
	if settings.has('theme_shadow_offset_y'):
		$TextBubble/RichTextLabel.set('custom_constants/shadow_offset_y', settings['theme_shadow_offset_y'])
	
	if settings.has('theme_background_image'):
		$TextBubble/TextureRect.texture = load(settings['theme_background_image'])
	if settings.has('theme_next_image'):
		$TextBubble/NextIndicator.texture = load(settings['theme_next_image'])
	
	if settings.has('theme_action_key'):
		input_next = settings['theme_action_key']
	
	
	load_dialog()


func _process(_delta):
	$TextBubble/NextIndicator.visible = finished
	# Multiple choices
	if waiting_for_answer:
		$Options.visible = finished
	else:
		$Options.visible = false
	
	if Engine.is_editor_hint() == false:
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


func update_name(name_string, color='FFFFFF'):
	var parsed_name = parse_text(name_string)
	$TextBubble/NameLabel.bbcode_text = '[color=#' + color + ']' + parsed_name + '[/color]'
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


func get_character_variable(name):
	for c in dialog_characters:#dialog_resource.characters:
		if c.name == name:
			return c
	#push_error('DialogCharacterResource [' + name + '] does not exists. Make sure the name field is not empty.')
	return false


func reset_dialog_extras():
	$TextBubble/NameLabel.bbcode_text = ''


func event_handler(event):
	# Handling an event and updating the available nodes accordingly. 
	reset_dialog_extras()
	match event:
		{'text', 'character'}, {'text', 'character', ..}:
			show_dialog()
			finished = false
			#var character_data = get_character_variable(event['character'])
			##update_name(character_data.name, character_data.color.to_html())
			#var exists = false
			#var existing
			#for portrait in $Portraits.get_children():
			#	if portrait.character_data == character_data:
			#		exists = true
			#		existing = portrait
			#	else:
			#		portrait.focusout()
			#
			#if exists:
			#	existing.focus()
			#if exists == false:
			#	var p = Portrait.instance()
			#	p.character_data = character_data
			#	#p.debug = true
			#	if event.has('position'):
			#		p.init(event['position'])
			#	else:
			#		p.init('left') # Default character position
			#	$Portraits.add_child(p)
			#	p.fade_in()
			
			update_text(event['text'])
		{'question', ..}:
			show_dialog()
			finished = false
			waiting_for_answer = true
			if event.has('name'):
				update_name(event['name'])			
			update_text(event['question'])
			for o in event['options']:
				var button = Button.new()
				button.text = o['label']
				if event.has('variable'):
					button.connect("pressed", self, "_on_option_selected", [button, event['variable'], o])
				else:
					# Checking for checkpoints
					if o['value'] == '0':
						button.connect("pressed", self, "change_position", [button, int(event['checkpoint'])])
					else:
						# Continue
						button.connect("pressed", self, "change_position", [button, 0])
				$Options.add_child(button)
		{'input', ..}:
			show_dialog()
			finished = false
			waiting_for_input = true
			update_text(event['input'])
			$TextInputDialog.window_title = event['window_title']
			$TextInputDialog.popup_centered()
			$TextInputDialog.connect("confirmed", self, "_on_input_set", [event['variable']])
		{'action'}:
			if event['action'] == 'game_end':
				get_tree().quit()
			if event['action'] == 'clear_portraits':
				for p in $Portraits.get_children():
					p.fade_out()
				dialog_index += 1
				load_dialog(true)
			if event['action'] == 'focusout_portraits':
				for p in $Portraits.get_children():
					p.focusout()
				dialog_index += 1
				load_dialog(true)
		{'scene'}:
			get_tree().change_scene(event['scene'])
		{'background'}:
			$Background.visible = true
			$Background.texture = load(event['background'])
			dialog_index += 1
			load_dialog(true)
		{'fade-in'}:
			$FX/FadeInNode.modulate = Color(0,0,0,1)
			$FX/FadeInNode/Tween.interpolate_property(
				$FX/FadeInNode, "modulate", Color(0,0,0,1), Color(0,0,0,0), event['fade-in'],
				Tween.TRANS_LINEAR, Tween.EASE_IN_OUT
			)
			$FX/FadeInNode/Tween.start()
			dialog_index += 1
			load_dialog(true)
		{'sound'}:
			print('Play sound here: ', event)
			dialog_index += 1
			load_dialog()
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


func change_position(i, checkpoint):
	print('[!] Going back ', checkpoint, i)
	print('    From ', dialog_index, ' to ', dialog_index - checkpoint)
	waiting_for_answer = false
	dialog_index += checkpoint
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
	finished = true


func _on_TextInputDialog_confirmed():
	pass # Replace with function body.


func load_json(path):
	var file = File.new()
	if file.open(path, File.READ) != OK:
		file.close()
		return
	var data_text = file.get_as_text()
	file.close()
	var data_parse = JSON.parse(data_text)
	if data_parse.error != OK:
		return
	return data_parse.result
