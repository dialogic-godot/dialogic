class_name DialogicNode_DialogText
extends RichTextLabel

## Dialogic node that can reveal text at a given (changeable speed).

signal started_revealing_text()
signal continued_revealing_text(new_character : String)
signal finished_revealing_text()
enum Alignment {LEFT, CENTER, RIGHT}

@export var enabled := true
@export var alignment := Alignment.LEFT
@export var textbox_root : Node = self

@export var hide_when_empty := false
@export var start_hidden := true

var revealing := false
var base_visible_characters := 0
# time per character
var lspeed:float = 0.01
var speed_counter:float = 0


func _set(property:StringName, what:Variant) -> bool:
	if property == &'text' and typeof(what) == TYPE_STRING:
		text = what
		if hide_when_empty:
			textbox_root.visible = !text.is_empty()
		return true
	return false


func _ready() -> void:
	# add to necessary
	add_to_group('dialogic_dialog_text')

	bbcode_enabled = true
	if textbox_root == null:
		textbox_root = self

	if start_hidden:
		textbox_root.hide()
	text = ""


# this is called by the DialogicGameHandler to set text
func reveal_text(_text:String, keep_previous:bool=false) -> void:
	if !enabled:
		return
	show()

	if !keep_previous:
		text = _text
		base_visible_characters = 0

		if alignment == Alignment.CENTER:
			text = '[center]'+text
		elif alignment == Alignment.RIGHT:
			text = '[right]'+text
		visible_characters = 0
	else:
		base_visible_characters = len(text)
		visible_characters = len(text)
		text = text+_text

		# If Auto-Skip is enabled and we append the text (keep_previous),
		# we can skip revealing the text and just show it all at once.
		if DialogicUtil.autoload().Inputs.auto_skip.enabled:
			visible_characters = 1
			return

	revealing = true
	speed_counter = 0
	started_revealing_text.emit()


# called by the timer -> reveals more text
func continue_reveal() -> void:
	if visible_characters <= get_total_character_count():
		revealing = false
		await DialogicUtil.autoload().Text.execute_effects(visible_characters-base_visible_characters, self, false)

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
		# TODO! Make this configurable in the settings!
		DialogicUtil.autoload().Inputs.block_input(0.3)


# shows all the text imidiatly
# called by this thing itself or the DialogicGameHandler
func finish_text() -> void:
	visible_ratio = 1
	DialogicUtil.autoload().Text.execute_effects(-1, self, true)
	revealing = false
	DialogicUtil.autoload().current_state = DialogicGameHandler.States.IDLE

	finished_revealing_text.emit()


# Calls continue_reveal. Used instead of a timer to allow multiple reveals per frame.
func _process(delta:float) -> void:
	if !revealing or DialogicUtil.autoload().paused:
		return

	speed_counter += delta

	while speed_counter > lspeed and revealing and !DialogicUtil.autoload().paused:
		speed_counter -= lspeed
		continue_reveal()
