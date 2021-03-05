tool
extends ScrollContainer

onready var nodes = {
	'themes': $VBoxContainer/HBoxContainer/ThemeOptionButton
}


func _ready():
	update_data()


func update_data():
	refresh_themes()


func refresh_themes():
	nodes['themes'].clear()
	for theme in DialogicUtil.get_theme_list():
		nodes['themes'].add_item(theme['name'])
