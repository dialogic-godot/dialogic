@tool
extends DialogicEvent
class_name DialogicSoundEvent

# DEFINE ALL PROPERTIES OF THE EVENT
var FilePath: String = ""
var Volume: float = 0
var AudioBus: String = "Master"
var Loop : bool = false

func _execute() -> void:
	dialogic.Audio.play_sound(FilePath, Volume, AudioBus, Loop)
	finish()


################################################################################
## 						INITIALIZE
################################################################################

# SET ALL VALUES THAT SHOULD NEVER CHANGE HERE
func _init() -> void:
	event_name = "Sound"
	set_default_color('Color5')
	event_category = Category.AUDIOVISUAL
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
		"path"		: "FilePath",
		"volume"	: "Volume",
		"bus"		: "AudioBus",
		"loop"		: "Loop",
	}


################################################################################
## 						EDITOR REPRESENTATION
################################################################################

func build_event_editor():
	add_header_edit('FilePath', ValueType.File, '', '', {'file_filter':'*.mp3, *.ogg, *.wav', 'placeholder': "Select file", 'editor_icon':["AudioStreamPlayer", "EditorIcons"]})
	add_body_edit('Volume', ValueType.Decibel, 'Volume:', '', {}, '!FilePath.is_empty()')
	add_body_edit('AudioBus', ValueType.SinglelineText, 'AudioBus:', '', {}, '!FilePath.is_empty()')
	#add_body_edit('Loop', ValueType.Bool, 'Loop:')
