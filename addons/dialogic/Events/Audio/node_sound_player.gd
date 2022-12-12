class_name DialogicNode_SoundPlayer
extends AudioStreamPlayer

## An audio stream player that is used by dialogic to play sounds.

func _ready():
	add_to_group('dialogic_sound_player')
