tool
extends DialogicEvent
class_name DialogicVoiceEvent

func _execute() -> void:
	finish() #content is executed by a text event

# DEFINE ALL PROPERTIES OF THE EVENT
var FilePath: String = ""
var Volume: float = 0
var AudioBus: String = "Master"
var regions : Array = [] 

################################################################################
## 						INITIALIZE
################################################################################

# SET ALL VALUES THAT SHOULD NEVER CHANGE HERE
func _init() -> void:
	event_name = "Voice"
	set_default_color('Color1')
	event_category = Category.AUDIOVISUAL
	event_sorting_index = 5
	expand_by_default = true

################################################################################
## 						SAVING/LOADING
################################################################################
func get_shortcode() -> String:
	return "voice"

func get_shortcode_parameters() -> Dictionary:
	return {
		#param_name : property_name
		"path"		: "FilePath",
		"volume"	: "Volume",
		"bus"		: "AudioBus",
		"regions"	: "voice_regions",
	}
	
################################################################################
## 						EDITOR REPRESENTATION
################################################################################

func build_event_editor():
	add_header_edit('FilePath', ValueType.SinglelineText, 'Path:')
	add_body_edit('Volume', ValueType.Decibel, 'Volume:', '', {}, '!FilePath.empty()')
	add_body_edit('AudioBus', ValueType.SinglelineText, 'AudioBus:', '', {}, '!FilePath.empty()')
	add_body_edit('voice_regions', ValueType.Custom, '', '', {'path' : 'res://addons/dialogic/Events/Voice/SerialAudioregion.tscn'}, '!FilePath.empty()')


