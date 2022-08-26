tool
extends Control

## -----------------------------------------------------------------------------
## 						VARIABLES
## -----------------------------------------------------------------------------
## The timeline to load when starting the scene
var timeline: String
var timeline_name: String

### MODE
var preview: bool = false

var noSkipMode: bool = false
var autoPlayMode: bool = false
var autoWaitTime : float = 2.0

enum state {
	IDLE, # When nothing is happening
	READY, # When Dialogic already displayed the text on the screen
	TYPING, # While the editor is typing text
	WAITING, # Waiting a timer or something to finish
	WAITING_INPUT, # Waiting for player to answer a question
	ANIMATING # While performing a dialog animation
}
var _state : int = state.IDLE

var do_fade_in := true
var dialog_faded_in_already = false
# true if the glossary popup is visible: # TODO rename
var definition_visible: bool = false
# used to reset the mouse mode after questions:
var last_mouse_mode = null
# this is for switching back after a custom character theme was loaded
var current_default_theme = null

### SETTINGS
var settings: ConfigFile
var custom_events = {}
var record_history: bool = false

### DATA
var definitions = {}

# Parsing results
var questions #for keeping track of the questions answered
var anchors = {} # for listing the indexes of the anchors

### CURRENT STATE
var current_timeline: String = ''
var dialog_script: Dictionary = {}
var current_event: Dictionary
var dialog_index: int = 0
var is_last_text: bool

var current_background = ""

# Theme and Audio
var current_theme: ConfigFile
var current_theme_file_name = null
var history_theme: ConfigFile
var audio_data = {}

# References
var button_container = null

## -----------------------------------------------------------------------------
## 						SCENES
## -----------------------------------------------------------------------------
onready var ChoiceButton = load("res://addons/dialogic/Nodes/ChoiceButton.tscn")
onready var Portrait = load("res://addons/dialogic/Nodes/Portrait.tscn")
onready var Background = load("res://addons/dialogic/Nodes/Background.tscn")
onready var HistoryTimeline = $History

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
# Utility
signal letter_displayed(lastLetter)


## -----------------------------------------------------------------------------
## 						SCRIPT
## -----------------------------------------------------------------------------
func _ready():
	# Set this dialog as the latest (used for saving)
	Engine.get_main_loop().set_meta('latest_dialogic_node', self)
	# Loading the config files
	load_config_files()
	
	#update_custom_events()
	$CustomEvents.update()
		
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
	if !DialogicResources.get_settings_value('dialog', 'stop_mouse', true):
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Connecting some other timers
	$OptionsDelayedInput.connect("timeout", self, '_on_OptionsDelayedInput_timeout')
	# Setting everything up for the node to be default
	$DefinitionInfo.visible = false
	$TextBubble.connect("text_completed", self, "_on_text_completed")
	$TextBubble.connect("letter_written", self, "_on_letter_written")
	$TextBubble.connect("signal_request", self, "_on_signal_request")
	$TextBubble.text_label.connect('meta_hover_started', self, '_on_RichTextLabel_meta_hover_started')
	$TextBubble.text_label.connect('meta_hover_ended', self, '_on_RichTextLabel_meta_hover_ended')
	
	$TouchScreenButton.action = Dialogic.get_action_button()
	
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
	theme_file = settings.get_value('theme', 'default', 'default-theme.cfg')
	current_default_theme = theme_file
	current_theme = load_theme(theme_file)
	
	# history
	if settings.has_section('history'):
		record_history = settings.get_value('history', 'enable_history_logging', false)
		if settings.has_section_key('history', 'history_theme'):
			theme_file = settings.get_value('history', 'history_theme')
		history_theme = load_theme(theme_file)
		HistoryTimeline.load_theme(history_theme)
		if settings.has_section_key('history', 'enable_history_logging'):
			if settings.get_value('history', 'enable_history_logging'):
				HistoryTimeline.initalize_history()


