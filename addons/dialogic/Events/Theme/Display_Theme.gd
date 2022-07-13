extends Control

class_name DialogicDisplay_Theme, 'icon.png'

export (String) var theme_name:String = 'Default'

func _ready():
	if theme_name.empty():
		theme_name = name
	add_to_group('dialogic_themes')
