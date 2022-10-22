@tool
extends DialogicEvent
class_name DialogicVoiceEvent

# DEFINE ALL PROPERTIES OF THE EVENT
var FilePath: String = ""
var Volume: float = 0
var AudioBus: String = "Master"
var regions : String #Array = [] 

func _execute() -> void:
	dialogic.Voice.set_file(FilePath)
	dialogic.Voice.set_volume(Volume)
	dialogic.Voice.set_bus(AudioBus)
	#NOTE need better way of reading the regiondata. This deems messy
	var regiondata = []

	var stringfluff = ["[", "]", "start at", "stop at"]
	if not regions is String:
		printerr("Invalid data - (DialogicVoiceEvent): serial regiondata not string.")
	for f in stringfluff:
		regions = regions.replace(f, "")
	var data1:PackedStringArray = regions.split("region", false)
	for d in data1:
		var data2:PackedStringArray = d.split(",", false)
		regiondata.append([data2[0].to_float(), data2[1].to_float()])

	dialogic.Voice.set_regions(regiondata)

	finish() #the rest is executed by a text event


func get_required_subsystems() -> Array:
	return [
				{'name':'Voice',
				'subsystem': get_script().resource_path.get_base_dir().path_join('Subsystem_Voice.gd'),
				},
			]

################################################################################
## 						INITIALIZE
################################################################################

# SET ALL VALUES THAT SHOULD NEVER CHANGE HERE
func _init() -> void:
	event_name = "Voice"
	set_default_color('Color1')
	event_category = Category.AUDIOVISUAL
	event_sorting_index = 5
	expand_by_default = false

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
		"regions"	: "regions",
	}
	
################################################################################
## 						EDITOR REPRESENTATION
################################################################################

func build_event_editor():
	add_header_edit('FilePath', ValueType.File, '', 'is the audio for the next text', {'file_filter':'*.mp3, *.ogg, *.wav', 'placeholder': "Select file", 'editor_icon':["AudioStreamPlayer", "EditorIcons"]})
	add_body_edit('Volume', ValueType.Decibel, 'Volume:', '', {}, '!FilePath.is_empty()')
	add_body_edit('AudioBus', ValueType.SinglelineText, 'AudioBus:', '', {}, '!FilePath.is_empty()')
	add_body_line_break()
	add_body_edit('regions', ValueType.Custom, 'Number of lines/audio regions:', '', {'path' : 'res://addons/dialogic/Events/Voice/SerialAudioregion.tscn'}, '!FilePath.is_empty()')