## -----------------------------------------------------------------------------
## 						CUSTOM EVENTS
## -----------------------------------------------------------------------------
## not used anymore. use $CustomEvents.update()
func update_custom_events() -> void:
	custom_events = {}
	var path : String = DialogicResources.get_working_directories()["CUSTOM_EVENTS_DIR"]
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
	var margin_bottom = current_theme.get_value('box', 'box_margin_bottom', current_theme.get_value('box', 'box_margin_v', 40) * -1)
	var margin_top = current_theme.get_value('box', 'box_margin_top', current_theme.get_value('box', 'box_margin_v', 40))
	var margin_left = current_theme.get_value('box', 'box_margin_left', current_theme.get_value('box', 'box_margin_h', 40))
	var margin_right = current_theme.get_value('box', 'box_margin_right', current_theme.get_value('box', 'box_margin_h', 40) * -1)
	# first the y position
	if anchor in [0,1,2]: # TOP
		$TextBubble.rect_position.y = margin_top
	elif anchor in [4,5,6]: # CENTER
		$TextBubble.rect_position.y = (reference.y/2)-($TextBubble.rect_size.y/2)
	else:
		$TextBubble.rect_position.y = (reference.y) - ($TextBubble.rect_size.y) + margin_bottom
	
	# now x position
	if anchor in [0,4,8]: # LEFT
		$TextBubble.rect_position.x = margin_left
	elif anchor in [1,5,9]: # CENTER
		$TextBubble.rect_position.x = (reference.x / 2) - ($TextBubble.rect_size.x / 2)
	else:
		$TextBubble.rect_position.x = reference.x - ($TextBubble.rect_size.x) + margin_right
	
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
	
	if settings.get_value('input', 'clicking_dialog_action', true):
		$TouchScreenButton.shape.extents = reference
	
	# Background positioning
	var background = get_node_or_null('Background')
	if background != null:
		background.rect_size = reference
	
	var portraits = get_node_or_null('Portraits')
	if portraits != null:
		portraits.rect_position.x = reference.x / 2
		portraits.rect_position.y = reference.y

# calls resize_main
func deferred_resize(current_size, result, anchor):
	$TextBubble.rect_size = result
	if current_size != $TextBubble.rect_size or current_theme.get_value('box', 'anchor', 9) != anchor:
		resize_main()

# loads the given theme file
func load_theme(filename):
	var current_theme_anchor = -1
	if current_theme:
		current_theme_anchor = current_theme.get_value('box', 'anchor', 9)
	var load_theme = DialogicResources.get_theme_config(filename)
	if not load_theme:
		return current_theme 
	var theme = load_theme
	current_theme_file_name = filename
	# Box size
	call_deferred('deferred_resize', $TextBubble.rect_size, theme.get_value('box', 'size', Vector2(910, 167)), current_theme_anchor)
	
	$TextBubble.load_theme(theme)
	HistoryTimeline.change_theme(theme)
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
	
	if theme.get_value('box', 'portraits_behind_dialog_box', true):
		move_child($Portraits, 0)
	else:
		move_child($Portraits, 1)
	
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

# starts all necessary parsing
func load_dialog():
	# All this parse events should be happening in the same loop ideally
	# But until performance is not an issue I will probably stay lazy
	# And keep adding different functions for each parsing operation.
	if settings.get_value('dialog', 'auto_color_names', true):
		dialog_script = DialogicParser.parse_characters(dialog_script)
	dialog_script = DialogicParser.parse_text_lines(dialog_script, preview)
	dialog_script = DialogicParser.parse_branches(self, dialog_script)
	DialogicParser.parse_anchors(self)
	return dialog_script

## -----------------------------------------------------------------------------
## 					MAIN GAME-LOGIC 
## -----------------------------------------------------------------------------
# checks if NextIndicator and ChoiceButtons should be visible
func _process(delta):
	# Showing or hiding the ▼ next indicator
	$TextBubble/NextIndicatorContainer/NextIndicator.visible = is_state(state.READY)
	# Showing or hiding the container where the option buttons show up in questions
	$Options.visible = is_state(state.WAITING_INPUT)
	
	# Hide if no input is required
	if current_event.has('text'):
		if '[nw]' in current_event['text'] or '[nw=' in current_event['text'] or noSkipMode or autoPlayMode:
			$TextBubble/NextIndicatorContainer/NextIndicator.visible = false
		
	# Hide if "Don't Close After Last Event" is checked and event is last text
	if current_theme and current_theme.get_value('settings', 'dont_close_after_last_event', false) and is_last_text:
		$TextBubble/NextIndicatorContainer/NextIndicator.visible = false
	
	# Hide if fading in
	if is_state(state.ANIMATING):
		$TextBubble/NextIndicatorContainer/NextIndicator.visible = false
	

