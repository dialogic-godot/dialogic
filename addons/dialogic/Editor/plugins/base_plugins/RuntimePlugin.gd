extends WindowDialog
class_name DialogicRuntimePlugin

var dialog_reference
onready var targetList:ItemList = $s_container/target/s/items
onready var sourceList:ItemList = $s_container/source/s/items
export(String) var plugin_name : String
export(Texture) var plugin_icon : Texture


func setup():
	pass #stub
