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
			printerr("Timeline is empty! Aborting save to prevent accidental data loss, please delete the file if it is supposed to be empty")
			return ERR_INVALID_DATA
		# Do not do this if the timeline's not in a ready state, so it doesn't accidentally save it blank
		elif !resource.events_processed:
			print('[Dialogic] Saving timeline...')
			if FileAccess.file_exists(path):
				var file := FileAccess.open(path, FileAccess.WRITE)
				
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
					result += "\t".repeat(indent)+"\n"
					
				file.store_string(result)
				
				print('[Dialogic] Saved timeline "' , path, '"')
				
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
			return ERR_FILE_NOT_FOUND
		else: 
			printerr(path + ": Timeline was not in ready state for saving! Timeline was not saved!")
			return ERR_INVALID_DATA
	else:
		var file := FileAccess.open(path, FileAccess.WRITE)
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
