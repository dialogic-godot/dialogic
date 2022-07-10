tool
extends DialogicEvent
class_name DialogicMusicEvent

# DEFINE ALL PROPERTIES OF THE EVENT
var FilePath: String = ""
var FadeLength: float = 0
var Volume: float = 0
var AudioBus: String = "Master"
var Loop: bool = true

func _execute() -> void:
	dialogic.Audio.update_music(FilePath, Volume, AudioBus, FadeLength, Loop)
	finish()


func get_required_subsystems() -> Array:
	return [
				['Audio', get_script().resource_path.get_base_dir().plus_file('Subsystem_Audio.gd')],
			]

################################################################################
## 						INITIALIZE
################################################################################

# SET ALL VALUES THAT SHOULD NEVER CHANGE HERE
func _init() -> void:
	event_name = "Music"
	set_default_color('Color5')
	event_category = Category.AUDIOVISUAL
	event_sorting_index = 2
	


################################################################################
## 						SAVING/LOADING
################################################################################
func get_shortcode() -> String:
	return "music"

func get_shortcode_parameters() -> Dictionary:
	return {
		#param_name : property_name
		"path"		: "FilePath",
		"volume"	: "Volume",
		"fade"		: "FadeLength",
		"bus"		: "AudioBus",
		"loop"		: "Loop"
	}


################################################################################
## 						EDITOR REPRESENTATION
################################################################################

func build_event_editor():
	add_header_edit('FilePath', ValueType.SinglelineText, 'Path:')
	add_header_edit('FadeLength', ValueType.Float, 'Fade:')
	add_body_edit('Volume', ValueType.Decibel, 'Volume:', '', {}, '!FilePath.empty()')
	add_body_edit('AudioBus', ValueType.SinglelineText, 'AudioBus:', '', {}, '!FilePath.empty()')
	add_body_edit('Loop', ValueType.Bool, 'Loop:', '', {}, '!FilePath.empty()')
