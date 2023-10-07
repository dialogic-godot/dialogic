@tool
extends ResourceFormatLoader

# Needed by godot
class_name DialogicCharacterFormatLoader


# returns all excepted extenstions
func _get_recognized_extensions() -> PackedStringArray:
	return PackedStringArray(["dch"])


# Returns "Rrsource" if this file can/should be loaded by this script
func _get_resource_type(path: String) -> String:
	var ext = path.get_extension().to_lower()
	if ext == "dch":
		return "Resource"
	
	return ""


# Return true if this type is handled
func _handles_type(typename: StringName) -> bool:
	return ClassDB.is_parent_class(typename, "Resource")


# parse the file and return a resource
func _load(path: String, original_path: String, use_sub_threads: bool, cache_mode: int):
#	print('[Dialogic] Reimporting character "' , path, '"')
	if ResourceLoader.exists(path):
		var file = FileAccess.open(path, FileAccess.READ)
		return dict_to_inst(str_to_var(file.get_as_text()))
	else:
		push_error("File does not exists")
		return false


func _get_dependencies(path:String, add_type:bool):
	var depends_on : PackedStringArray
	var character:DialogicCharacter = load(path)
	for p in character.portraits.values():
		if 'path' in p and p.path:
			depends_on.append(p.path)
	return depends_on

func _rename_dependencies(path: String, renames: Dictionary):
	var character:DialogicCharacter = load(path)
	for p in character.portraits:
		if 'path' in character.portraits[p] and character.portraits[p].path in renames:
			character.portraits[p].path = renames[character.portraits[p].path]
	ResourceSaver.save(character, path)
	return OK
