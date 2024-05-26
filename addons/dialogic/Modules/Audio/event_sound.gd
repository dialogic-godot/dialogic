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
var audio_bus: String = ""
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
	set_default_color('Color7')
	event_category = "Audio"
	event_sorting_index = 3
	help_page_path = "https://dialogic.coppolaemilio.com"


func _get_icon() -> Resource:
	return load(self.get_script().get_path().get_base_dir().path_join('icon_sound.png'))

################################################################################
## 						SAVING/LOADING
################################################################################

func get_shortcode() -> String:
	return "sound"


func get_shortcode_parameters() -> Dictionary:
	return {
		#param_name : property_name
		"path"		: {"property": "file_path", 	"default": "",},
		"volume"	: {"property": "volume", 		"default": 0},
		"bus"		: {"property": "audio_bus", 	"default": "",
							"suggestions": get_bus_suggestions},
		"loop"		: {"property": "loop", 			"default": false},
	}


################################################################################
## 						EDITOR REPRESENTATION
################################################################################

func build_event_editor() -> void:
	add_header_edit('file_path', ValueType.FILE,
			{'left_text'	: 'Play',
			'file_filter' 	: '*.mp3, *.ogg, *.wav; Supported Audio Files',
			'placeholder' 	: "Select file",
			'editor_icon' 	: ["AudioStreamPlayer", "EditorIcons"]})
	add_body_edit('volume', ValueType.NUMBER, {'left_text':'Volume:', 'mode':2}, '!file_path.is_empty()')
	add_body_edit('audio_bus', ValueType.SINGLELINE_TEXT, {'left_text':'Audio Bus:'}, '!file_path.is_empty()')


func get_bus_suggestions() -> Dictionary:
	var bus_name_list := {}
	for i in range(AudioServer.bus_count):
		bus_name_list[AudioServer.get_bus_name(i)] = {'value':AudioServer.get_bus_name(i)}
	return bus_name_list
