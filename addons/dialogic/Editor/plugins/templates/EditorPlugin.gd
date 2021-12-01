extends WindowDialog
class_name DialogicEditorPlugin

var editor_reference
var timeline_reference
onready var targetList:ItemList = $s_container/target/s/items
onready var sourceList:ItemList = $s_container/source/s/items
export(String) var plugin_name : String
export(Texture) var plugin_icon : Texture


func setup():
	editor_reference = find_parent('EditorView')
	timeline_reference = editor_reference.get_node("MainPanel/TimelineEditor")


func on_plugin_button_pressed():
	if visible:
		hide()
	else:
		popup()
