tool
extends "res://addons/dialogic/Editor/Events/Templates/EventTemplate.gd"


func _ready():
	event_data = {
		'event_id':'dialogic_030',
		'event_name':'AudioEvent',
		'audio': 'stop',
		'file': '',
		'audio_bus':'Master',
		'volume':0
	}
	get_body().load_data(event_data)
	get_body().connect("audio_changed", self, "_on_AudioPicker_audio_changed")


func load_data(data):
	.load_data(data)
	get_body().load_data(data)


func _on_AudioPicker_audio_changed(file, playing, audio_bus, volume):
	event_data['file'] = file
	event_data['audio'] = playing
	event_data['audio_bus'] = audio_bus
	event_data['volume'] = volume

	if file:
		set_preview('Plays '+file.get_file())
	else:
		set_preview('Stops previous audio event')
