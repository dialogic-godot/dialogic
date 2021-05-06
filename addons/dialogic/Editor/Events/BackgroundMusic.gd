tool
extends "res://addons/dialogic/Editor/Events/Templates/EventTemplate.gd"


func _ready():
	event_data = {
		'event_id':'dialogic_031',
		'event_name':'BackgroundMusic',
		'background-music': 'stop',
		'file': '',
		'audio_bus':'Master',
		'volume':0,
		'fade_length':1,
	}
	get_body().load_data(event_data)
	get_body().connect("audio_changed", self, "_on_ComplexAudioPicker_audio_changed")


func load_data(data):
	.load_data(data)
	get_body().load_data(data)


func _on_ComplexAudioPicker_audio_changed(file, playing, audio_bus, volume, fade_length):
	event_data['file'] = file
	event_data['background_music'] = playing
	event_data['audio_bus'] = audio_bus
	event_data['volume'] = volume
	event_data['fade_length'] = fade_length

	if file:
		set_preview('Plays '+file.get_file())
	else:
		set_preview('Stops previous audio event')
