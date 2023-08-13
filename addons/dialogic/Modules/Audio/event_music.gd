@tool
class_name DialogicMusicEvent
extends DialogicEvent

## Event that can change the currently playing background music. 


### Settings

## The file to play. If empty, the previous music will be faded out.
var file_path: String = ""
## The length of the fade. If 0 (by default) it's an instant change.
var fade_length: float = 0
## The volume the music will be played at.
var volume: float = 0
## The audio bus the music will be played at.
var audio_bus: String = "Master"
## If true, the audio will loop, otherwise only play once.
var loop: bool = true


################################################################################
## 						EXECUTE
################################################################################

func _execute() -> void:
	dialogic.Audio.update_music(file_path, volume, audio_bus, fade_length, loop)
	finish()


################################################################################
## 						INITIALIZE
################################################################################

func _init() -> void:
	event_name = "Music"
	set_default_color('Color7')
	event_category = "Audio"
	event_sorting_index = 2
	expand_by_default = false


func _get_icon() -> Resource:
	return load(self.get_script().get_path().get_base_dir().path_join('icon_music.png'))

################################################################################
## 						SAVING/LOADING
################################################################################

func get_shortcode() -> String:
	return "music"


func get_shortcode_parameters() -> Dictionary:
	return {
		#param_name : property_info
		"path"		: {"property": "file_path", 	"default": ""},
		"fade"		: {"property": "fade_length", 	"default": 0},
		"volume"	: {"property": "volume", 		"default": 0},
		"bus"		: {"property": "audio_bus", 	"default": "Master", 
						"suggestions": get_bus_suggestions},
		"loop"		: {"property": "loop", 			"default": true},
	}


################################################################################
## 						EDITOR REPRESENTATION
################################################################################

func build_event_editor():
	add_header_edit('file_path', ValueType.FILE, 'Play', '', 
			{'file_filter' 	: "*.mp3, *.ogg, *.wav; Supported Audio Files", 
			'placeholder' 	: "No music", 
			'editor_icon' 	: ["AudioStreamPlayer", "EditorIcons"]})
	add_body_edit('fade_length', ValueType.FLOAT, 'Fade Time:')
	add_body_edit('volume', ValueType.DECIBEL, 'Volume:', '', {}, '!file_path.is_empty()')
	add_body_edit('audio_bus', ValueType.SINGLELINE_TEXT, 'Audio Bus:', '', {}, '!file_path.is_empty()')
	add_body_edit('loop', ValueType.BOOL, 'Loop:', '', {}, '!file_path.is_empty()')


func get_bus_suggestions() -> Dictionary:
	var bus_name_list := {}
	for i in range(AudioServer.bus_count):
		bus_name_list[AudioServer.get_bus_name(i)] = {'value':AudioServer.get_bus_name(i)}
	return bus_name_list
