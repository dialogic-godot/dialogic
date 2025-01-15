extends DialogicSubsystem
## Subsystem for managing background audio and one-shot sound effects.
##
## This subsystem has many different helper methods for managing audio
## in your timeline.
## For instance, you can listen to audio changes via [signal audio_started].


## Whenever a new audio event is started, this signal is emitted and
## contains a dictionary with the following keys: [br]
## [br]
## Key         |   Value Type  | Value [br]
## ----------- | ------------- | ----- [br]
## `path`      | [type String] | The path to the audio resource file. [br]
## `volume`    | [type float]  | The volume in `db` of the audio resource that will be set to the [AudioStreamPlayer]. [br]
## `audio_bus` | [type String] | The audio bus name that the [AudioStreamPlayer] will use. [br]
## `loop`      | [type bool]   | Whether the audio resource will loop or not once it finishes playing. [br]
## `channel`   | [type String] | The channel name to play the audio on. [br]
signal audio_started(info: Dictionary)


## Audio node for holding audio players
var audio_node := Node.new()
## Sound node for holding sound players
var sound_node := Node.new()
## Reference to the last used music player.
var current_audio_player: Dictionary = {}

#region STATE
####################################################################################################

## Clears the state on this subsystem and stops all audio.
##
## If you want to stop sounds only, use [method stop_all_sounds].
func clear_game_state(_clear_flag := DialogicGameHandler.ClearFlags.FULL_CLEAR) -> void:
	var info: Dictionary = dialogic.current_state_info.get("audio", {})
	for channel_name in current_audio_player.keys():
		update_audio(channel_name)
	stop_all_sounds()


## Loads the state on this subsystem from the current state info.
func load_game_state(load_flag:=LoadFlags.FULL_LOAD) -> void:
	if load_flag == LoadFlags.ONLY_DNODES:
		return

	# Pre Alpha 17 Converter
	_convert_state_info()

	var info: Dictionary = dialogic.current_state_info.get("audio", {})

	for channel_name in info.keys():
		if info[channel_name].path.is_empty():
			update_audio(channel_name)
		else:
			update_audio(channel_name, info[channel_name].path, info[channel_name].volume, info[channel_name].audio_bus, 0, info[channel_name].loop)


## Pauses playing audio.
func pause() -> void:
	for child in get_children():
		child.stream_paused = true


## Resumes playing audio.
func resume() -> void:
	for child in get_children():
		child.stream_paused = false


func _on_dialogic_timeline_ended() -> void:
	if not dialogic.Styles.get_layout_node():
		clear_game_state()

#endregion


#region MAIN METHODS
####################################################################################################

func _ready() -> void:
	dialogic.timeline_ended.connect(_on_dialogic_timeline_ended)

	audio_node.name = "Audio"
	add_child(audio_node)
	sound_node.name = "Sound"
	add_child(sound_node)


## Updates the background audio. Will fade out previous audio. Can optionally synchronise the start time to the current position of another audio channel.
func update_audio(channel_name: String, path := "", volume := 0.0, audio_bus := "", fade_time := 0.0, loop := true, sync_channel := "") -> void:
	if not dialogic.current_state_info.has('audio'):
		dialogic.current_state_info['audio'] = {}

	if path:
		dialogic.current_state_info['audio'][channel_name] = {'path':path, 'volume':volume, 'audio_bus':audio_bus, 'loop':loop, 'channel':channel_name}
		audio_started.emit(dialogic.current_state_info['audio'][channel_name])
	else:
		dialogic.current_state_info['audio'].erase(channel_name)

	if not has_audio(channel_name) and path.is_empty():
		return

	var fader: Tween = null
	if has_audio(channel_name) or fade_time > 0.0:
		fader = create_tween()

	var prev_node: Node = null
	if has_audio(channel_name):
		prev_node = current_audio_player[channel_name]
		fader.tween_method(interpolate_volume_linearly.bind(prev_node), db_to_linear(prev_node.volume_db),0.0,fade_time)

	if path:
		var new_player := AudioStreamPlayer.new()
		audio_node.add_child(new_player)
		new_player.stream = load(path)
		new_player.volume_db = linear_to_db(0.0) if fade_time > 0.0 else volume
		if audio_bus:
			new_player.bus = audio_bus

		if "loop" in new_player.stream:
			new_player.stream.loop = loop
		elif "loop_mode" in new_player.stream:
			if loop:
				new_player.stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
				new_player.stream.loop_begin = 0
				new_player.stream.loop_end = new_player.stream.mix_rate * new_player.stream.get_length()
			else:
				new_player.stream.loop_mode = AudioStreamWAV.LOOP_DISABLED

		if sync_channel and has_audio(sync_channel):
			var play_position = current_audio_player[sync_channel].get_playback_position()
			new_player.play(play_position)

			# TODO Remove this once https://github.com/godotengine/godot/issues/18878 is fixed
			if new_player.stream.format == AudioStreamWAV.FORMAT_IMA_ADPCM:
				printerr("[Dialogic] WAV files using Ima-ADPCM compression cannot be synced. Reimport the file using a different compression mode.")
				dialogic.print_debug_moment()
		else:
			new_player.play()
		new_player.finished.connect(_on_audio_finished.bind(new_player, channel_name, path))
		if fade_time > 0.0:
			fader.parallel().tween_method(interpolate_volume_linearly.bind(new_player), 0.0, db_to_linear(volume), fade_time)

		current_audio_player[channel_name] = new_player

	if prev_node:
		fader.tween_callback(prev_node.queue_free)


