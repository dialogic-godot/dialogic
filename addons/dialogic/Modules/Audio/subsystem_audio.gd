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
## `channel`   | [type String] | The channel name to play the audio on. [br]
## `volume`    | [type float]  | The volume in `db` of the audio resource that will be set to the [AudioStreamPlayer]. [br]
## `audio_bus` | [type String] | The audio bus name that the [AudioStreamPlayer] will use. [br]
## `loop`      | [type bool]   | Whether the audio resource will loop or not once it finishes playing. [br]
signal audio_started(info: Dictionary)


## Audio node for holding audio players
var audio_node := Node.new()
## Sound node for holding sound players
var one_shot_audio_node := Node.new()
## Dictionary with info of all current audio channels
var current_audio_channels: Dictionary = {}

#region STATE
####################################################################################################

## Clears the state on this subsystem and stops all audio.
func clear_game_state(_clear_flag := DialogicGameHandler.ClearFlags.FULL_CLEAR) -> void:
	stop_all_channels()
	stop_all_one_shot_sounds()


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
			update_audio(channel_name, info[channel_name].path, info[channel_name].settings_overrides)


## Pauses playing audio.
func pause() -> void:
	for child in audio_node.get_children():
		child.stream_paused = true
	for child in one_shot_audio_node.get_children():
		child.stream_paused = true


## Resumes playing audio.
func resume() -> void:
	for child in audio_node.get_children():
		child.stream_paused = false
	for child in one_shot_audio_node.get_children():
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
	one_shot_audio_node.name = "OneShotAudios"
	add_child(one_shot_audio_node)


## Plays the given file (or nothing) on the given channel.
## No channel given defaults to the "One-Shot SFX" channel,
##   which does not save audio but can have multiple audios playing simultaneously.
func update_audio(channel_name:= "", path := "", settings_overrides := {}) -> void:
	#volume := 0.0, audio_bus := "", fade_time := 0.0, loop := true, sync_channel := "") -> void:
	if not is_channel_playing(channel_name) and path.is_empty():
		return

	## Determine audio settings
	## TODO use .merged after dropping 4.2 support
	var audio_settings: Dictionary = DialogicUtil.get_audio_channel_defaults().get(channel_name, {})
	audio_settings.merge(
		{"volume":0, "audio_bus":"", "fade_length":0.0, "loop":false, "sync_channel":""}
	)
	audio_settings.merge(settings_overrides, true)

	## Handle previous audio on channel
	if is_channel_playing(channel_name):
		var prev_audio_node: AudioStreamPlayer = current_audio_channels[channel_name]
		prev_audio_node.name += "_Prev"
		if audio_settings.fade_length > 0.0:
			var fade_out_tween: Tween = create_tween()
			fade_out_tween.tween_method(
				interpolate_volume_linearly.bind(prev_audio_node),
				db_to_linear(prev_audio_node.volume_db),
				0.0,
				audio_settings.fade_length)
			fade_out_tween.tween_callback(prev_audio_node.queue_free)

		else:
			prev_audio_node.queue_free()

	## Set state
	if not dialogic.current_state_info.has('audio'):
		dialogic.current_state_info['audio'] = {}

	if not path:
		dialogic.current_state_info['audio'].erase(channel_name)
		return

	dialogic.current_state_info['audio'][channel_name] = {'path':path, 'settings_overrides':settings_overrides}
	audio_started.emit(dialogic.current_state_info['audio'][channel_name])

	var new_player := AudioStreamPlayer.new()
	if channel_name:
		new_player.name = channel_name.validate_node_name()
		audio_node.add_child(new_player)
	else:
		new_player.name = "OneShotSFX"
		one_shot_audio_node.add_child(new_player)

	var file := load(path)
	if file == null:
		printerr("[Dialogic] Audio file \"%s\" failed to load." % path)
		return

	new_player.stream = load(path)

	## Apply audio settings

	## Volume & Fade
	if audio_settings.fade_length > 0.0:
		new_player.volume_db = linear_to_db(0.0)
		var fade_in_tween := create_tween()
		fade_in_tween.tween_method(
			interpolate_volume_linearly.bind(new_player),
			0.0,
			db_to_linear(audio_settings.volume),
			audio_settings.fade_length)

	else:
		new_player.volume_db = audio_settings.volume

	## Audio Bus
	new_player.bus = audio_settings.audio_bus

	## Loop
	if "loop" in new_player.stream:
		new_player.stream.loop = audio_settings.loop
	elif "loop_mode" in new_player.stream:
		if audio_settings.loop:
			new_player.stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
			new_player.stream.loop_begin = 0
			new_player.stream.loop_end = new_player.stream.mix_rate * new_player.stream.get_length()
		else:
			new_player.stream.loop_mode = AudioStreamWAV.LOOP_DISABLED

	## Sync & start player
	if audio_settings.sync_channel and is_channel_playing(audio_settings.sync_channel):
		var play_position: float = current_audio_channels[audio_settings.sync_channel].get_playback_position()
		new_player.play(play_position)

		# TODO Remove this once https://github.com/godotengine/godot/issues/18878 is fixed
		if new_player.stream is AudioStreamWAV and new_player.stream.format == AudioStreamWAV.FORMAT_IMA_ADPCM:
			printerr("[Dialogic] WAV files using Ima-ADPCM compression cannot be synced. Reimport the file using a different compression mode.")
			dialogic.print_debug_moment()
	else:
		new_player.play()

	new_player.finished.connect(_on_audio_finished.bind(new_player, channel_name, path))

	if channel_name:
		current_audio_channels[channel_name] = new_player


