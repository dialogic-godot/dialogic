tool
extends HBoxContainer

var editor_reference setget set_editor_reference
var editorPopup

onready var regular_audio_picker = $AudioPicker

export (String) var event_name = 'Audio Event'

var file : String
var audio : String
var audio_bus : String = "Master"
var volume: float = 0

signal audio_changed(file, audio, audio_bus, volume, fade_length)

func _ready():
	regular_audio_picker.load_audio('')
	regular_audio_picker.event_name = event_name
	regular_audio_picker.connect("audio_changed", self, "_on_AudioPicker_audio_changed")

func set_editor_reference(reference):
	regular_audio_picker.editor_reference = reference

func load_data(data):
	regular_audio_picker.load_data(data)
	$FadeLength.value = data.get("fade_length", 1)

func _on_AudioPicker_audio_changed(n_file, n_playing, n_audio_bus, n_volume):
	file = n_file
	audio = n_playing
	audio_bus = n_audio_bus
	volume = n_volume
	emit_signal("audio_changed", file, audio, audio_bus, volume, $FadeLength.value)


func _on_FadeLength_value_changed(value):
	emit_signal("audio_changed", file, audio, audio_bus, volume, $FadeLength.value)
