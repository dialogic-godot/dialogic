@tool
## Event that can change the currently playing background music.
## This event won't play new music if it's already playing.
class_name DialogicMusicEvent
extends DialogicEvent


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
	if not dialogic.Audio.is_music_playing_resource(file_path):
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

func build_event_editor() -> void:
	add_header_edit('file_path', ValueType.FILE, {
			'left_text'		: 'Play',
			'file_filter' 	: "*.mp3, *.ogg, *.wav; Supported Audio Files",
			'placeholder' 	: "No music",
			'editor_icon' 	: ["AudioStreamPlayer", "EditorIcons"]})
	add_body_edit('fade_length', ValueType.NUMBER, {'left_text':'Fade Time:'})
	add_body_edit('volume', ValueType.NUMBER, {'left_text':'Volume:', 'mode':2}, '!file_path.is_empty()')
	add_body_edit('audio_bus', ValueType.SINGLELINE_TEXT, {'left_text':'Audio Bus:'}, '!file_path.is_empty()')
	add_body_edit('loop', ValueType.BOOL, {'left_text':'Loop:'}, '!file_path.is_empty() and not file_path.to_lower().ends_with(".wav")')


func get_bus_suggestions() -> Dictionary:
	var bus_name_list := {}
	for i in range(AudioServer.bus_count):
		bus_name_list[AudioServer.get_bus_name(i)] = {'value':AudioServer.get_bus_name(i)}
	return bus_name_list
