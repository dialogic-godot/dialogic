extends DialogicSubsystem
## Subsystem for managing background music and one-shot sound effects.
##
## This subsystem has many different helper methods for managing audio
## in your timeline.
## For instance, you can listen to music changes via [signal music_started].


## Whenever a new background music is started, this signal is emitted and
## contains a dictionary with the following keys: [br]
## [br]
## Key         |   Value Type  | Value [br]
## ----------- | ------------- | ----- [br]
## `path`      | [type String] | The path to the audio resource file. [br]
## `volume`    | [type float]  | The volume of the audio resource that will be set to the [member base_music_player]. [br]
## `audio_bus` | [type String] | The audio bus name that the [member base_music_player] will use. [br]
## `loop`      | [type bool]   | Whether the audio resource will loop or not once it finishes playing. [br]
signal music_started(info: Dictionary)


## Whenever a new sound effect is set, this signal is emitted and contains a
## dictionary with the following keys: [br]
## [br]
## Key         |   Value Type  | Value [br]
## ----------- | ------------- | ----- [br]
## `path`      | [type String] | The path to the audio resource file. [br]
## `volume`    | [type float]  | The volume of the audio resource that will be set to [member base_sound_player]. [br]
## `audio_bus` | [type String] | The audio bus name that the [member base_sound_player] will use. [br]
## `loop`      | [type bool]   | Whether the audio resource will loop or not once it finishes playing. [br]
signal sound_started(info: Dictionary)


## Audio player base duplicated to play background music.
##
## Background music is long audio.
var base_music_player := AudioStreamPlayer.new()
## Reference to the last used music player.
var current_music_player: AudioStreamPlayer
## Audio player base, that will be duplicated to play sound effects.
##
## Sound effects are short audio.
var base_sound_player := AudioStreamPlayer.new()


#region STATE
####################################################################################################

## Clears the state on this subsystem and stops all audio.
##
## If you want to stop sounds only, use [method stop_all_sounds].
func clear_game_state(_clear_flag := DialogicGameHandler.ClearFlags.FULL_CLEAR) -> void:
	update_music()
	stop_all_sounds()


## Loads the state on this subsystem from the current state info.
func load_game_state(load_flag:=LoadFlags.FULL_LOAD) -> void:
	if load_flag == LoadFlags.ONLY_DNODES:
		return
	var info: Dictionary = dialogic.current_state_info.get("music", {})
	if info.is_empty() or info.path.is_empty():
		update_music()
	else:
		update_music(info.path, info.volume, info.audio_bus, 0, info.loop)


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
	pass
#endregion


#region MAIN METHODS
####################################################################################################

func _ready() -> void:
	dialogic.timeline_ended.connect(_on_dialogic_timeline_ended)
	
	base_music_player.name = "Music"
	add_child(base_music_player)

	base_sound_player.name = "Sound"
	add_child(base_sound_player)


## Updates the background music. Will fade out previous music.
func update_music(path := "", volume := 0.0, audio_bus := "", fade_time := 0.0, loop := true) -> void:

	dialogic.current_state_info['music'] = {'path':path, 'volume':volume, 'audio_bus':audio_bus, 'loop':loop}
	music_started.emit(dialogic.current_state_info['music'])

	var fader: Tween = null
	if is_instance_valid(current_music_player) and current_music_player.playing or !path.is_empty():
		fader = create_tween()

	var prev_node: Node = null
	if is_instance_valid(current_music_player) and current_music_player.playing:
		prev_node = current_music_player.duplicate()
		add_child(prev_node)
		prev_node.play(current_music_player.get_playback_position())
		fader.tween_method(interpolate_volume_linearly.bind(prev_node), db_to_linear(prev_node.volume_db),0.0,fade_time)

	if path:
		current_music_player = base_music_player.duplicate()
		add_child(current_music_player)
		current_music_player.stream = load(path)
		current_music_player.volume_db = volume
		if audio_bus:
			current_music_player.bus = audio_bus
		if not current_music_player.stream is AudioStreamWAV:
			if "loop" in current_music_player.stream:
				current_music_player.stream.loop = loop
			elif "loop_mode" in current_music_player.stream:
				if loop:
					current_music_player.stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
				else:
					current_music_player.stream.loop_mode = AudioStreamWAV.LOOP_DISABLED

		current_music_player.play(0)
		fader.parallel().tween_method(interpolate_volume_linearly.bind(current_music_player), 0.0, db_to_linear(volume),fade_time)
	else:
		if is_instance_valid(current_music_player):
			current_music_player.stop()
			current_music_player.queue_free()

	if prev_node:
		fader.tween_callback(prev_node.queue_free)


## Whether music is playing.
func has_music() -> bool:
	return !dialogic.current_state_info.get('music', {}).get('path', '').is_empty()


## Plays a given sound file.
func play_sound(path: String, volume := 0.0, audio_bus := "", loop := false) -> void:
	if base_sound_player != null and !path.is_empty():
		sound_started.emit({'path':path, 'volume':volume, 'audio_bus':audio_bus, 'loop':loop})

		var new_sound_node := base_sound_player.duplicate()
		new_sound_node.name += "Sound"
		new_sound_node.stream = load(path)

		if "loop" in new_sound_node.stream:
			new_sound_node.stream.loop = loop
		elif "loop_mode" in new_sound_node.stream:
			if loop:
				new_sound_node.stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
			else:
				new_sound_node.stream.loop_mode = AudioStreamWAV.LOOP_DISABLED

		new_sound_node.volume_db = volume
		if audio_bus:
			new_sound_node.bus = audio_bus

		add_child(new_sound_node)
		new_sound_node.play()
		new_sound_node.finished.connect(new_sound_node.queue_free)


## Stops all audio.
func stop_all_sounds() -> void:
	for node in get_children():
		if node == base_sound_player:
			continue
		if "Sound" in node.name:
			node.queue_free()


## Converts a linear loudness value to decibel and sets that volume to
## the given [param node].
func interpolate_volume_linearly(value: float, node: Node) -> void:
	node.volume_db = linear_to_db(value)


## Returns whether the currently playing audio resource is the same as this
## event's [param resource_path].
func is_music_playing_resource(resource_path: String) -> bool:
	var is_playing_resource: bool = (base_music_player.is_playing()
		and base_music_player.stream.resource_path == resource_path)

	return is_playing_resource

#endregion
