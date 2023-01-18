extends RichTextLabel

class_name DialogicNode_DialogText

## Dialogic node that can reveal text at a given (changeable speed). 

signal started_revealing_text()
signal continued_revealing_text(new_character)
signal finished_revealing_text()
enum ALIGNMENT {LEFT, CENTER, RIGHT}

@export var Align : ALIGNMENT = ALIGNMENT.LEFT
@onready var timer :Timer = null


var speed:float = 0.01

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


# this is called by the DialogicGameHandler to set text
func reveal_text(_text:String) -> void:
	speed = DialogicUtil.get_project_setting('dialogic/text/speed', 0.01)
	text = _text
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
		await Dialogic.Text.execute_effects(visible_characters, self, false)
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
	Dialogic.Text.execute_effects(-1, self, true)
	timer.stop()
	Dialogic.current_state = Dialogic.states.IDLE
	emit_signal("finished_revealing_text")


func pause() -> void: 
	timer.stop()

func resume() -> void:
	continue_reveal()