# checks for the "input_next" action
func _input(event: InputEvent) -> void:
	if not Engine.is_editor_hint() and event.is_action_pressed(Dialogic.get_action_button()) and autoPlayMode:
		autoPlayMode = false
		return
	
	if not Engine.is_editor_hint() and event.is_action_pressed(Dialogic.get_action_button()) and (!noSkipMode and !autoPlayMode):
		if HistoryTimeline.block_dialog_advance:
			return
		if is_state(state.WAITING):
			if not current_event:
				return
			var timer = current_event.get('waiting_timer_skippable')
			if timer:
				timer.time_left = 0
		else:
			if is_state(state.TYPING):
				# Skip to end if key is pressed during the text animation
				$TextBubble.skip()
				# Cut the voice
				$FX/CharacterVoice.stop_voice()
			else:
				if current_event.has('options') and !is_state(state.WAITING_INPUT):
					pass
				elif is_state(state.WAITING_INPUT) or is_state(state.ANIMATING):
					pass
				elif $TextBubble/NextIndicatorContainer/NextIndicator.is_visible():
					$FX/CharacterVoice.stop_voice() # stop the current voice as well
					play_audio("passing")
					_load_next_event()
				else:
					next_event(false)
			if settings.has_section_key('dialog', 'propagate_input'):
				var propagate_input: bool = settings.get_value('dialog', 'propagate_input')
				if not propagate_input  and not is_state(state.WAITING_INPUT):
					get_tree().set_input_as_handled()

func next_event(discreetly: bool):
	$FX/CharacterVoice.stop_voice() # stop the current voice as well
	if !discreetly:
		play_audio("passing")
	_load_next_event()

# when the text finished showing
# plays audio, adds buttons, handles [nw]
func _on_text_completed():
	emit_signal('text_complete', current_event)
	
	play_audio('waiting')
	
	# Add the choice buttons for questions
	if current_event.has('options'):
		# Already showed the text, ready to show the option buttons
		set_state(state.WAITING_INPUT)
		
		var waiting_until_options_enabled = float(settings.get_value('input', 'delay_after_options', 0.1))
		$OptionsDelayedInput.start(waiting_until_options_enabled)

		for o in current_event['options']:
			if _should_add_choice_button(o):
				add_choice_button(o)
		
		# Auto focus
		$DialogicTimer.start(0.1); yield($DialogicTimer, "timeout")
		if settings.get_value('input', 'autofocus_choices', false):
			button_container.get_child(0).grab_focus()
		
	
	if current_event.has('text'):
		# Already showed the text, ready to show the ▼ next indicator button
		set_state(state.READY)
		
		# [p] needs more work
		# Setting the timer for how long to wait in the [nw] events
		if '[nw]' in current_event['text'] or '[nw=' in current_event['text'] or noSkipMode or autoPlayMode:
			var waiting_time = 2
			var current_index = dialog_index
			if '[nw=' in current_event['text']: # Regex stuff
				var regex = RegEx.new()
				regex.compile("\\[nw=(.+?)\\](.*?)")
				var result = regex.search(current_event['text'])
				var wait_settings = result.get_string()
				#Kva-hack. if the waiting time is set to 'v'
				#It will fetch waiting time from CharacterVoice.
				waiting_time = wait_settings.split('=')[1]
				if(waiting_time.begins_with('v')):
					waiting_time = $"FX/CharacterVoice".remaining_time()
				else:
					waiting_time = float(waiting_time)
				#print("Waiting time: " + String(waiting_time))
				#Remove these comments once replaced with proper code.				
				# - KvaGram
				#original line
				#waiting_time = float(wait_settings.split('=')[1])
			elif noSkipMode or autoPlayMode:
				waiting_time = autoWaitTime
				if current_event.has('voice_data'):
					waiting_time = $"FX/CharacterVoice".remaining_time()
				else:
					waiting_time = float(waiting_time)
			$DialogicTimer.start(waiting_time); yield($DialogicTimer, "timeout")
			if dialog_index == current_index:
				_load_next_event()

# When text reaches a [signal] command
# emits the dialogic signal with the argument
func _on_signal_request(name):
	emit_signal("dialogic_signal", name)

# emits timeline_start and handles autosaving
func on_timeline_start():
	if not Engine.is_editor_hint():
		if settings.get_value('saving', 'autosave', true):
			# save to the default slot
			Dialogic.save('', true)
	# TODO remove event_start in 2.0
	emit_signal("event_start", "timeline", timeline_name)
	emit_signal("timeline_start", timeline_name)

