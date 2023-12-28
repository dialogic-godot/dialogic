@icon("node_next_indicator_icon.svg")
class_name DNextIndicator
extends Control

## Node that is shown when the text is fully revealed.
## The default implementation allows to set an icon and animation.

const TEXTURE : String = 'Texture'

@export var enabled : bool = true

## If true the next indicator will also be shown if the text is a question.
@export var show_on_questions : bool = false
## If true the next indicator will be shown even if dialogic will autocontinue.
@export var show_on_autoadvance : bool = false

## What animation should the indicator do.
@export_enum('bounce', 'blink', 'none') var animation : int = 0
## Set the image to use as the indicator.
@export var texture : Texture = preload("res://addons/dialogic/Example Assets/next-indicator/next-indicator.png"):
	set(_texture):
		texture = _texture
		if has_node(TEXTURE):
			get_node(TEXTURE).set(&'texture', texture)

@export var texture_size : Vector2 = Vector2(32,32):
	set(_texture_size):
		texture_size = _texture_size
		if has_node(TEXTURE):
			get_node(TEXTURE).set(&'size', _texture_size)
			get_node(TEXTURE).set(&'position', -_texture_size)


var tween: Tween

func _ready() -> void:
	add_to_group('dialogic_next_indicator')
	# Creating texture
	if texture:
		var icon : TextureRect = TextureRect.new()
		icon.name = TEXTURE
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.size = texture_size
		icon.position = -icon.size
		add_child(icon)
		icon.texture = texture

	hide()
	visibility_changed.connect(_on_visibility_changed)


func _on_visibility_changed() -> void:
	if visible:
		play_animation(animation, 1.0)


func play_animation(anim: int, time: float) -> void:
	# clean up previous tween to prevent slipping
	if tween:
		tween.stop()

	if anim == 0:
		tween = (create_tween() as Tween)
		var distance : int = 4
		tween.set_parallel(false)
		tween.set_trans(Tween.TRANS_SINE)
		tween.set_ease(Tween.EASE_IN_OUT)
		tween.set_loops()

		tween.tween_property(self, 'position', Vector2(0,distance), time*0.3).as_relative()
		tween.tween_property(self, 'position', - Vector2(0,distance), time*0.3).as_relative()
	if anim == 1:
		tween = (create_tween() as Tween)
		tween.set_parallel(false)
		tween.set_trans(Tween.TRANS_SINE)
		tween.set_ease(Tween.EASE_IN_OUT)
		tween.set_loops()

		tween.tween_property(self, 'modulate:a', 0, time*0.3)
		tween.tween_property(self, 'modulate:a', 1, time*0.3)
