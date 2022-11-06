extends Control

class_name DNextIndicator
@icon("res://addons/dialogic/Events/Text/DNextIndicator_icon.svg")

@export var show_on_questions := false
@export var show_on_autocontinue := false
@export_enum('bounce', 'blink', 'none') var animation :int = 0
@export var texture := preload("res://addons/dialogic/Example Assets/next-indicator/next-indicator.png")
@export var texture_question :ImageTexture

@onready var start_position : Vector2 = position

func _ready():
	add_to_group('dialogic_next_indicator')
	
	# Creating texture
	if texture:
		var icon = TextureRect.new()
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
		position = start_position
		var distance := 4
		tween.set_parallel(false)
		tween.set_trans(Tween.TRANS_SINE)
		tween.set_ease(Tween.EASE_IN_OUT)
		tween.set_loops()
		
		tween.tween_property(self, 'position', position + Vector2(0,distance), time*0.3)
		tween.tween_property(self, 'position', position - Vector2(0,distance), time*0.3)
	if animation == 1:
		var tween:Tween = (create_tween() as Tween)
		tween.set_parallel(false)
		tween.set_trans(Tween.TRANS_SINE)
		tween.set_ease(Tween.EASE_IN_OUT)
		tween.set_loops()
		
		tween.tween_property(self, 'modulate:a', 0, time*0.3)
		tween.tween_property(self, 'modulate:a', 1, time*0.3)
