@tool
extends ScrollContainer

signal active_theme_changed

var ListItem := load(DialogicUtil.get_module_path('LayoutEditor').path_join("Components/StyleItem.tscn"))
@onready var active_layout :String = ProjectSettings.get_setting('dialogic/layout/layout_scene', DialogicUtil.get_default_layout())


func add_item(data) -> void:
	var l :Control= ListItem.instantiate()
	l.theme_name = data.get('name', 'Mysterious Layout')
	l.author = data.get('author', 'Unknown')
	l.path = data.get('path', '')
	l.description = data.get('description', '')
	if data.has('preview_image'):
		l.preview_image = load(data.preview_image[0])
	else:
		l.preview_image = load("res://addons/dialogic/Editor/Images/Unknown.png")
	if l.path == active_layout:
		l.active_state(true)
	l.activate_theme.connect(_on_activate_theme)
	$HBoxContainer.add_child(l)


func _on_activate_theme(item):
	for i in $HBoxContainer.get_children():
		i.active_state(false)
	item.active_state(true)
	ProjectSettings.set_setting('dialogic/layout/layout_scene', item.path)
	ProjectSettings.save()
	emit_signal('active_theme_changed', item.path)
