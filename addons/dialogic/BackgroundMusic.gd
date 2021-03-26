extends Control
class_name DialogicBackgroundMusic

onready var _anim_player := $AnimationPlayer
onready var _track1 := $Track1
onready var _track2 := $Track2


func crossfade_to(audio_stream: AudioStream) -> void:
	if _track1.playing and _track2.playing:
		return
	
	if _track2.playing:
		_track1.stream = audio_stream
		_track1.play()
		_anim_player.play("FadeToTrack1")
	else:
		_track2.stream = audio_stream
		_track2.play()
		_anim_player.play("FadeToTrack2")


func fade_out() -> void:
	_anim_player.play("FadeOut")
