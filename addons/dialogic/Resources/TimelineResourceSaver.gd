@tool
extends ResourceFormatSaver
class_name DialogicTimelineFormatSaver


func _get_recognized_extensions(resource: Resource) -> PackedStringArray:
	return PackedStringArray(["dtl"])


# Return true if this resource should be loaded as a DialogicTimeline 
func _recognize(resource: Resource) -> bool:
	# Cast instead of using "is" keyword in case is a subclass
	resource = resource as DialogicTimeline
	
	if resource:
		return true
	
	return false


# Save the resource
func _save(resource: Resource, path: String = '', flags: int = 0) -> int:
	if resource.get_meta("timeline_not_saved", false):
		if len(resource.events) == 0:
			printerr("[Dialogic] Timeline save was called, but there are no events. Timeline will not be saved, to prevent accidental data loss. Please delete the timeline file if you are trying to clear all of the events.")
			return ERR_INVALID_DATA
		
#		print('[Dialogic] Beginning saving timeline. Safety checks will be performed before writing, and temporary file will be created and removed if saving is successful...')
		
		#prepare everything before writing, we will only open the file if it's successfuly prepared, as that will clear the file contents
		
		var timeline_as_text :String = ""
		# if events are resources, create text
		if resource.events_processed:
			
			var indent := 0
			for idx in range(0, len(resource.events)):
				var event :DialogicEvent= resource.events[idx]
				if event.event_name == 'End Branch':
					indent -=1
					continue
				
				for i in event.empty_lines_above:
					timeline_as_text += '\t'.repeat(indent) + '\n'
					
				if event != null:
					timeline_as_text += "\t".repeat(indent)+ event.event_node_as_text + "\n"
				if event.can_contain_events:
					indent += 1
				if indent < 0: 
					indent = 0
		
		# if events are string lines, just save them
		else:
			for event in resource.events:
				timeline_as_text += event + "\n"
		
		# Now do the actual saving
		if (len(timeline_as_text) > 0):
			var file := FileAccess.open(path.replace(".dtl", ".tmp"), FileAccess.WRITE)
			file.store_string(timeline_as_text)
			file = null
			
			var dir = DirAccess.open("res://")
			if  dir.file_exists(path.replace(".dtl", ".tmp")):
				file = FileAccess.open(path.replace(".dtl", ".tmp"), FileAccess.READ)
				var check_length = file.get_length()
				if check_length > 0:
					var check_result = file.get_as_text()
					file = null
					if timeline_as_text == check_result:
						dir.copy(path.replace(".dtl", ".tmp"), path)
						file = FileAccess.open(path, FileAccess.READ)
						var check_result2 = file.get_as_text()
						if timeline_as_text == check_result2:
#							print('[Dialogic] Completed saving timeline "' , path, '"')
							dir.remove(path.replace(".dtl", ".tmp"))
						else:
							printerr("[Dialogic] " + path + ": Overwriting .dtl file failed! Temporary file was saved as .tmp extension, please check to see if it matches your timeline, and rename to .dtl manually.")
							return ERR_INVALID_DATA
					else:
						printerr("[Dialogic] " + path + ": Temporary timeline file contents do not match what was written! Temporary file was saved as .tmp extension, please check to see if it matches your timeline, and rename to .dtl manually.")
						return ERR_INVALID_DATA
				else:
					printerr("[Dialogic] " + path + ": Temporary timeline file is empty! Timeline was not saved!")
					dir.remove(path.replace(".dtl", ".tmp"))
					return ERR_INVALID_DATA
			else:
				printerr("[Dialogic] " + path + ": Temporary timeline file failed to create! Timeline was not saved!")
				return ERR_INVALID_DATA
			
		else: 
			printerr("[Dialogic] " + path + ": Timeline failed to convert to text for saving! Timeline was not saved!")
			return ERR_INVALID_DATA
	
	return OK
