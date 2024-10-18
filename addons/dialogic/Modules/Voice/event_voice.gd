@tool
class_name DialogicVoiceEvent
extends DialogicEvent

## Event that allows to set the sound file to use for the next text event.


### Settings

## The path to the sound file.
var file_path := ""
## The volume the sound will be played at.
var volume: float = 0
## The audio bus to play the sound on.
var audio_bus := "Master"


var _preview_node: AudioStreamPlayer

################################################################################
## 						EXECUTE
################################################################################

func _execute() -> void:
	# If Auto-Skip is enabled, we may not want to play voice audio.
	# Instant Auto-Skip will always skip voice audio.
	if (dialogic.Inputs.auto_skip.enabled
	and dialogic.Inputs.auto_skip.skip_voice):
		finish()
		return

	dialogic.Voice.set_file(file_path)
	dialogic.Voice.set_volume(volume)
	dialogic.Voice.set_bus(audio_bus)
	finish()
	# the rest is executed by a text event


################################################################################
## 						INITIALIZE
################################################################################

func _init() -> void:
	event_name = "Voice"
	set_default_color('Color7')
	event_category = "Audio"
	event_sorting_index = 5


func _enter_visual_editor(_timeline_editor:DialogicEditor) -> void:
	_preview_node = AudioStreamPlayer.new()
	editor_node.add_child(_preview_node)
	_preview_node.finished.connect(_on_preview_finished)

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
		"bus"		: {"property": "audio_bus", "default": "Master"}
	}


################################################################################
## 						EDITOR REPRESENTATION
################################################################################

func build_event_editor() -> void:
	add_header_edit('file_path', ValueType.FILE, {
			'left_text'		: 'Set',
			'right_text'	: 'as the next voice audio',
			'file_filter'	: "*.mp3, *.ogg, *.wav",
			'placeholder' 	: "Select file",
			'editor_icon' 	: ["AudioStreamPlayer", "EditorIcons"]})
	add_header_button('', _on_play_preview_audio, '', ["Play", "EditorIcons"], '!file_path.is_empty() && !_preview_node.is_playing()')
	add_header_button('', _on_stop_preview_audio, '', ["Stop", "EditorIcons"], '_preview_node.is_playing()')
	add_body_edit('volume', ValueType.NUMBER, {'left_text':'Volume:', 'mode':2}, '!file_path.is_empty()')
	add_body_edit('audio_bus', ValueType.SINGLELINE_TEXT, {'left_text':'Audio Bus:'}, '!file_path.is_empty()')


func _on_play_preview_audio() -> void:
	if _preview_node:
		_preview_node.stream = load(file_path)
		_preview_node.play()
		ui_update_needed.emit()


func _on_stop_preview_audio() -> void:
	_preview_node.stop()
	_preview_node.stream = null
	ui_update_needed.emit()


func _on_preview_finished() -> void:
	ui_update_needed.emit()