## Returns `true` if any audio is playing on the given [param channel_name].
func is_channel_playing(channel_name: String) -> bool:
	return (current_audio_channels.has(channel_name)
		and is_instance_valid(current_audio_channels[channel_name])
		and current_audio_channels[channel_name].is_playing())


## Stops audio on all channels.
func stop_all_channels(fade := 0.0) -> void:
	for channel_name in current_audio_channels.keys():
		update_audio(channel_name, '', {"fade_length":fade})


### Stops all one-shot sounds.
func stop_all_one_shot_sounds() -> void:
	for i in one_shot_audio_node.get_children():
		i.queue_free()


## Converts a linear loudness value to decibel and sets that volume to
## the given [param node].
func interpolate_volume_linearly(value: float, node: AudioStreamPlayer) -> void:
	node.volume_db = linear_to_db(value)


## Returns whether the currently playing audio resource is the same as this
## event's [param resource_path], for [param channel_name].
func is_channel_playing_file(file_path: String, channel_name: String) -> bool:
	return (is_channel_playing(channel_name)
		and current_audio_channels[channel_name].stream.resource_path == file_path)


## Returns `true` if any channel is playing.
func is_any_channel_playing() -> bool:
	for channel in current_audio_channels:
		if is_channel_playing(channel):
			return true
	return false


func _on_audio_finished(player: AudioStreamPlayer, channel_name: String, path: String) -> void:
	if current_audio_channels.has(channel_name) and current_audio_channels[channel_name] == player:
		current_audio_channels.erase(channel_name)
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
	if info.has("path"):
		# Pre Alpha 16 Save Data Conversion
		new_info['music'] = {
			"path":info.path,
			"settings_overrides": {
				"volume":info.volume,
				"audio_bus":info.audio_bus,
				"loop":info.loop}
				}

	else:
		# Pre Alpha 17 Save Data Conversion
		for channel_id in info.keys():
			if info[channel_id].is_empty():
				continue

			var channel_name = "music"
			if channel_id > 0:
				channel_name += str(channel_id + 1)
			new_info[channel_name] = {
				"path": info[channel_id].path,
				"settings_overrides":{
					'volume': info[channel_id].volume,
					'audio_bus': info[channel_id].audio_bus,
					'loop': info[channel_id].loop,
					}
				}

	dialogic.current_state_info['audio'] = new_info
	dialogic.current_state_info.erase('music')

#endregion
