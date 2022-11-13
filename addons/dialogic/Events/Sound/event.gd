@tool
class_name DialogicSoundEvent
extends DialogicEvent

## Event that allows to play a sound effect. Requires the Audio subsystem!


### Settings

## The path to the file to play.
var file_path: String = ""
## The volume to play the sound at.
var volume: float = 0
## The bus to play the sound on.
var audio_bus: String = "Master"
## If true, the sound will loop infinitely. Not recommended (as there is no way to stop it).
var loop: bool = false


################################################################################
## 						EXECUTE
################################################################################

func _execute() -> void:
	dialogic.Audio.play_sound(file_path, volume, audio_bus, loop)
	finish()


################################################################################
## 						INITIALIZE
################################################################################

func _init() -> void:
	event_name = "Sound"
	set_default_color('Color5')
	event_category = Category.AudioVisual
	event_sorting_index = 3
	expand_by_default = false


################################################################################
## 						SAVING/LOADING
################################################################################

func get_shortcode() -> String:
	return "sound"


func get_shortcode_parameters() -> Dictionary:
	return {
		#param_name : property_name
		"path"		: {"property": "file_path", 	"default": ""},
		"volume"	: {"property": "volume", 		"default": 0},
		"bus"		: {"property": "audio_bus", 	"default": "Master"},
		"loop"		: {"property": "loop", 			 "default": false},
	}


################################################################################
## 						EDITOR REPRESENTATION
################################################################################

func build_event_editor():
	add_header_edit('file_path', ValueType.File, '', '', 
			{'file_filter' 	: '*.mp3, *.ogg, *.wav', 
			'placeholder' 	: "Select file", 
			'editor_icon' 	: ["AudioStreamPlayer", "EditorIcons"]})
	add_body_edit('volume', ValueType.Decibel, 'volume:', '', {}, '!file_path.is_empty()')
	add_body_edit('audio_bus', ValueType.SinglelineText, 'audio_bus:', '', {}, '!file_path.is_empty()')