# emits timeline_end and handles autosaving
func on_timeline_end():
	if not Engine.is_editor_hint():
		if settings.get_value('saving', 'autosave', true):
			# save to the default slot
			Dialogic.save('', true)
	# TODO remove event_end in 2.0
	emit_signal("event_end", "timeline")
	emit_signal("timeline_end", timeline_name)

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
	# Updates whether the event is the last text box
	if dialog_index + 1 >= dialog_script['events'].size():
		is_last_text = true
	else:
		# Get next event
		var next_event = dialog_script['events'][dialog_index + 1]
		
		# If next event is Text Event, is_last_text is false
		if next_event['event_id'] == "dialogic_001":
			is_last_text = false
		
		# Else, if next event is End Branch, set is_last_text to whether the next after exceeds the size of events.
		elif 'end_branch_of' in next_event:
			is_last_text = dialog_index + 2 >= dialog_script['events'].size()
			
		# Else, if next event is Choice (and current event is not a Question)
		elif 'choice' in next_event and not 'options' in dialog_script['events'][dialog_index]:
			# Get Question
			var index_in_questions = next_event['question_idx']
			var question = questions[index_in_questions]
			var index_in_events = dialog_script['events'].rfind(question, dialog_index)
			var end_index = question['end_idx']
			is_last_text = end_index + 1 >= dialog_script['events'].size()
	
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
			# If setting 'Don't Close After Last Event' is not checked, free it.
			if not current_theme.get_value('settings', 'dont_close_after_last_event', false):
				queue_free()

