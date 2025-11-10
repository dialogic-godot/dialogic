@tool
class_name DialogicTimelineFormatSaver
extends ResourceFormatSaver


func _get_recognized_extensions(_resource: Resource) -> PackedStringArray:
	return PackedStringArray(["dtl"])


## Return true if this resource should be loaded as a DialogicTimeline
func _recognize(resource: Resource) -> bool:
	# Cast instead of using "is" keyword in case is a subclass
	resource = resource as DialogicTimeline

	if resource:
		return true

	return false


## Save the resource
func _save(resource: Resource, path: String = '', _flags: int = 0) -> Error:
	if resource.get_meta("timeline_not_saved", false):
		var timeline_as_text: String = resource.as_text()

		var file := FileAccess.open(path, FileAccess.WRITE)
		if not file:
			print("[Dialogic] Error opening file:", FileAccess.get_open_error())
			return ERR_CANT_OPEN
		file.store_string(timeline_as_text)
		file.close()

	return OK
