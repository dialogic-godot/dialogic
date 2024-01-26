extends DialogicSubsystem

## Subsystem that manages setting voice lines for text events.


signal voiceline_started(info:Dictionary)
signal voiceline_finished(info:Dictionary)
# Emitted if the voiceline didn't end but was cut off
signal voiceline_stopped(info:Dictionary)


var current_audio_file: String
var voice_player := AudioStreamPlayer.new()

#region STATE
####################################################################################################

func pause() -> void:
	voice_player.stream_paused = true


func resume() -> void:
	voice_player.stream_paused = false

#endregion


#region MAIN METHODS
####################################################################################################

func _ready() -> void:
	add_child(voice_player)
	voice_player.finished.connect(_on_voice_finnished)


func is_voiced(index:int) -> bool:
	if dialogic.current_timeline_events[index] is DialogicTextEvent:
		if dialogic.current_timeline_events[index-1] is DialogicVoiceEvent:
			return true
	return false


func play_voice() -> void:
	voice_player.play()
	voiceline_started.emit({'file':current_audio_file})


func set_file(path:String) -> void:
	if current_audio_file == path:
		return
	current_audio_file = path
	var audio: AudioStream = load(path)
	voice_player.stream = audio


func set_volume(value:float) -> void:
	voice_player.volume_db = value


func set_bus(value:String) -> void:
	voice_player.bus = value


func stop_audio() -> void:
	if voice_player.playing:
		voiceline_stopped.emit({'file':current_audio_file, 'remaining_time':get_remaining_time()})
	voice_player.stop()


func _on_voice_finnished() -> void:
	voiceline_finished.emit({'file':current_audio_file, 'remaining_time':get_remaining_time()})


func get_remaining_time() -> float:
	if not voice_player or !voice_player.playing:
		return 0.0
	return voice_player.stream.get_length()-voice_player.get_playback_position()


func is_running() -> bool:
	return get_remaining_time() > 0.0

#endregion