# Handling an event and updating the available nodes accordingly.
func event_handler(event: Dictionary):
	$TextBubble.reset()
	clear_options()
	
	current_event = event
	
	if record_history:
		HistoryTimeline.add_history_row_event(current_event)
	
	match event['event_id']:
		# MAIN EVENTS
		# Text Event
		'dialogic_001':
			emit_signal("event_start", "text", event)
			if fade_in_dialog():
				yield(get_node('fade_in_tween_show_time'), 'tween_completed')
			set_state(state.TYPING)
			if event.has('character'):
				var character_data = DialogicUtil.get_character(event['character'])
				grab_portrait_focus(character_data, event)
				if character_data.get('data', {}).get('theme', '') and current_theme_file_name != character_data.get('data', {}).get('theme', ''):
					current_theme = load_theme(character_data.get('data', {}).get('theme', ''))
				elif !character_data.get('data', {}).get('theme', '') and current_default_theme and  current_theme_file_name != current_default_theme:
					current_theme = load_theme(current_default_theme)
				update_name(character_data)

			#voice 
			handle_voice(event)
			update_text(event['text'])
		# Character event
		'dialogic_002':
			## PLEASE UPDATE THIS! BUT HOW? 
			emit_signal("event_start", "action", event)
			set_state(state.WAITING)
			if event['character'] == '':# No character found on the event. Skip.
				_load_next_event()
			else:
				var character_data = DialogicUtil.get_character(event['character'])
				# JOIN MODE -------------------------------------------
				if event.get('type', 0) == 0 and not portrait_exists(character_data):
					# CREATE NEW PORTRAIT 
					var p = Portrait.instance()
					
					# SET DATA
					if current_theme.get_value('settings', 'single_portrait_mode', false):
						p.single_portrait_mode = true
					p.character_data = character_data
					p.dim_time = current_theme.get_value('animation', 'dim_time', 0.5)
					
					var char_portrait = get_portrait_name(event)
					p.init(char_portrait)
					p.set_mirror(event.get('mirror_portrait', false))
					
					# ADD IT TO THE SCENE
					$Portraits.add_child(p)
					p.move_to_position(get_character_position(event['position']))
					event = insert_animation_data(event, 'join', 'fade_in_up.gd')
					p.animate(event.get('animation', '[No Animation]'), event.get('animation_length', 1))
					p.current_state['character'] = event['character']
					p.current_state['position'] = event['position']
					
					# z_index
					$Portraits.move_child(p, get_portrait_z_index_point(event.get('z_index', 0)))
					p.z_index = event.get('z_index', 0)
					
					if event.get('animation_wait', false):
						yield(p, 'animation_finished')
					
			
				# LEAVE MODE -------------------------------------------
				elif event.get('type', 0) == 1:
					if event['character'] == '[All]':
						event = insert_animation_data(event, 'leave', 'fade_out_down.gd')
						characters_leave_all(event.get('animation', '[No Animation]'), event.get('animation_length', -1))
						if event.get('animation_wait', false):
							$DialogicTimer.start(event.get('animation_duration', 1))
							yield($DialogicTimer, "timeout")
					else:
						for p in $Portraits.get_children():
							if is_instance_valid(p) and p.character_data['file'] == event['character']:
								event = insert_animation_data(event, 'leave', 'fade_out_down.gd')
								p.animate(event.get('animation', 'instant_out.gd'), event.get('animation_length', 1), 1, true)
								if event.get('animation_wait', false):
									yield(p, 'animation_finished')
				
				# UPDATE MODE -------------------------------------------
				else:
					if portrait_exists(character_data):
						for portrait in $Portraits.get_children():
							if portrait.character_data.get('file', true) == character_data.get('file', false):
								# UPDATE PORTRAIT
								var portrait_name = get_portrait_name(event)
								if portrait_name != portrait.current_state['portrait']:
									portrait.set_portrait(portrait_name)
									# recalculate the position of the portrait with an instant animation
									portrait.move_to_position(get_character_position(portrait.current_state['position']))
								
								# UPDATE POSITION
								if event.get('change_position', false):
									if event['position'] != portrait.current_state['position']:
										portrait.move_to_position(get_character_position(event['position']))
										portrait.current_state['position'] = event['position']
								
								if event.get('change_mirror_portrait', false):
									portrait.set_mirror(event.get('mirror_portrait', false))
								
								if event.get('change_z_index', false):
									$Portraits.move_child(portrait, get_portrait_z_index_point(event.get('z_index', 0)))
									portrait.z_index = event.get('z_index', 0)
								
								portrait.animate(event.get('animation', '[No Animation]'), event.get('animation_length', 1), event.get('animation_repeat', 1))
								
								if event.get('animation_wait', false) and event.get('animation', '[No Animation]') != "[No Animation]":
									yield(portrait, 'animation_finished')
				set_state(state.READY)
				_load_next_event()
		
		# LOGIC EVENTS
		# Question event
		'dialogic_010':
			emit_signal("event_start", "question", event)
			if fade_in_dialog():
				yield(get_node('fade_in_tween_show_time'), 'tween_completed')
			set_state(state.TYPING)
			if event.has('name'):
				update_name(event['name'])
			elif event.has('character'):
				var character_data = DialogicUtil.get_character(event['character'])
				grab_portrait_focus(character_data, event)
				
				if character_data.get('data', {}).get('theme', '') and current_theme_file_name != character_data.get('data', {}).get('theme', ''):
					current_theme = load_theme(character_data.get('data', {}).get('theme', ''))
				elif !character_data.get('data', {}).get('theme', '') and current_default_theme and  current_theme_file_name != current_default_theme:
					current_theme = load_theme(current_default_theme)
				update_name(character_data)
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
			
			var condition_met = def_value != null and DialogicUtil.compare_definitions(def_value, event['value'], event['condition']);
			
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
		# Anchor event
		'dialogic_015':
			emit_signal("event_start", "anchor", event)
			_load_next_event()
		# GoTo event
		'dialogic_016':
			emit_signal("event_start", "goto", event)
			dialog_index = anchors[event.get('anchor_id')]
			_load_next_event()
		
		
		# TIMELINE EVENTS
		# Change Timeline event
		'dialogic_020':
			if !event['change_timeline'].empty():
				change_timeline(event['change_timeline'])
		# Change Backround event
		'dialogic_021':
			emit_signal("event_start", "background", event)
			var fade_time = event.get('fade_duration', 1)
			var value = event.get('background', '')
			var background = get_node_or_null('Background')
			
			current_background = event['background']
			if background != null:
				background.name = "BackgroundFadingOut"
				if !value:
					background.fade_out(fade_time)
				else:
					background.remove_with_delay(fade_time)
				background = null
			
			if value != '':
				background = Background.instance()
				add_child(background)
				if (event['background'].ends_with('.tscn')):
					var bg_scene = load(event['background'])
					bg_scene = bg_scene.instance()
					background.modulate = Color(1,1,1,0)
					background.add_child(bg_scene)
					background.fade_in(fade_time)
				else:
					background.texture = load(value)
					background.fade_in(fade_time)
				call_deferred('resize_main') # Executing the resize main to update the background size
			
			_load_next_event()
		# Close Dialog event
		'dialogic_022':
			emit_signal("event_start", "close_dialog", event)
			set_state(state.ANIMATING)
			var transition_duration = event.get('transition_duration', 1.0)
			
			# fade out characters
			insert_animation_data(event, 'leave', 'fade_out_down')
			characters_leave_all(event['animation'], event['animation_length'])
			
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
			if event.get('hide_dialogbox', true):
				$TextBubble.visible = false
			set_state(state.WAITING)
			var timer = get_tree().create_timer(event['wait_seconds'])
			if event.get('waiting_skippable', false):
				event['waiting_timer_skippable'] = timer
			yield(timer, "timeout")
			event.erase('waiting_timer_skippable')
			set_state(state.IDLE)
			$TextBubble.visible = true
			emit_signal("event_end", "wait")
			_load_next_event()
		# Set Theme event
		'dialogic_024':
			emit_signal("event_start", "set_theme", event)
			if event['set_theme'] != '':
				current_theme = load_theme(event['set_theme'])
				current_default_theme = event['set_theme']
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
			emit_signal("event_start", "call_node", event)
			$TextBubble.visible = false
			set_state(state.WAITING)
			var target = get_node_or_null(event['call_node']['target_node_path'])
			if not target:
				target = get_tree().root.get_node_or_null(event['call_node']['target_node_path'])
			var method_name = event['call_node']['method_name']
			var args = event['call_node']['arguments']
			if (not args is Array):
				args = []

			if is_instance_valid(target):
				if target.has_method(method_name):
					var func_result = target.callv(method_name, args)
					
					if (func_result is GDScriptFunctionState):
						yield(func_result, "completed")

			set_state(state.IDLE)
			$TextBubble.visible = true
			_load_next_event()
		'dialogic_050':
			noSkipMode = event['block_input']
			autoWaitTime = event['wait_time']
			_load_next_event()
		_:
			if event['event_id'] in $CustomEvents.handlers.keys():
				# get the handler node
				var handler = $CustomEvents.handlers[event['event_id']]
				handler.handle_event(event, self)
			else:
				visible = false
				
