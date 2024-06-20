@icon("node_next_indicator_icon.svg")
class_name DialogicNode_NextIndicator
extends Control

## Node that is shown when the text is fully revealed.
## The default implementation allows to set an icon and animation.


@export var enabled := true

## If true the next indicator will also be shown if the text is a question.
@export var show_on_questions := false
## If true the next indicator will be shown even if dialogic will autocontinue.
@export var show_on_autoadvance := false

enum Animations {BOUNCE, BLINK, NONE}

## What animation should the indicator do.
@export var animation := Animations.BOUNCE

var texture_rect: TextureRect

## Set the image to use as the indicator.
@export var texture: Texture2D = preload("res://addons/dialogic/Example Assets/next-indicator/next-indicator.png") as Texture2D:
	set(_texture):
		texture = _texture
		if texture_rect:
			texture_rect.texture = texture

@export var texture_size := Vector2(32,32):
	set(_texture_size):
		texture_size = _texture_size
		if has_node('Texture'):
			get_node('Texture').size = _texture_size
			get_node('Texture').position = -_texture_size


var tween: Tween

func _ready() -> void:
	add_to_group('dialogic_next_indicator')

	# Creating TextureRect if missing
	if not texture_rect:
		var icon := TextureRect.new()
		icon.name = 'Texture'
		icon.ignore_texture_size = true
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.size = texture_size
		icon.position = -icon.size
		add_child(icon)
		texture_rect = icon

	texture_rect.texture = texture

	hide()
	visibility_changed.connect(_on_visibility_changed)


func _on_visibility_changed() -> void:
	if visible:
		play_animation(animation, 1.0)


func play_animation(current_animation: int, time:float) -> void:
	# clean up previous tween to prevent slipping
	if tween:
		tween.stop()

	match current_animation:
		Animations.BOUNCE:
			tween = (create_tween() as Tween)
			var distance := 4
			tween.set_parallel(false)
			tween.set_trans(Tween.TRANS_SINE)
			tween.set_ease(Tween.EASE_IN_OUT)
			tween.set_loops()

			tween.tween_property(self, 'position', Vector2(0,distance), time*0.3).as_relative()
			tween.tween_property(self, 'position', - Vector2(0,distance), time*0.3).as_relative()
		Animations.BLINK:
			tween = (create_tween() as Tween)
			tween.set_parallel(false)
			tween.set_trans(Tween.TRANS_SINE)
			tween.set_ease(Tween.EASE_IN_OUT)
			tween.set_loops()

			tween.tween_property(self, 'modulate:a', 0, time*0.3)
			tween.tween_property(self, 'modulate:a', 1, time*0.3)
