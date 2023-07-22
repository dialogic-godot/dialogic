@tool
class_name DialogicVoiceEvent
extends DialogicEvent

## Event that allows to set the sound file to use for the next text event.


### Settings

## The path to the sound file.
var file_path: String = ""
## The volume the sound will be played at.
var volume: float = 0
## The audio bus to play the sound on.
var audio_bus: String = "Master"


################################################################################
## 						EXECUTE
################################################################################

func _execute() -> void:
	dialogic.Voice.set_file(file_path)
	dialogic.Voice.set_volume(volume)
	dialogic.Voice.set_bus(audio_bus)
	finish() 
	# the rest is executed by a text event


################################################################################
## 						INITIALIZE
################################################################################

func _init() -> void:
	event_name = "Voice"
	set_default_color('Color5')
	event_category = "Audio"
	event_sorting_index = 5
	expand_by_default = false


################################################################################
## 						SAVING/LOADING
################################################################################

func get_shortcode() -> String:
	return "voice"


func get_shortcode_parameters() -> Dictionary:
	return {
		#param_name : property_info
		"path"		: {"property": "file_path", "default": ""},
		"volume"	: {"property": "volume", 	"default": 0},
		"bus"		: {"property": "audio_bus", "default": "Master"}
	}


################################################################################
## 						EDITOR REPRESENTATION
################################################################################

func build_event_editor():
	add_header_edit('file_path', ValueType.File, '', 'is the audio for the next text', 
			{'file_filter'	: "*.mp3, *.ogg, *.wav", 
			'placeholder' 	: "Select file", 
			'editor_icon' 	: ["AudioStreamPlayer", "EditorIcons"]})
	add_body_edit('volume', ValueType.Decibel, 'Volume:', '', {}, '!file_path.is_empty()')
	add_body_edit('audio_bus', ValueType.SinglelineText, 'Audio Bus:', '', {}, '!file_path.is_empty()')