func change_timeline(timeline):
	dialog_script = set_current_dialog(timeline)
	_init_dialog()


## -----------------------------------------------------------------------------
## 					TEXTBOX-FUNCTIONALITY
## -----------------------------------------------------------------------------
# updates the Name Label
func update_name(character) -> void:
	if character.has('name'):
		var parsed_name = character['name']
		if character['data'].get('display_name_bool', false):
			if character['display_name'] != '':
				parsed_name = character['display_name']
		parsed_name = DialogicParser.parse_definitions(self, parsed_name, true, false)
		$TextBubble.update_name(parsed_name, character.get('color', Color.white), current_theme.get_value('name', 'auto_color', true))
	else:
		$TextBubble.update_name('')

# shows the given text in the Text Bubble
# handles the simple translation feature
func update_text(text: String) -> String:
	if settings.get_value('dialog', 'translations', false):
		text = tr(text)
	var final_text = DialogicParser.parse_definitions(self, DialogicParser.parse_alignment(self, text))
	final_text = final_text.replace('[br]', '\n')

	$TextBubble.update_text(final_text)
	return final_text

# plays a sound
func _on_letter_written(lastLetter):
	if lastLetter != ' ':
		play_audio('typing')
	emit_signal('letter_displayed', lastLetter)


## -----------------------------------------------------------------------------
## 						CHOICE/OPTION BUTTONS
## -----------------------------------------------------------------------------

# called when a choice is selected
# hides choices, sets question as answered and jumps to the appropriate event
func answer_question(i, event_idx, question_idx):
	play_audio("selecting")
	
	clear_options()
	
	# set flags and continue dialog
	questions[question_idx]['answered'] = true
	_load_event_at_index(event_idx + 1)
	
	if record_history:
		HistoryTimeline.add_answer_to_question(str(i.text))
	
	# Revert to last mouse mode when selection is done
	if last_mouse_mode != null:
		Input.set_mouse_mode(last_mouse_mode) 
		last_mouse_mode = null

# deletest the choice buttons
func clear_options():
	# Clearing out the options after one was selected.
	for option in button_container.get_children():
		option.queue_free()

