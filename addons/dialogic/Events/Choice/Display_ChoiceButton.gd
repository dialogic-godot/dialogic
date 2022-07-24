extends BaseButton

class_name DialogicDisplay_ChoiceButton, 'icon.png'

export (int) var choice_index = -1

export(AudioStream) var sound_pressed
export(AudioStream) var sound_hover
export(AudioStream) var sound_focus

func _ready():
	add_to_group('dialogic_choice_button')
	shortcut_in_tooltip = false
	hide()
