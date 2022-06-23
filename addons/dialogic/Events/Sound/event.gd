tool
extends DialogicEvent
class_name DialogicSoundEvent

# DEFINE ALL PROPERTIES OF THE EVENT
var FilePath: String = ""
var Volume: float = 0
var AudioBus: String = "Master"
var Loop : bool = false

func _execute() -> void:
	dialogic_game_handler.play_sound(FilePath, Volume, AudioBus, Loop)
	finish()


################################################################################
## 						INITIALIZE
################################################################################

# SET ALL VALUES THAT SHOULD NEVER CHANGE HERE
func _init() -> void:
	event_name = "Sound"
	event_color = Color("#fc6514")
	event_category = Category.AUDIOVISUAL
	event_sorting_index = 3
	


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
	add_header_edit('FilePath', ValueType.SinglelineText, 'Path:')
	add_body_edit('Volume', ValueType.Decibel, 'Volume:')
	add_body_edit('AudioBus', ValueType.SinglelineText, 'AudioBus:')
	add_body_edit('Loop', ValueType.Bool, 'Loop:')