# adds a button for the given choice
func add_choice_button(option: Dictionary) -> Button:
	var button = get_classic_choice_button(option['label'])
	button_container.set('custom_constants/separation', current_theme.get_value('buttons', 'gap', 20))
	button_container.add_child(button)
	
	var hotkey
	var buttonCount = button_container.get_child_count()
	var hotkeyOption = settings.get_value('input', str('choice_hotkey_', buttonCount), '')
	
	# If there is a hotkey, use that key
	if hotkeyOption != '' and hotkeyOption != '[None]':
		hotkey = InputEventAction.new()
		hotkey.action = hotkeyOption
	# otherwise default hotkeys are 1-9 for the first 10 buttons
	elif buttonCount < 10 and settings.get_value('input', 'enable_default_shortcut', false):
		hotkey = InputEventKey.new()
		hotkey.scancode = OS.find_scancode_from_string(str(button_container.get_child_count()))
	else:
		hotkey = InputEventKey.new()
	
	if hotkeyOption != '[None]' or settings.get_value('input', 'enable_default_shortcut', false) == true:
		var shortcut = ShortCut.new()
		shortcut.set_shortcut(hotkey)
		
		button.set_shortcut(shortcut)
		button.shortcut_in_tooltip = false
	
	# Selecting the first button added
	if settings.get_value('input', 'autofocus_choices', false):
		if button_container.get_child_count() == 1:
			button.grab_focus()
	else:
		button.focus_mode = FOCUS_NONE
	
	# Adding audio when focused or hovered
	button.connect('focus_entered', self, '_on_option_hovered', [button])
	button.connect('mouse_entered', self, '_on_option_focused')
	
	button.set_meta('event_idx', option['event_idx'])
	button.set_meta('question_idx', option['question_idx'])

	if Input.get_mouse_mode() != Input.MOUSE_MODE_VISIBLE:
		last_mouse_mode = Input.get_mouse_mode()
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE) # Make sure the cursor is visible for the options selection
	
	return button

# checks the condition of the given option
func _should_add_choice_button(option: Dictionary):
	if not option['definition'].empty():
		var def_value = null
		for d in definitions['variables']:
			if d['id'] == option['definition']:
				def_value = d['value']
		return def_value != null and DialogicUtil.compare_definitions(def_value, option['value'], option['condition']);
	else:
		return true

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
	button.set_meta('input_next', Dialogic.get_action_button())
	
	# Removing the blue selected border
	button.set('custom_styles/focus', StyleBoxEmpty.new())
	# Text
	button.set('custom_fonts/font', DialogicUtil.path_fixer_load(theme.get_value('text', 'font', "res://addons/dialogic/Example Assets/Fonts/DefaultFont.tres")))


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
	# Default hover style
	var hover_style = [true, Color( 0.698039, 0.698039, 0.698039, 1 ), false, Color.black, true, default_background, false, Color.white]
	
	var style_normal = theme.get_value('buttons', 'normal', default_style)
	var style_hover = theme.get_value('buttons', 'hover', hover_style)
	var style_focus = theme.get_value('buttons', 'focus', hover_style)
	var style_pressed = theme.get_value('buttons', 'pressed', default_style)
	var style_disabled = theme.get_value('buttons', 'disabled', default_style)
	
	# Text color
	var default_color = Color(theme.get_value('text', 'color', '#ffffff'))
	button.set('custom_colors/font_color', default_color)
	button.set('custom_colors/font_color_hover', default_color.lightened(0.2))
	button.set('custom_colors/font_color_focus', default_color.lightened(0.2))
	button.set('custom_colors/font_color_pressed', default_color.darkened(0.2))
	button.set('custom_colors/font_color_disabled', default_color.darkened(0.8))
	
	if style_normal[0]:
		button.set('custom_colors/font_color', style_normal[1])
	if style_hover[0]:
		button.set('custom_colors/font_color_hover', style_hover[1])
	if style_focus[0]:
		button.set('custom_colors/font_color_focus', style_focus[1])
	if style_pressed[0]:
		button.set('custom_colors/font_color_pressed', style_pressed[1])
	if style_disabled[0]:
		button.set('custom_colors/font_color_disabled', style_disabled[1])
	

	# Style normal
	button_style_setter('normal', style_normal, button, theme)
	button_style_setter('hover', style_hover, button, theme)
	button_style_setter('focus', style_focus, button, theme)
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
	for portrait in $Portraits.get_children():
		# check if it's the same character
		if portrait.character_data.get("file", "something") == character_data.get("file", "none"):
			exists = true
			portrait.focus()
			if event.has('portrait'):
				portrait.set_portrait(get_portrait_name(event))
				if settings.get_value('dialog', 'recenter_portrait', true):
					portrait.move_to_position(portrait.direction)
		else:
			portrait.focusout(Color(current_theme.get_value('animation', 'dim_color', '#ff808080')))
	return exists

