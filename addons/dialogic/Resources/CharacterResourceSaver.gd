tool
extends ResourceFormatSaver
class_name DialogicCharacterFormatSaver


func get_recognized_extensions(resource: Resource) -> PoolStringArray:
	return PoolStringArray(["dch"])


# Return true if this resource should be loaded as a DialogicCharacter 
func recognize(resource: Resource) -> bool:
	# Cast instead of using "is" keyword in case is a subclass
	resource = resource as DialogicCharacter
	
	if resource:
		return true
	
	return false


# Save the resource
func save(path: String, resource: Resource, flags: int) -> int:
	var err:int
	var file:File = File.new()
	err = file.open(path, File.WRITE)
	if err != OK:
		printerr('Can\'t write file: "%s"! code: %d.' % [path, err])
		return err
	
	var result = var2str(inst2dict(resource))
	
	file.store_string(result)
	file.close()
	print('[Dialogic] Saved character "' , path, '"')
	return OK
