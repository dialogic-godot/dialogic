@tool
extends ResourceFormatSaver
class_name DialogicTimelineFormatSaver


func _get_recognized_extensions(resource: Resource) -> PackedStringArray:
	return PackedStringArray(["dtl"])


# Return true if this resource should be loaded as a DialogicCharacter 
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
		# Do not do this if the timeline's not in a ready state, so it doesn't accidentally save it blank
		elif !resource.events_processed:
			print('[Dialogic] Beginning saving timeline. Safety checks will be performed before writing, and temporary file will be created and removed if saving is successful...')
			
			#prepare everything before writing, we will only open the file if it's successfuly prepared, as that will clear the file contents
			#var result = events_to_text(resource.events)
			var result := ""
			var indent := 0

			for idx in range(0, len(resource.events)):
				var event = resource.events[idx]


				if event['event_name'] == 'End Branch':
					indent -=1
					continue

				if event != null:
					result += "\t".repeat(indent)+ event['event_node_as_text'] + "\n"
				if event.can_contain_events:
					indent += 1
				if indent < 0: 
					indent = 0
				#result += "\t".repeat(indent)+"\n"
				result += "\n"
				
			if (len(result) > 0):
				var file := FileAccess.open(path.replace(".dtl", ".tmp"), FileAccess.WRITE)
				file.store_string(result)
				file = null
				
				var dir = DirAccess.open("res://")
				if  dir.file_exists(path.replace(".dtl", ".tmp")):
					file = FileAccess.open(path.replace(".dtl", ".tmp"), FileAccess.READ)
					var check_length = file.get_length()
					if check_length > 0:
						var check_result = file.get_as_text()
						file = null
						if result == check_result:
							dir.copy(path.replace(".dtl", ".tmp"), path)
							file = FileAccess.open(path, FileAccess.READ)
							var check_result2 = file.get_as_text()
							if result == check_result2:
								print('[Dialogic] Completed saving timeline "' , path, '"')
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
				
			# Checking for translation updates 
			var trans_updates := {}
			var translate :bool= DialogicUtil.get_project_setting('dialogic/translation_enabled', false)
			for idx in range(0, len(resource.events)):
				var event = resource.events[idx]

				if event != null:
					if translate and event.can_be_translated():
						if event.translation_id:
							trans_updates[event.translation_id] = event.get_original_translation_text()
						else:
							trans_updates[event.add_translation_id()] = event.get_original_translation_text()

	#		if translate:
	#			update_translations(path, trans_updates)
			return OK
		else: 
			printerr("[Dialogic] " + path + ": Timeline was not in ready state for saving! Timeline was not saved!")
			return ERR_INVALID_DATA
	else:
		return OK

func update_translations(path:String, translation_updates:Dictionary):
	if translation_updates.is_empty():
		return
	
	var file_path :String = path.trim_suffix('.dtl')+'_translation.csv'
	if DialogicUtil.get_project_setting('dialogic/translation_path', '').ends_with('.csv'):
		file_path = ProjectSettings.get_setting('dialogic/translation_path')
	
	
	var csv_lines := []
	if FileAccess.file_exists(file_path):
		var trans_file := FileAccess.open(file_path, FileAccess.READ)
		
		while !trans_file.eof_reached():
			csv_lines.append(trans_file.get_csv_line())
			if csv_lines[-1][0] in translation_updates.keys():
				csv_lines[-1][1] = translation_updates[csv_lines[-1][0]]
				translation_updates.erase(csv_lines[-1][0])
	else:
		var trans_file := FileAccess.open(file_path, FileAccess.WRITE)
		for line in csv_lines:
			if line and line[0]:
				trans_file.store_csv_line(line)
		for key in translation_updates.keys():
			trans_file.store_csv_line([key, translation_updates[key]])
		print('[Dialogic] Updated translations for "', path ,'"')
