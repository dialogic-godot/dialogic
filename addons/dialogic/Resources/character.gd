@tool
extends Resource
class_name DialogicCharacter


@export var display_name:String = ""
@export var nicknames:Array = []

@export var color:Color = Color()
@export var description:String = ""

@export var scale:float = 1.0
@export var offset:Vector2 = Vector2()
@export var mirror:bool = false

@export var default_portrait:String = ""
@export var portraits:Dictionary = {}

@export var custom_info:Dictionary = {}

var _translation_id: String = ""

func __get_property_list() -> Array:
	return []


func _to_string() -> String:
	return "[{name}:{id}]".format({"name":get_character_name(), "id":get_instance_id()})

func _hide_script_from_inspector() -> bool:
	return true

## This is automatically called, no need to use this.
func add_translation_id() -> String:
	_translation_id = DialogicUtil.get_next_translation_id()
	return _translation_id


func remove_translation_id() -> void:
	_translation_id = ""


func get_property_translation_key(property_name:String) -> String:
	return "Character".path_join(_translation_id).path_join(property_name)

## Returns the name of the file (without the extension).
func get_character_name() -> String:
	if !resource_path.is_empty():
		return resource_path.get_file().trim_suffix('.dch')
	elif !display_name.is_empty():
		return display_name.validate_node_name()
	else:
		return "UnnamedCharacter"

## Returns the info of the given portrait.
## Uses the default portrait if the given portrait doesn't exist.
func get_portrait_info(portrait_name:String) -> Dictionary:
	return portraits.get(portrait_name, portraits.get(default_portrait, {}))
