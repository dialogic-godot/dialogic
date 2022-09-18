extends RichTextLabel

class_name DialogicNode_DialogText


enum ALIGNMENT {LEFT, CENTER, RIGHT}

@export var Align : ALIGNMENT = ALIGNMENT.LEFT
@onready var timer :Timer = null

var effect_regex = RegEx.new()
var modifier_words_select_regex = RegEx.new()
var effects:Array = []

var speed:float = 0.01

signal started_revealing_text()

signal continued_revealing_text(new_character)

signal finished_revealing_text()

func _ready() -> void:
	# add to necessary
	add_to_group('dialogic_dialog_text')
	
	bbcode_enabled = true
	text = ""
	
	# setup my timer
	timer = Timer.new()
	add_child(timer)
	timer.wait_time = 0.01
	timer.one_shot = true
	DialogicUtil.update_timer_process_callback(timer)
	timer.timeout.connect(continue_reveal)
	
	# compile effects regex
	effect_regex.compile("(?<!\\\\)\\[\\s*(?<command>mood|portrait|speed|signal|pause)\\s*(=\\s*(?<value>.+?)\\s*)?\\]")
	
	# compule modifier regexs
	modifier_words_select_regex.compile("(?<!\\\\)\\[[^\\[\\]]+(,[^\\]]*)\\]")
	
# this is called by the DialogicGameHandler to set text
func reveal_text(_text:String) -> void:
	speed = DialogicUtil.get_project_setting('dialogic/text/speed', 0.01)
	text = parse_effects(parse_modifiers(_text))
	if Align == ALIGNMENT.CENTER:
		text = '[center]'+text
	elif Align == ALIGNMENT.RIGHT:
		text = '[right]'+text
	visible_characters = 0
	if speed <= 0:
		timer.start(0.01)
	else:
		timer.start(speed) 
	emit_signal('started_revealing_text')

# called by the timer -> reveals more text
func continue_reveal() -> void:
	if visible_characters < get_total_character_count():
		visible_characters += 1
		emit_signal("continued_revealing_text", text[visible_characters-1])
		execute_effects()
		if timer.is_stopped():
			if speed <= 0:
				continue_reveal()
			else:
				timer.start(speed)
	else:
		
		finish_text()

# shows all the text imidiatly
# called by this thing itself or the DialogicGameHandler
func finish_text() -> void:
	visible_ratio = 1
	execute_effects(true)
	timer.stop()
	Dialogic.current_state = Dialogic.states.IDLE
	emit_signal("finished_revealing_text")


func parse_effects(_text:String) -> String:
	effects.clear()
	var position_correction = 0
	for effect_match in effect_regex.search_all(_text):
		# append [index, command, value] to effects array
		effects.append([effect_match.get_start()-position_correction, effect_match.get_string('command'), effect_match.get_string('value').strip_edges()])
		
		## TODO MIGHT BE BROKEN, because I had to replace string.erase for godot 4
		_text = _text.substr(0,effect_match.get_start()-position_correction)+_text.substr(effect_match.get_start()-position_correction+len(effect_match.get_string()))
		
		position_correction += len(effect_match.get_string())
	_text = _text.replace('\\[', '[')
	return _text

func execute_effects(skip :bool= false) -> void:
	# might have to execute multiple effects
	while effects and (visible_characters >= effects.front()[0] or visible_characters== -1):
		var effect = effects.pop_front()
		match effect[1]:
			'pause':
				if skip:
					continue
				if effect[2].is_valid_float():
					timer.start(effect[2].to_float())
				else:
					timer.start(1)
			'speed':
				if skip:
					continue
				if effect[2].is_valid_float():
					speed = effect[2].to_float()
				else:
					speed = DialogicUtil.get_project_setting('dialogic/text/speed', 0.01)
			'signal':
				Dialogic.emit_signal("text_signal", effect[2])
			'portrait':
				if effect[2]:
					if Dialogic.current_state_info.get('character', null):
						Dialogic.Portraits.change_portrait(load(Dialogic.current_state_info.character), effect[2])
			'mood':
				if effect[2]:
					if Dialogic.current_state_info.get('character', null):
						var Character = load(Dialogic.current_state_info.character)
						Dialogic.Text.update_typing_sound_mood(Character.custom_info.get('sound_moods', {}).get(effect[2], {}))

func parse_modifiers(_text:String) -> String:
	# [word, select] effect
	for replace_mod_match in modifier_words_select_regex.search_all(_text):
		var string = replace_mod_match.get_string().trim_prefix("[").trim_suffix("]")
		string = string.replace('\\,', '<comma>')
		var list = string.split(',')
		var item = list[randi()%len(list)]
		item = item.replace('<comma>', ',')
		_text = _text.replace(replace_mod_match.get_string(), item.strip_edges())
	
	# [br] effect
	_text = _text.replace('[br]', '\n')
	return _text

func pause() -> void: 
	timer.stop()

func resume() -> void:
	continue_reveal()
