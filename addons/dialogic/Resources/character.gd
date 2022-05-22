tool
extends Resource
class_name DialogicCharacter


export (String) var name = ""
export (String) var display_name = ""

export (Color) var color = Color()

export (Dictionary) var portraits = {}

func __get_property_list() -> Array:
	return []


func property_can_revert(property:String) -> bool:
	if property == "event_node_path":
		return true
	return false


func property_get_revert(property:String):
	if property == "event_node_path":
		return NodePath()


func _to_string() -> String:
	return "[{name}:{id}]".format({"name":name, "id":get_instance_id()})


func _hide_script_from_inspector():
	return true
