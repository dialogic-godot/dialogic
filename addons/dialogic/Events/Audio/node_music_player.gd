class_name DialogicNode_MusicPlayer
extends AudioStreamPlayer

## An audio stream player that is used by dialogic to play music.

func _ready():
	add_to_group('dialogic_music_player')
