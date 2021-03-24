tool
extends Control

export var text_speed: float = 0.02

onready var text_label = $RichTextLabel
onready var name_label = $NameLabel
onready var tween = $Tween

signal text_completed()

func _ready():
	name_label.text = ''
	text_label.meta_underlined = false


func start_text_tween():
	# This will start the animation that makes the text appear letter by letter
	var tween_duration = text_speed * text_label.get_total_character_count()
	tween.interpolate_property(
		text_label, "percent_visible", 0, 1, tween_duration,
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT
	)
	tween.start()


func update_name(character, color='#FFFFFF'):
	if character.has('name'):
		var parsed_name = character['name']
		if character.has('display_name'):
			if character['display_name'] != '':
				parsed_name = character['display_name']
		if character.has('color'):
			color = '#' + character['color'].to_html()
		name_label.bbcode_text = '[color=' + color + ']' + parsed_name + '[/color]'
	else:
		name_label.bbcode_text = ''


func update_text(text):
	# Updating the text and starting the animation from 0
	text_label.bbcode_text = text
	text_label.percent_visible = 0

	# The call to this function needs to be deferred.
	# More info: https://github.com/godotengine/godot/issues/36381
	call_deferred("start_text_tween")


func reset_dialog_extras():
	name_label.bbcode_text = ''

func _on_Tween_tween_completed(object, key):
	emit_signal("text_completed")
