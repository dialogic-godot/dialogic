extends DialogicSubsystem

const audioplayer_name = "dialogic_dialog_voice"

var voiceregions = []

var voicetimer:Timer

var currentAudio:String

func isVoiced(index:int) -> bool:
	if dialogic.current_timeline_events[index] is DialogicTextEvent:
		if dialogic.current_timeline_events[index-1] is DialogicVoiceEvent:
			return true
	return false

func playVoiceRegion(index:int):
	if index >= len(voiceregions):
		return
	var start:float = voiceregions[index][0]
	var stop:float = voiceregions[index][1]
	for audio_node in get_tree().get_nodes_in_group(audioplayer_name):
		#do not play in invisible nodes. This allows audio (2d and 3d) to be used in themes
		if "visible" in audio_node and not audio_node.visible:
			continue
		audio_node.play(start)
		setTimer(stop - start)
	
func setFile(path:String):
	if currentAudio == path:
		return
	currentAudio = path
	var audio:AudioStream = load(path)
	#TODO: check for faults in loaded audio
	for audio_node in get_tree().get_nodes_in_group(audioplayer_name):
		audio_node.stream = audio
	
func setVolume(value:float):
	for audio_node in get_tree().get_nodes_in_group(audioplayer_name):
		audio_node.volume_db = value

func setRegions(value:Array):
	voiceregions = value

func setBus(value:String):
	for audio_node in get_tree().get_nodes_in_group(audioplayer_name):
		audio_node.bus = value

func stopAudio():
	for audio_node in get_tree().get_nodes_in_group(audioplayer_name):
		audio_node.stop()

func setTimer(time:float):
	if !voicetimer:
		voicetimer = Timer.new()
		voicetimer.one_shot = true
		add_child(voicetimer)
		voicetimer.timeout.connect(stopAudio)
	voicetimer.stop()
	voicetimer.start(time)

func getRemainingTime() -> float:
	if not voicetimer or voicetimer.is_stopped():
		return 0.0 #contingency
	return voicetimer.time_left

func isRunning() -> bool:
	return getRemainingTime() > 0.0
	
# To be overriden by sub-classes
# Fill in everything that should be cleared (for example before loading a different state)
func clear_game_state():
	pass

# To be overriden by sub-classes
# Fill in everything that should be loaded using the dialogic_game_handler.current_state_info
# This is called when a save is loaded
func load_game_state():
	pass
	
