extends Control


onready var audio_player = $AudioStreamPlayer

#this could use more polish like fading between 2 characters ...
func play_voice(path:String='') -> void : 
	if path == '':
		stop_voice()
	else:
		audio_player.stream = load(path)
		audio_player.play()


func stop_voice():
	audio_player.stop()
