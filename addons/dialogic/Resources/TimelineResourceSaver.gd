tool
extends ResourceFormatSaver
class_name DialogicTimelineFormatSaver


func get_recognized_extensions(resource: Resource) -> PoolStringArray:
	return PoolStringArray(["dtl"])


# Return true if this resource should be loaded as a DialogicCharacter 
func recognize(resource: Resource) -> bool:
	# Cast instead of using "is" keyword in case is a subclass
	resource = resource as DialogicTimeline
	
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
	
	var result = ""
	var indent = 0
	for idx in range(0, len(resource.events)):
		var event = resource.events[idx]
		
		if event is DialogicEndBranchEvent:
			if idx < len(resource.events)-1 and resource.events[idx+1] is DialogicChoiceEvent:
				indent -= 1
			else:
				result += "\t".repeat(indent)+"\n"
				indent -= 1
			continue
		if event != null:
			result += "\t".repeat(indent)+event.get_as_string_to_store() + "\n"
		if event is DialogicChoiceEvent or event is DialogicConditionEvent:
			indent += 1
		if indent < 0: indent = 0
		result += "\t".repeat(indent)+"\n"
	file.store_string(result)
	file.close()
	print('[Dialogic] Saved timeline "' , path, '"')
	return OK
