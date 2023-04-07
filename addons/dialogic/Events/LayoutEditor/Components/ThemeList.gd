@tool
extends ScrollContainer

var ListItem = preload("res://addons/dialogic/Events/LayoutEditor/Components/ThemeItem.tscn")
@onready var active_layout = DialogicUtil.get_project_setting('dialogic/layout/layout_scene', DialogicUtil.get_default_layout())


func add_item(scene) -> void:
	var l = ListItem.instantiate()
	l.theme_name = scene.get('name', 'Mysterious Layout')
	l.author = scene.get('author', 'Unknown')
	l.path = scene.path
	if scene.has('preview_image'):
		l.preview_image = load(scene.preview_image[0])
	else:
		l.preview_image = load("res://addons/dialogic/Editor/Images/Unknown.png")
	if l.path == active_layout:
		l.get_node('VBoxContainer/Button').button_pressed = true
	l.activate_theme.connect(_on_activate_theme)
	$HBoxContainer.add_child(l)


func _on_activate_theme(item):
	for i in $HBoxContainer.get_children():
		i.get_node('VBoxContainer/Button').button_pressed = false
	item.get_node('VBoxContainer/Button').button_pressed = true
	ProjectSettings.set_setting('dialogic/layout/layout_scene', item.path)
	ProjectSettings.save()
	
	#CALL THIS ON PARENT
	#layouts_info.get(DialogicUtil.get_project_setting('dialogic/layout/layout_scene', DialogicUtil.get_default_layout()), {}).get('name', 'Invalid Preset!')
