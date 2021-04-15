tool
extends HBoxContainer

var editor_reference
var editorPopup



# This is the information of this event and it will get parsed and saved to the JSON file.
var event_data = {
	'event_name':'BackgroundMusic',
	'background-music': 'stop',
	'file': '',
	'audio_bus':'Master',
	'volume':0,
	'fade_length':1,
}


func _ready():
	$PanelContainer/VBoxContainer/Header/VisibleToggle.set_visible(true)
	$PanelContainer/VBoxContainer/Settings/AudioPicker.editor_reference = editor_reference
	$PanelContainer/VBoxContainer/Settings/AudioPicker.connect("audio_changed", self, "update_audio_data")

func load_data(data):
	event_data = data
	$PanelContainer/VBoxContainer/Settings/FadeLength.value = event_data.get("fade_length", 1)
	$PanelContainer/VBoxContainer/Settings/AudioPicker.load_data(data)

func update_audio_data(file, playing, audio_bus, volume):
	event_data['background-music'] = playing
	event_data['file'] = file
	event_data['audio_bus'] = audio_bus
	event_data['volume'] = volume
	if file:
		$PanelContainer/VBoxContainer/Header/Preview.text = 'Plays '+file.get_file()
	else:
		$PanelContainer/VBoxContainer/Header/Preview.text = 'Fades out previous background music'

func _on_FadeLength_value_changed(value):
	event_data['fade_length'] = value

