tool

const DialogicDB = preload("res://addons/dialogic/Core/DialogicDatabase.gd")

class Error:
	const DIALOGIC_ERROR = "[Dialogic Error]"
	const TIMELINE_NOT_FOUND = "TIMELINE_NOT_FOUND"
	const TIMELINE_NOT_SELECTED = "TIMELINE_NOT_SELECTED"
	
	static func not_found_timeline() -> Resource:
		var _timeline = load("res://DialogicResources/TimelineResource.gd").new()
		var _text_event = load("res://DialogicResources/Events/TextEvent.gd").new()
		var _character = load("res://DialogicResources/CharacterResource.gd").new()
		_character.name = DIALOGIC_ERROR
		_character.color = Color.red
		_text_event.character = _character
		_text_event.text = TIMELINE_NOT_SELECTED
		_timeline.events.append(_text_event)
		return _timeline


static func print(what) -> void:
	if not DialogicDB.get_editor_configuration().editor_debug_mode:
		return
	
	var _info = "[Dialogic]"
	match typeof(what):
		var anything_else:
			print("{mark} {info}".format({"mark":_info, "info":what}))

