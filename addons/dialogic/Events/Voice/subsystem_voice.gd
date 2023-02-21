extends DialogicSubsystem

## Subsystem that manages setting voice lines for text events.

## The current voice timer
var voice_timer:Timer
## The current audio
var current_audio_file:String

var voice_player := AudioStreamPlayer.new()

####################################################################################################
##					STATE
####################################################################################################

func pause() -> void:
	voice_player.stream_paused = true
	if voice_timer:
		voice_timer.paused = true


func resume() -> void:
	voice_player.stream_paused = false
	if voice_timer:
		voice_timer.paused = false


####################################################################################################
##					MAIN METHODS
####################################################################################################

func _ready() -> void:
	add_child(voice_player)


func is_voiced(index:int) -> bool:
	if dialogic.current_timeline_events[index] is DialogicTextEvent:
		if dialogic.current_timeline_events[index-1] is DialogicVoiceEvent:
			return true
	return false


func play_voice():
	var start:float = 0
	var stop:float = voice_player.stream.get_length()
	voice_player.play(start)
	set_timer(stop - start)


func set_file(path:String):
	if current_audio_file == path:
		return
	current_audio_file = path
	var audio:AudioStream = load(path)
	#TODO: check for faults in loaded audio
	voice_player.stream = audio


func set_volume(value:float):
	voice_player.volume_db = value

func set_bus(value:String):
	voice_player.bus = value


func stop_audio():
	voice_player.stop()


func set_timer(time:float):
	if !voice_timer:
		voice_timer = Timer.new()
		DialogicUtil.update_timer_process_callback(voice_timer)
		voice_timer.one_shot = true
		add_child(voice_timer)
		voice_timer.timeout.connect(stop_audio)
	voice_timer.stop()
	voice_timer.start(time)


func get_remaining_time() -> float:
	if not voice_timer or voice_timer.is_stopped():
		return 0.0 #contingency
	return voice_timer.time_left


func is_running() -> bool:
	return get_remaining_time() > 0.0