# returns true if the a portrait for that character already exists
func portrait_exists(character_data) -> bool:
	var exists = false
	for portrait in $Portraits.get_children():
		if portrait.character_data.get('file', true) == character_data.get('file', false):
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

# returns the portrait name or the definition value (id definition is enabled)
func get_portrait_name(event_data):
	var char_portrait = event_data['portrait']
	if char_portrait == '':
		char_portrait = "(Don't change)"
	
	if char_portrait == '[Definition]' and event_data.has('port_defn'):
		var portrait_definition = event_data['port_defn']
		if portrait_definition != '':
			for d in Dialogic._get_definitions()['variables']:
				if d['id'] == portrait_definition:
					char_portrait = d['value']
					break
	return char_portrait


func insert_animation_data(event_data, type = 'join', default = 'fade_in_up'):
	var animation = event_data.get('animation', '[Default]')
	var length = event_data.get('animation_length', 0.5)
	if animation == '[Default]':
		animation = DialogicResources.get_settings_value('animations', 'default_'+type+'_animation', default)
		length = DialogicResources.get_settings_value('animations', 'default_'+type+'_animation_length', 0.5)
	event_data['animation'] = animation
	event_data['animation_length'] = length
	return event_data
	
# moves out all portraits
func characters_leave_all(animation, time):
	var portraits = get_node_or_null('Portraits')
	if portraits != null:
		for p in portraits.get_children():
			p.animate(animation, time, 1, true)

# returns where to move the portrait, so the fake-z-index looks good 
func get_portrait_z_index_point(z_index):
	for i in range($Portraits.get_child_count()):
		if $Portraits.get_child(i).z_index >= z_index:
			return i
	return $Portraits.get_child_count()
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
				'body': DialogicParser.parse_definitions(self, d['text'], true, false), # inserts variables but not other glossary items!
				'extra': d['extra'],
			})
			correct_type = true

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
## 					DIALOG FADING
## -----------------------------------------------------------------------------
# Since Dialogic has some placeholder text in case something goes wrong
# This will reset the text, reset any modulation it might have, and
# set the variables that handle the fade in to the start position
func _hide_dialog():
	$TextBubble.clear() # Clearing the text
	$TextBubble.modulate = Color(1,1,1,0)
	dialog_faded_in_already = false

# start a fade in animation
func fade_in_dialog(time = 0.5):
	visible = true
	time = current_theme.get_value('animation', 'show_time', 0.5)
	var has_tween = false
	
	if Engine.is_editor_hint() == false:
		if dialog_faded_in_already == false and do_fade_in:
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
			set_state(state.ANIMATING)
			dialog_faded_in_already = true
			return true
	return false

# at the end of fade animation, reset flags
func finished_fade_in_dialog(object, key, node):
	node.queue_free()
	if !current_event.has('options'):
		set_state(state.IDLE)
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
		state['portraits'][-1]['z_index'] = portrait.z_index

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
		var character_data = DialogicUtil.get_character(event['character'])
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
			p.dim_time = current_theme.get_value('animation', 'dim_time', 0.5)
			p.character_data = character_data
			p.init(char_portrait)

			p.set_mirror(event.get('mirror', false))
			$Portraits.add_child(p)
			$Portraits.move_child(p, get_portrait_z_index_point(saved_portrait.get('z_index', 0)))
			p.move_to_position(get_character_position(event['position']))
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


## -----------------------------------------------------------------------------
##                  Finite State Machine
## -----------------------------------------------------------------------------
#  At the moment both functions are helpers only, but the goal of making them
#  as functions and not a simple `_state = whatever` is to also perform certain
#  actions when changing from state to state. If needed in the future, we can
#  also emit signals and stuff like that without having to go back to every 
#  state change in the code.

func set_state(new_state):
	var state_string = [ "IDLE", "READY", "TYPING", "WAITING", "WAITING_INPUT", "ANIMATING", ]
	#print(state_string[new_state])
	_state = new_state
	return _state

func is_state(check_state):
	if _state == check_state:
		return true
	return false
