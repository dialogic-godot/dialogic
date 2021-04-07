tool
extends Resource
class_name DialogicCharacterResource

export(String) var name:String = ""
export(String) var display_name:String setget ,_get_display_name
export(bool) var display_name_bool:bool = false
export(Color) var color:Color = Color.white
export(bool) var default_speaker:bool = false
export(String, MULTILINE) var description:String = ""
export(Array, Resource) var portraits = []


func _get_display_name() -> String:
	if display_name_bool and display_name:
		return display_name
	else:
		return name
