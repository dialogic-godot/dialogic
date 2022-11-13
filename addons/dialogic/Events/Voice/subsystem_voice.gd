extends DialogicSubsystem

## Subsystem that manages setting voice lines for text events.


## The group that voice players are added too.
const audioplayer_name := "dialogic_dialog_voice"

## The current voice regions
var voice_regions := []
## The current voice timer
var voice_timer:Timer
## The current audio
var current_audio_file:String


####################################################################################################
##					STATE
####################################################################################################

func pause() -> void:
	for audio_node in get_tree().get_nodes_in_group(audioplayer_name):
		audio_node.stream_paused = true
	if voice_timer:
		voice_timer.paused = true


func resume() -> void:
	for audio_node in get_tree().get_nodes_in_group(audioplayer_name):
		audio_node.stream_paused = false
	if voice_timer:
		voice_timer.paused = false


####################################################################################################
##					MAIN METHODS
####################################################################################################

func is_voiced(index:int) -> bool:
	if dialogic.current_timeline_events[index] is DialogicTextEvent:
		if dialogic.current_timeline_events[index-1] is DialogicVoiceEvent:
			return true
	return false


func play_voice_region(index:int):
	if index >= len(voice_regions):
		return
	var start:float = voice_regions[index][0]
	var stop:float = voice_regions[index][1]
	for audio_node in get_tree().get_nodes_in_group(audioplayer_name):
		#do not play in invisible nodes. This allows audio (2d and 3d) to be used in styles
		if "visible" in audio_node and not audio_node.visible:
			continue
		audio_node.play(start)
	set_timer(stop - start)


func set_file(path:String):
	if current_audio_file == path:
		return
	current_audio_file = path
	var audio:AudioStream = load(path)
	#TODO: check for faults in loaded audio
	for audio_node in get_tree().get_nodes_in_group(audioplayer_name):
		audio_node.stream = audio


func set_volume(value:float):
	for audio_node in get_tree().get_nodes_in_group(audioplayer_name):
		audio_node.volume_db = value


func set_regions(value:Array):
	voice_regions = value


func set_bus(value:String):
	for audio_node in get_tree().get_nodes_in_group(audioplayer_name):
		audio_node.bus = value


func stop_audio():
	for audio_node in get_tree().get_nodes_in_group(audioplayer_name):
		audio_node.stop()


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
