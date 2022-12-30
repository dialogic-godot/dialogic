class_name DNextIndicator
extends Control
@icon("res://addons/dialogic/Events/Text/node_next_indicator_icon.svg")

## Node that is shown when the text is fully revealed.
## The default implementation allows to set an icon and animation.

## If true the next indicator will also be shown if the text is a question.
@export var show_on_questions := false
## If true the next indicator will be shown even if dialogic will autocontinue.
@export var show_on_autocontinue := false

## What animation should the indicator do.
@export_enum('bounce', 'blink', 'none') var animation := 0
## Set the image to use as the indicator.
@export var texture := preload("res://addons/dialogic/Example Assets/next-indicator/next-indicator.png")


func _ready():
	add_to_group('dialogic_next_indicator')
	# Creating texture
	if texture:
		var icon := TextureRect.new()
		icon.ignore_texture_size = true
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.size = Vector2(32,32)
		icon.position -= icon.size
		add_child(icon)
		icon.texture = texture
	
	hide()
	visibility_changed.connect(_on_visibility_changed)


func _on_visibility_changed():
	if visible:
		play_animation(animation, 1.0)


func play_animation(animation: int, time:float) -> void:
	if animation == 0:
		var tween:Tween = (create_tween() as Tween)
		var distance := 4
		tween.set_parallel(false)
		tween.set_trans(Tween.TRANS_SINE)
		tween.set_ease(Tween.EASE_IN_OUT)
		tween.set_loops()
		
		tween.tween_property(self, 'position', Vector2(0,distance), time*0.3).as_relative()
		tween.tween_property(self, 'position', - Vector2(0,distance), time*0.3).as_relative()
	if animation == 1:
		var tween:Tween = (create_tween() as Tween)
		tween.set_parallel(false)
		tween.set_trans(Tween.TRANS_SINE)
		tween.set_ease(Tween.EASE_IN_OUT)
		tween.set_loops()
		
		tween.tween_property(self, 'modulate:a', 0, time*0.3)
		tween.tween_property(self, 'modulate:a', 1, time*0.3)
