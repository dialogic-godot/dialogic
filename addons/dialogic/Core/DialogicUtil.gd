tool

const DialogicDB = preload("res://addons/dialogic/Core/DialogicDatabase.gd")

class Error:
	const DIALOGIC_ERROR = "[Dialogic Error]"
	const TIMELINE_NOT_FOUND = "TIMELINE_NOT_FOUND"
	const TIMELINE_NOT_SELECTED = "TIMELINE_NOT_SELECTED"
	
	static func not_found_timeline() -> Resource:
		var _timeline = DialogicTimelineResource.new()
		var _text_event = DialogicTextEventResource.new()
		var _character = DialogicCharacterResource.new()
		_character.name = DIALOGIC_ERROR
		_character.color = Color.red
		_text_event.character = _character
		_text_event.text = TIMELINE_NOT_SELECTED
		_timeline.events.append(_text_event)
		return _timeline

class Logger:
	const INFO = "[Dialogic]"
	
	static func print(who, what) -> void:
		if not DialogicDB.get_editor_configuration().editor_debug_mode:
			return
		
		var _info = "[Dialogic]"
		
		match typeof(what):
			var anything_else:
				print("{mark} [{who}] {info}".format(
					{"mark":INFO, 
					"info":what,
					"who":who.get_class(),
					}))
