@tool
extends ResourceFormatLoader

# Needed by godot
class_name DialogicCharacterFormatLoader


# returns all excepted extenstions
func get_recognized_extensions() -> PackedStringArray:
	return PackedStringArray(["dch"])


# Returns "Rrsource" if this file can/should be loaded by this script
func get_resource_type(path: String) -> String:
	var ext = path.get_extension().to_lower()
	if ext == "dch":
		return "Resource"
	
	return ""


# Return true if this type is handled
func handles_type(typename: String) -> bool:
	return ClassDB.is_parent_class(typename, "Resource")


# parse the file and return a resource
func load(path: String, original_path: String):
	print('[Dialogic] Reimporting character "' , path, '"')
	var file := File.new()
	
	var err:int
	
	err = file.open(path, File.READ)
	if err != OK:
		push_error("For some reason, loading custom resource failed with error code: %s"%err)
		return err
	
	var res = dict2inst(str2var(file.get_as_text()))
	
	# Everything went well, and you parsed your file data into your resource. Life is good, return it
	return res
