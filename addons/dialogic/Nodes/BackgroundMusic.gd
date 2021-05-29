extends Control
class_name DialogicBackgroundMusic

onready var _track1 := $Track1
onready var _track2 := $Track2

var current_path = ""

func _ready():
	$Tween.connect("tween_completed", self, "_on_Tween_tween_completed")

func crossfade_to(path: String, audio_bus:String, volume:float, fade_length: float) -> void:
	# find a better solution for this
	if _track1.playing and _track2.playing:
		return
	
	var stream: AudioStream = load(path)
	var fade_out_track = _track1
	var fade_in_track = _track2
	
	if _track2.playing:
		fade_out_track = _track2
		fade_in_track = _track1
	
	# setup the new track
	fade_in_track.stream = stream
	fade_in_track.bus = audio_bus
	fade_in_track.volume_db = -60
	
	
	$Tween.interpolate_property(fade_out_track, "volume_db", null, -60, fade_length, Tween.TRANS_EXPO)
	$Tween.interpolate_property(fade_in_track, "volume_db", -60, volume, fade_length, Tween.TRANS_EXPO)
	$Tween.start()
	
	# in case the audio is already playing we will attempt a fade into the new one from the current position
	if current_path == path:
		fade_in_track.play(fade_out_track.get_playback_position())
	# else just play it from the beginning
	else:
		fade_in_track.play()
	current_path = path

func fade_out(fade_length:float = 1) -> void:
	current_path = ""
	$Tween.interpolate_property(_track1, "volume_db", null, -60, fade_length, Tween.TRANS_EXPO)
	$Tween.interpolate_property(_track2, "volume_db", null, -60, fade_length, Tween.TRANS_EXPO)
	$Tween.start()

func _on_Tween_tween_completed(object, key):
	# if the stream was faded out
	if object.volume_db == -60:
		object.playing = false
		object.stream = null
