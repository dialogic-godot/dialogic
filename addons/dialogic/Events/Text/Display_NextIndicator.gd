extends Control

class_name DialogicNode_NextIndicator

@export var show_on_questions := false

@export var show_on_autocontinue := false

@export var animation := 'bounce'

@onready var start_position : Vector2 = position

func _ready():
	add_to_group('dialogic_next_indicator')
	hide()
	visibility_changed.connect(_on_visibility_changed)


func _on_visibility_changed():
	if visible:
		play_animation(animation, 1.0)


func play_animation(animation: String, time:float) -> void:
	if animation == 'bounce':
		var tween:Tween = (create_tween() as Tween)
		position = start_position
		var distance := 4
		tween.set_parallel(false)
		tween.set_trans(Tween.TRANS_SINE)
		tween.set_ease(Tween.EASE_IN_OUT)
		tween.set_loops()
		
		tween.tween_property(self, 'position', position + Vector2(0,distance), time*0.3)
		tween.tween_property(self, 'position', position - Vector2(0,distance), time*0.3)
