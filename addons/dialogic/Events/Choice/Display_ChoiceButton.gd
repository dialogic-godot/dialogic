extends Button

class_name DialogicDisplay_ChoiceButton, 'icon.png'

export (int) var choice_index = -1

export(AudioStream) var sound_pressed
export(AudioStream) var sound_released
export(AudioStream) var sound_hover
export(AudioStream) var sound_unhover
export(AudioStream) var sound_focus
export(AudioStream) var sound_unfocus

onready var sound_node = get_parent().get_node("SoundButton")

func _ready():
	connect('pressed', sound_node, '_on_pressed', [sound_pressed])
	connect('button_up', sound_node, '_on_released', [sound_released])
	connect('mouse_entered', sound_node, '_on_hover', [sound_hover])
	connect('mouse_exited', sound_node, '_on_unhover', [sound_unhover])
	connect('focus_entered', sound_node, '_on_focus', [sound_focus])
	connect('focus_exited', sound_node, '_on_unfocus', [sound_unfocus])
	add_to_group('dialogic_choice_button')
	hide()
