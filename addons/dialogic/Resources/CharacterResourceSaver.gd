@tool
extends ResourceFormatSaver
class_name DialogicCharacterFormatSaver


func _get_recognized_extensions(resource: Resource) -> PackedStringArray:
	return PackedStringArray(["dch"])


# Return true if this resource should be loaded as a DialogicCharacter 
func _recognize(resource: Resource) -> bool:
	# Cast instead of using "is" keyword in case is a subclass
	resource = resource as DialogicCharacter
	
	if resource:
		return true
	
	return false


# Save the resource
func _save(resource: Resource, path: String = '', flags: int = 0):
	var file := FileAccess.open(path, FileAccess.WRITE)
	var result := var_to_str(inst_to_dict(resource))
	file.store_string(result)
#	print('[Dialogic] Saved character "' , path, '"')
