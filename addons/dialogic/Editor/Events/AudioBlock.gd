tool
extends HBoxContainer

var editor_reference
var editorPopup


# This is the information of this event and it will get parsed and saved to the JSON file.
var event_data = {
	'audio': 'stop',
	'file': '',
	'audio_bus':'Master',
	'volume':0
}


func _ready():
	$PanelContainer/VBoxContainer/Header/AudioPicker.editor_reference = editor_reference
	$PanelContainer/VBoxContainer/Header/AudioPicker.connect('audio_changed', self, 'update_audio_data')

func load_data(data):
	event_data = data
	$PanelContainer/VBoxContainer/Header/AudioPicker.load_data(data)

func update_audio_data(file, playing, audio_bus, volume):
	event_data['file'] = file
	event_data['audio'] = playing
	event_data['audio_bus'] = audio_bus
	event_data['volume'] = volume
