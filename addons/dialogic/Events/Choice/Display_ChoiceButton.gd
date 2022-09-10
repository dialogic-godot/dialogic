extends Button

class_name DialogicNode_ChoiceButton


@export var choice_index:int = -1

@export var sound_pressed: AudioStream
@export var sound_hover: AudioStream
@export var sound_focus: AudioStream

func _ready():
	add_to_group('dialogic_choice_button')
	shortcut_in_tooltip = false
	hide()
