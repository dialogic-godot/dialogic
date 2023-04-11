@tool
extends Control


@export var text: String = "Hello World"


func _ready():
	$Label.text = text
	$Label.set('custom_colors/font_color', Color("#7b7b7b"))

