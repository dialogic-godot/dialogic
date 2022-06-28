extends RichTextLabel

export(String, 'Left', 'Center', 'Right') var Align = 'Left'
var timer

func _ready():
	add_to_group('dialogic_dialog_text')
	bbcode_text = ""
	timer = Timer.new()
	add_child(timer)
	timer.wait_time = 0.01
	timer.connect("timeout", self, 'continue_reveal')

func reveal_text():
	if Align == 'Center':
		bbcode_text = '[center]'+bbcode_text
	elif Align == 'Right':
		bbcode_text = '[right]'+bbcode_text
	visible_characters = 0
	timer.start()

func continue_reveal():
	if visible_characters < len(bbcode_text):
		visible_characters += 1
		timer.start()
	else:
		finish_text()

func finish_text():
	percent_visible = 1
	timer.stop()
	DialogicGameHandler.current_state = DialogicGameHandler.states.IDLE
