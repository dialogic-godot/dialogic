extends Control

var text

func _ready():
	text = $Container/Label.get_node("Container/Label").text
