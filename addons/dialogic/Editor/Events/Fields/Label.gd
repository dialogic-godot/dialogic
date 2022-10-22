@tool
extends Control


@export var text: String = "Hello World"


# Called when the node enters the scene tree for the first time.
func _ready():
	$Label.text = text
	#$Label.text = DTS.translate(text)
	$Label.set('custom_colors/font_color', Color("#7b7b7b"))

