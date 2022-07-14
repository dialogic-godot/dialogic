extends RichTextLabel

class_name DialogicDisplay_DialogText, "icon.png"

export(String, 'Left', 'Center', 'Right') var Align :String = 'Left'
onready var timer = null

var effect_regex = RegEx.new()
var modifier_words_select_regex = RegEx.new()
var effects:Array = []

var speed:float = 0.01

signal started_revealing_text()

signal continued_revealing_text(new_character)

func _ready() -> void:
	# add to necessary
	add_to_group('dialogic_dialog_text')
	
	bbcode_enabled = true
	
	# setup my timer
	timer = Timer.new()
	add_child(timer)
	timer.wait_time = 0.01
	timer.one_shot = true
	timer.connect("timeout", self, 'continue_reveal')
	
	# compile effects regex
	effect_regex.compile("(?<!\\\\)\\[(?<command>[^\\[=,]*)(=(?<value>[^\\[]*))?\\]")
	
	# compule modifier regexs
	modifier_words_select_regex.compile("(?<!\\\\)\\[[^\\[]+(,[^\\]]*)\\]")
	
# this is called by the DialogicGameHandler to set text
func reveal_text(_text:String) -> void:
	bbcode_text = parse_effects(parse_modifiers(_text))
	if Align == 'Center':
		bbcode_text = '[center]'+bbcode_text
	elif Align == 'Right':
		bbcode_text = '[right]'+bbcode_text
	visible_characters = 0
	timer.start(speed)
	emit_signal('started_revealing_text')

# called by the timer -> reveals more text
func continue_reveal() -> void:
	if visible_characters < len(bbcode_text):
		visible_characters += 1
		emit_signal("continued_revealing_text", bbcode_text[visible_characters-1])
		execute_effects()
		if timer.is_stopped():
			if speed == 0:
				continue_reveal()
			else:
				timer.start(speed)
	else:
		finish_text()

# shows all the text imidiatly
# called by this thing itself or the DialogicGameHandler
func finish_text():
	percent_visible = 1
	execute_effects(true)
	timer.stop()
	Dialogic.current_state = Dialogic.states.IDLE


func parse_effects(_text:String) -> String:
	effects.clear()
	var position_correction = 0
	for effect_match in effect_regex.search_all(_text):
		# append [index, command, value] to effects array
		effects.append([effect_match.get_start()-position_correction, effect_match.get_string('command'), effect_match.get_string('value').strip_edges()])
		
		_text.erase(effect_match.get_start()-position_correction, len(effect_match.get_string()))
		position_correction += len(effect_match.get_string())
	_text = _text.replace('\\[', '[')
	return _text

func execute_effects(skip :bool= false) -> void:
	# might have to execute multiple effects
	while effects and (visible_characters >= effects.front()[0] or visible_characters== -1):
		var effect = effects.pop_front()
		print(effect)
		match effect[1]:
			'pause':
				if skip:
					continue
				if effect[2].is_valid_float():
					timer.start(float(effect[2]))
				else:
					timer.start(1)
			'speed':
				if skip:
					continue
				if effect[2].is_valid_float():
					speed = float(effect[2])
			'signal':
				Dialogic.emit_signal("text_signal", effect[2])
			'portrait':
				if effect[2]:
					if Dialogic.current_state_info.get('character', null):
						Dialogic.update_portrait(Dialogic.current_state_info.get('character'), effect[2])

func parse_modifiers(_text:String) -> String:
	for replace_mod_match in modifier_words_select_regex.search_all(_text):
		var string = replace_mod_match.get_string().trim_prefix("[").trim_suffix("]")
		string = string.replace('\\,', '<comma>')
		var list = string.split(',')
		var item = list[randi()%len(list)]
		item = item.replace('<comma>', ',')
		_text = _text.replace(replace_mod_match.get_string(), item.strip_edges())
	return _text
