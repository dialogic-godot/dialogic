class_name DialogicNode_DialogText
extends RichTextLabel

## Dialogic node that can reveal text at a given (changeable speed). 

signal started_revealing_text()
signal continued_revealing_text(new_character)
signal finished_revealing_text()
enum Alignment {LEFT, CENTER, RIGHT}

@export var enabled := true
@export var alignment := Alignment.LEFT
@export var textbox_root : Node = self

@export var hide_when_empty := false
@export var start_hidden := true

var revealing := false
var speed:float = 0.01
var speed_counter:float = 0



func _set(property, what):
	if property == 'text' and typeof(what) == TYPE_STRING:
		text = what
		if hide_when_empty:
			textbox_root.visible = !what.is_empty()
		return true


func _ready() -> void:
	# add to necessary
	add_to_group('dialogic_dialog_text')
	
	bbcode_enabled = true
	if start_hidden:
		textbox_root.hide()
	text = ""


# this is called by the DialogicGameHandler to set text
func reveal_text(_text:String) -> void:
	if !enabled:
		return
	
	speed = Dialogic.Settings.get_setting('text_speed', 0.01)
	text = _text
	show()
	if alignment == Alignment.CENTER:
		text = '[center]'+text
	elif alignment == Alignment.RIGHT:
		text = '[right]'+text
	visible_characters = 0
	revealing = true
	speed_counter = 0
	emit_signal('started_revealing_text')


# called by the timer -> reveals more text
func continue_reveal() -> void:
	if visible_characters <= get_total_character_count():
		revealing = false
		await Dialogic.Text.execute_effects(visible_characters, self, false)
		if visible_characters == -1:
			return
		revealing = true
		visible_characters += 1
		if visible_characters > -1 and visible_characters <= len(get_parsed_text()):
			continued_revealing_text.emit(get_parsed_text()[visible_characters-1])
	else:
		finish_text()
		# if the text finished organically, add a small input block
		# this prevents accidental skipping when you expected the text to be longer
		Dialogic.Text.input_handler.block_input(0.3)


# shows all the text imidiatly
# called by this thing itself or the DialogicGameHandler
func finish_text() -> void:
	visible_ratio = 1
	Dialogic.Text.execute_effects(-1, self, true)
	revealing = false
	Dialogic.current_state = Dialogic.States.IDLE
	emit_signal("finished_revealing_text")


# Calls continue_reveal. Used instead of a timer to allow multiple reveals per frame.
func _process(delta:float) -> void:
	if !revealing or Dialogic.paused:
		return
	speed_counter += delta
	while speed_counter > speed and revealing and !Dialogic.paused:
		speed_counter -= speed
		continue_reveal()
