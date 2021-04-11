extends Control
class_name DialogicBackgroundMusic

onready var _anim_player := $AnimationPlayer
onready var _track1 := $Track1
onready var _track2 := $Track2

var current_path = ""

func crossfade_to(path: String) -> void:
	if current_path != path:
		current_path = path
		var stream: AudioStream = load(current_path)
		if _track1.playing and _track2.playing:
			return
		
		if _track2.playing:
			_track1.stream = stream
			_track1.play()
			_anim_player.play("FadeToTrack1")
		else:
			_track2.stream = stream
			_track2.play()
			_anim_player.play("FadeToTrack2")


func fade_out() -> void:
	current_path = ""
	_anim_player.play("FadeOut")
