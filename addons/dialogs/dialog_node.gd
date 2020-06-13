extends Control

var input_next = 'ui_accept'
var dialog_index = 0
var finished = false
var text_tween_duration = 1.0
var waiting_for_answer = false
var waiting_for_input = false
export(String, FILE, "*.json") var extenal_file = ''
var dialog_script = [
	{
		'fade-in': 2
	},
	{
		'background': "res://addons/dialogs/Images/background/placeholder-2.png"
	},
	{
		'text': 'Welcome to the dialog node! You can pick options'
	},
	{
		'question': 'Choose your favourite color',
		'options': [
			{ 'label': 'Red', 'value': '#f7411d'},
			{ 'label': 'Blue', 'value': '#1da0f7'}
		],
		'variable': 'fav_color'
	},
	{
		'text': 'You picked the color [color=fav_color.value][fav_color][/color]'
	},
	{
		'question': 'Are you sure you want the color [fav_color]?',
		'options': [
			{ 'label': 'No, let me pick again', 'value': '0'},
			{ 'label': 'Yes, I love it', 'value': '1'}
		],
		'checkpoint': '-3'
	},
	{
		'input': 'Now the name you want to set.',
		'window_title': 'Write your name',
		'variable': 'name'
	},
	{
		'text': 'So, your name is [name] and you like the color [color=fav_color.value][fav_color][/color].'
	},
	{
		'name': '[color=fav_color.value][name][/color]',
		'text': 'I actually want to be able to pick more colors but you won\'t let me!'
	},
	{  
		'name': 'Dialog System',
		'text': 'It doesn\'t matter, this is only a demonstration!'
	},
	{
		'action': 'game_end'
	}
]

func file(file_path):
	# Reading a json file to use as a dialog.
	var file = File.new()
	var fileExists = file.file_exists(file_path)
	var dict = []
	if fileExists:
		file.open(file_path, File.READ)
		var content = file.get_as_text()
		dict = parse_json(content)
		file.close()
		return dict
	else:
		push_error("File " + file_path  + " doesn't exists. ")
	return dict

func parse_text(text):
	# This will parse the text and automatically format some of your available variables
	var end_text = text
	
	var c_variable
	for g in global.custom_variables:
		if global.custom_variables.has(g):
			c_variable = global.custom_variables[g]
			# If it is a dictionary, get the label key
			if typeof(c_variable) == TYPE_DICTIONARY:
				if c_variable.has('label'):
					if '.value' in end_text:
						end_text = end_text.replace(g + '.value', c_variable['value'])
					end_text = end_text.replace('[' + g + ']', c_variable['label'])
			# Otherwise, just replace the value
			else:
				end_text = end_text.replace('[' + g + ']', c_variable)
	return end_text

func _ready():
	# Checking if the dialog should read the code from a external file
	if extenal_file != '':
		dialog_script = file(extenal_file)
	# Setting everything up for the node to be default
	$TextBubble/NameLabel.text = ''
	$Background.visible = false
	$CloseUp.visible = false
	load_dialog()

func _process(delta):
	$TextBubble/NextIndicator.visible = finished
	# Multiple choices
	if waiting_for_answer:
		$Options.visible = finished
	else:
		$Options.visible = false
	
	if Input.is_action_just_pressed(input_next):
		if $TextBubble/Tween.is_active():
			# Skip to end if key is pressed during the text animation
			$TextBubble/Tween.seek(text_tween_duration)
			finished = true
		else:
			if waiting_for_answer == false and waiting_for_input == false:
				load_dialog()

func hide_dialog():
	visible = false

func show_dialog():
	visible = true

func start_text_tween():
	# This will start the animation that makes the text appear letter by letter
	$TextBubble/Tween.interpolate_property(
		$TextBubble/RichTextLabel, "percent_visible", 0, 1, text_tween_duration,
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT
	)
	$TextBubble/Tween.start()

func update_name(event):
	# This function will search for the name key and try to parse it into the NameLabel node of the dialog
	if event.has('name'):
		$TextBubble/NameLabel.bbcode_text = parse_text(event['name'])
		if '[name]' in event['name']:
			$CloseUp.visible = true
		else:
			$CloseUp.visible = false
	else:
		$TextBubble/NameLabel.bbcode_text = ''
		$CloseUp.visible = false

func update_text(text):
	# Updating the text and starting the animation from 0
	$TextBubble/RichTextLabel.bbcode_text = parse_text(text)
	$TextBubble/RichTextLabel.percent_visible = 0
	start_text_tween()
	return true

func load_dialog(skip_add = false):
	# This will load the next entry in the dialog_script array.
	if dialog_index < dialog_script.size():
		event_handler(dialog_script[dialog_index])
	else:
		queue_free()
	if skip_add == false:
		dialog_index += 1

func event_handler(event):
	# Handling an event and updating the available nodes accordingly. 
	match event:
		{'text'}, {'text', 'name'}:
			show_dialog()
			finished = false
			update_name(event)
			update_text(event['text'])
			
		{'question', ..}:
			show_dialog()
			finished = false
			waiting_for_answer = true
			update_name(event)
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
			hide_dialog()
			print('Other event. ', event)

func _on_input_set(variable):
	var input_value = $TextInputDialog/LineEdit.text
	if input_value == '':
		$TextInputDialog.popup_centered()
	else:
		global.custom_variables[variable] = input_value
		waiting_for_input = false
		$TextInputDialog/LineEdit.text = ''
		$TextInputDialog.disconnect("confirmed", self, '_on_input_set')
		$TextInputDialog.visible = false
		load_dialog()
		print('[!] Input selected: ', input_value)
		print(global.custom_variables)

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
	global.custom_variables[variable] = value
	waiting_for_answer = false
	reset_options()
	load_dialog()
	print('[!] Option selected: ', option.text, ' value= ' , value)
	print(global.custom_variables)

func _on_Tween_tween_completed(object, key):
	finished = true

func _on_TextInputDialog_confirmed():
	pass # Replace with function body.
