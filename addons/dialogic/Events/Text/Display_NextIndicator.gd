extends Control

class_name DialogicDisplay_NextIndicator

@export var show_on_questions := false

@export var show_on_autocontinue := false

func _ready():
	add_to_group('dialogic_next_indicator')
	hide()
