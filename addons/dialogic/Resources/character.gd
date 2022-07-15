tool
extends Resource
class_name DialogicCharacter


export (String) var name:String = ""
export (String) var display_name:String = ""
export (PoolStringArray) var nicknames:Array = []

export (Color) var color:Color = Color()
export (String, MULTILINE) var description:String = ""

export (float) var scale:float = 1.0 
export (Vector2) var offset:Vector2 = Vector2()
export (bool) var mirror:bool = false

export (Dictionary) var portraits:Dictionary = {}

export (Dictionary) var custom_info:Dictionary = {}

func __get_property_list() -> Array:
	return []


func _to_string() -> String:
	return "[{name}:{id}]".format({"name":name, "id":get_instance_id()})


func _hide_script_from_inspector():
	return true
