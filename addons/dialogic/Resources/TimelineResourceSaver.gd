tool
extends ResourceFormatSaver
class_name DialogicTimelineFormatSaver

# Preload to avoid problems with project.godot
#const TimelineResource = preload("res://addons/custom_resource/resource_class.gd")


func get_recognized_extensions(resource: Resource) -> PoolStringArray:
	return PoolStringArray(["dtl"])


# Here you see if that resource is the type you need.
# Multiple resources can inherith from the same class
# Even they can modify the structure of the class or be pretty similar to it
# So you verify if that resource is the one you need here, and if it's not
# You let other ResourceFormatSaver deal with it.
func recognize(resource: Resource) -> bool:
	# Cast instead of using "is" keyword in case is a subclass
	resource = resource as DialogicTimeline
	
	if resource:
		return true
	
	return false


# Magic tricks
# Magic tricks
# Don't you love magic tricks?

# Here you write the file you want to save, and save it to disk too.
# For text is pretty trivial.
# Binary files, custom formats and complex things are done here.
func save(path: String, resource: Resource, flags: int) -> int:
	var err:int
	var file:File = File.new()
	err = file.open(path, File.WRITE)
	print('Dialogic saved "' , path, '"')
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
	file.store_string(result)
	file.close()
	return OK
