# Here is where the magic begins

# A little tool to ensure that it'll work in editor (we never use it in editor anyway)
tool
extends ResourceFormatLoader

# Docs says that it needs a class_name in order to register it in ResourceLoader
# Who am I to judge the docs?
class_name DialogicTimelineFormatLoader

# Preload to avoid problems with project.godot
#const TimelineResource = preload("res://addons/dialogic/Resources/timeline.gd")

# Dude, look at the docs, I'm not going to explain each function... 
# Specially when they are self explainatory...
func get_recognized_extensions() -> PoolStringArray:
	return PoolStringArray(["dtl"])


# Ok, if custom resources were a thing this would be even useful.
# But is not.
# I don't know what is taking longer, Godot 4 or https://github.com/godotengine/godot/pull/48201
func get_resource_type(path: String) -> String:
	# For now, the only thing that you need to know is that this thing serves as
	# a filter for your resource. You verify whatever you need on the file path
	# or even the file itself (with a File.load)
	# and you return "Resource" (or whatever you're working on) if you handle it.
	# Everything else ""
	var ext = path.get_extension().to_lower()
	if ext == "dtl":
		return "Resource"
	
	return ""


# Ok, if custom resources were a thing this would be even useful.
# But is not. (again)
# You need to tell the editor if you handle __this__ type of class (wich is an string)
func handles_type(typename: String) -> bool:
	# I'll give you a hand for custom resources... use this snipet and that's it ;)
	return ClassDB.is_parent_class(typename, "Resource")


# And this is the one that does the magic.
# Read your file, parse the data to your resource, and return the resource
# Is that easy!

# Even JSON can be accepted here, if you like that (I don't, but I'm not going to judge you)
func load(path: String, original_path: String):
	var file := File.new()
	
	print('load ' , path)
	var err:int
	
	var res := DialogicTimeline.new()
	
	err = file.open(path, File.READ)
	if err != OK:
		push_error("For some reason, loading custom resource failed with error code: %s"%err)
		# You has to return the error constant
		return err
	
	# Parse the lines as seperate events and recreate them as resources
	var events = []
	for line in file.get_as_text().split("\n", false):
		var event = DialogicUtil.get_event_by_string(line).new()
		event.load_from_string_to_store(line)
		events.append(event)
	
	res.events = events
	
	# Everything went well, and you parsed your file data into your resource. Life is good, return it
	return res
