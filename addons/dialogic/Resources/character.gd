tool
extends Resource
class_name DialogicCharacter


export (String) var name = ""
export (String) var display_name = ""
export (PoolStringArray) var nicknames = []

export (Color) var color = Color()
export (String, MULTILINE) var description = ""
export (String) var theme = ""

export (float) var scale:float = 1.0 

export (Dictionary) var portraits = {}



func __get_property_list() -> Array:
	return []


func _to_string() -> String:
	return "[{name}:{id}]".format({"name":name, "id":get_instance_id()})


func _hide_script_from_inspector():
	return true
