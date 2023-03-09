class_name DialogicNode_DialogText
extends RichTextLabel

## Dialogic node that can reveal text at a given (changeable speed). 

signal started_revealing_text()
signal continued_revealing_text(new_character)
signal finished_revealing_text()
enum ALIGNMENT {LEFT, CENTER, RIGHT}

@export var alignment : ALIGNMENT = ALIGNMENT.LEFT

var revealing := false
var speed:float = 0.01
var speed_counter:float = 0

func _ready() -> void:
	# add to necessary
	add_to_group('dialogic_dialog_text')
	
	bbcode_enabled = true
	text = ""



# this is called by the DialogicGameHandler to set text
func reveal_text(_text:String) -> void:
	speed = DialogicUtil.get_project_setting('dialogic/text/speed', 0.01)
	text = _text
	if alignment == ALIGNMENT.CENTER:
		text = '[center]'+text
	elif alignment == ALIGNMENT.RIGHT:
		text = '[right]'+text
	visible_characters = 0
	revealing = true
	speed_counter = 0
	emit_signal('started_revealing_text')

# called by the timer -> reveals more text
func continue_reveal() -> void:
	if visible_characters < get_total_character_count():
		revealing = false
		await Dialogic.Text.execute_effects(visible_characters, self, false)
		revealing = true
		visible_characters += 1
		emit_signal("continued_revealing_text", get_parsed_text()[visible_characters-2])
	else:
		finish_text()

# shows all the text imidiatly
# called by this thing itself or the DialogicGameHandler
func finish_text() -> void:
	visible_ratio = 1
	Dialogic.Text.execute_effects(-1, self, true)
	revealing = false
	Dialogic.current_state = Dialogic.states.IDLE
	emit_signal("finished_revealing_text")


# Calls continue_reveal. Used instead of a timer to allow multiple reveals per frame.
func _process(delta:float) -> void:
	if !revealing or Dialogic.paused:
		return
	speed_counter += delta
	while speed_counter > speed and revealing and !Dialogic.paused:
		speed_counter -= speed
		continue_reveal()
