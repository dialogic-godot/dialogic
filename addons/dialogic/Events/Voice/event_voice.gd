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
## The audio regions store in a strange as f*** format
var regions : String


################################################################################
## 						EXECUTE
################################################################################

func _execute() -> void:
	dialogic.Voice.set_file(file_path)
	dialogic.Voice.set_volume(volume)
	dialogic.Voice.set_bus(audio_bus)
	#NOTE need better way of reading the regiondata. This deems messy
	var regiondata := []

	var stringfluff := ["[", "]", "start at", "stop at"]
	if not regions is String:
		printerr("Invalid data - (DialogicVoiceEvent): serial regiondata not string.")
	for f in stringfluff:
		regions = regions.replace(f, "")
	var data1:PackedStringArray = regions.split("region", false)
	for d in data1:
		var data2:PackedStringArray = d.split(",", false)
		regiondata.append([data2[0].to_float(), data2[1].to_float()])

	dialogic.Voice.set_regions(regiondata)

	finish() 
	# the rest is executed by a text event


################################################################################
## 						INITIALIZE
################################################################################

func _init() -> void:
	event_name = "Voice"
	set_default_color('Color1')
	event_category = Category.AudioVisual
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
		"bus"		: {"property": "audio_bus", "default": "Master"},
		"regions"	: {"property": "regions", 	"default": ""},
	}


################################################################################
## 						EDITOR REPRESENTATION
################################################################################

func build_event_editor():
	add_header_edit('file_path', ValueType.File, '', 'is the audio for the next text', 
			{'file_filter'	: "*.mp3, *.ogg, *.wav", 
			'placeholder' 	: "Select file", 
			'editor_icon' 	: ["AudioStreamPlayer", "EditorIcons"]})
	add_body_edit('volume', ValueType.Decibel, 'volume:', '', {}, '!file_path.is_empty()')
	add_body_edit('audio_bus', ValueType.SinglelineText, 'audio_bus:', '', {}, '!file_path.is_empty()')
	add_body_line_break()
	add_body_edit('regions', ValueType.Custom, 'Number of lines/audio regions:', '', 
			{'path' : 'res://addons/dialogic/Events/Voice/ui_field_audio_region_list.tscn'}, 
			'!file_path.is_empty()')
