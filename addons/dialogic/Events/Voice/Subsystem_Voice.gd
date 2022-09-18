extends DialogicSubsystem

const audioplayer_name := "dialogic_dialog_voice"
var voiceregions := []
var voicetimer:Timer
var currentAudio:String

####################################################################################################
##					STATE
####################################################################################################
func clear_game_state() -> void:
	pass

func load_game_state() -> void:
	pass

func pause() -> void:
	for audio_node in get_tree().get_nodes_in_group(audioplayer_name):
		audio_node.stream_paused = true
	voicetimer.paused = true

func resume() -> void:
	for audio_node in get_tree().get_nodes_in_group(audioplayer_name):
		audio_node.stream_paused = false
	voicetimer.paused = false

####################################################################################################
##					MAIN METHODS
####################################################################################################
func is_voiced(index:int) -> bool:
	if dialogic.current_timeline_events[index] is DialogicTextEvent:
		if dialogic.current_timeline_events[index-1] is DialogicVoiceEvent:
			return true
	return false

func play_voice_region(index:int):
	if index >= len(voiceregions):
		return
	var start:float = voiceregions[index][0]
	var stop:float = voiceregions[index][1]
	for audio_node in get_tree().get_nodes_in_group(audioplayer_name):
		#do not play in invisible nodes. This allows audio (2d and 3d) to be used in styles
		if "visible" in audio_node and not audio_node.visible:
			continue
		audio_node.play(start)
	set_timer(stop - start)

func set_file(path:String):
	if currentAudio == path:
		return
	currentAudio = path
	var audio:AudioStream = load(path)
	#TODO: check for faults in loaded audio
	for audio_node in get_tree().get_nodes_in_group(audioplayer_name):
		audio_node.stream = audio
	
func set_volume(value:float):
	for audio_node in get_tree().get_nodes_in_group(audioplayer_name):
		audio_node.volume_db = value

func set_regions(value:Array):
	voiceregions = value

func set_bus(value:String):
	for audio_node in get_tree().get_nodes_in_group(audioplayer_name):
		audio_node.bus = value

func stop_audio():
	for audio_node in get_tree().get_nodes_in_group(audioplayer_name):
		audio_node.stop()

func set_timer(time:float):
	if !voicetimer:
		voicetimer = Timer.new()
		DialogicUtil.update_timer_process_callback(voicetimer)
		voicetimer.one_shot = true
		add_child(voicetimer)
		voicetimer.timeout.connect(stop_audio)
	voicetimer.stop()
	voicetimer.start(time)

func get_remaining_time() -> float:
	if not voicetimer or voicetimer.is_stopped():
		return 0.0 #contingency
	return voicetimer.time_left

func is_running() -> bool:
	return get_remaining_time() > 0.0