## Whether audio is playing for this [param channel_name].
func has_audio(channel_name: String) -> bool:
	return (current_audio_player.has(channel_name)
		and is_instance_valid(current_audio_player[channel_name])
		and current_audio_player[channel_name].is_playing())


## Stops audio on all channels (does not affect one-shot sounds) with optional fade time.
func stop_all_audio(fade := 0.0) -> void:
	for channel_name in current_audio_player.keys():
		update_audio(channel_name, '', 0.0, '', fade)


## Plays a given sound file.
func play_sound(path: String, volume := 0.0, audio_bus := "", loop := false) -> void:
	if !path.is_empty():
		audio_started.emit({'path':path, 'volume':volume, 'audio_bus':audio_bus, 'loop':loop, 'channel':''})

		var new_player := AudioStreamPlayer.new()
		new_player.stream = load(path)

		if "loop" in new_player.stream:
			new_player.stream.loop = loop
		elif "loop_mode" in new_player.stream:
			if loop:
				new_player.stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
				new_player.stream.loop_begin = 0
				new_player.stream.loop_end = new_player.stream.mix_rate * new_player.stream.get_length()
			else:
				new_player.stream.loop_mode = AudioStreamWAV.LOOP_DISABLED

		new_player.volume_db = volume
		if audio_bus:
			new_player.bus = audio_bus

		sound_node.add_child(new_player)
		new_player.play()
		new_player.finished.connect(new_player.queue_free)


## Stops all one-shot sounds.
func stop_all_sounds() -> void:
	for node in sound_node.get_children():
		node.queue_free()


## Converts a linear loudness value to decibel and sets that volume to
## the given [param node].
func interpolate_volume_linearly(value: float, node: Node) -> void:
	node.volume_db = linear_to_db(value)


## Returns whether the currently playing audio resource is the same as this
## event's [param resource_path], for [param channel_name].
func is_audio_playing_resource(resource_path: String, channel_name: String) -> bool:
	return (has_audio(channel_name)
		and current_audio_player[channel_name].stream.resource_path == resource_path)


func _on_audio_finished(player: AudioStreamPlayer, channel_name: String, path: String) -> void:
	if current_audio_player.has(channel_name) and current_audio_player[channel_name] == player:
		current_audio_player.erase(channel_name)
	player.queue_free()
	if dialogic.current_state_info.get('audio', {}).get(channel_name, {}).get('path', '') == path:
		dialogic.current_state_info['audio'].erase(channel_name)

#endregion


#region Pre Alpha 17 Conversion

func _convert_state_info() -> void:
	var info: Dictionary = dialogic.current_state_info.get("music", {})
	if info.is_empty():
		return

	var new_info := {}
	if info.has('path'):
		# Pre Alpha 16 Save Data Conversion
		new_info['music'] = info
	else:
		# Pre Alpha 17 Save Data Conversion
		for channel_id in info.keys():
			var channel_name = "music"
			if channel_id > 0:
				channel_name += str(channel_id + 1)
			if not info[channel_id].is_empty():
				new_info[channel_name] = {
					'path': info[channel_id].path,
					'volume': info[channel_id].volume,
					'audio_bus': info[channel_id].audio_bus,
					'loop': info[channel_id].loop,
					'channel': channel_name,
				}
	dialogic.current_state_info['audio'] = new_info
	dialogic.current_state_info.erase('music')

#endregion
