extends DialogicSubsystem

## Subsystem that manages music and sounds.

signal music_started(info:Dictionary)
signal sound_started(info:Dictionary)

var base_music_player := AudioStreamPlayer.new()
var base_sound_player := AudioStreamPlayer.new()


#region STATE
####################################################################################################

func clear_game_state(clear_flag:=DialogicGameHandler.ClearFlags.FULL_CLEAR) -> void:
	update_music()
	stop_all_sounds()


func load_game_state(load_flag:=LoadFlags.FULL_LOAD) -> void:
	if load_flag == LoadFlags.ONLY_DNODES:
		return
	var info: Dictionary = dialogic.current_state_info.get("music", {})
	if info.is_empty() or info.path.is_empty():
		update_music()
	else:
		update_music(info.path, info.volume, info.audio_bus, 0, info.loop)


func pause() -> void:
	for child in get_children():
		child.stream_paused = true


func resume() -> void:
	for child in get_children():
		child.stream_paused = false

#endregion


#region MAIN METHODS
####################################################################################################

func _ready() -> void:
	base_music_player.name = "Music"
	add_child(base_music_player)

	base_sound_player.name = "Sound"
	add_child(base_sound_player)


## Updates the background music. Will fade out previous music.
func update_music(path := "", volume := 0.0, audio_bus := "Master", fade_time := 0.0, loop := true) -> void:
	dialogic.current_state_info['music'] = {'path':path, 'volume':volume, 'audio_bus':audio_bus, 'loop':loop}
	music_started.emit(dialogic.current_state_info['music'])
	var fader: Tween = null
	if base_music_player.playing or !path.is_empty():
		fader = create_tween()
	var prev_node: Node = null
	if base_music_player.playing:
		prev_node = base_music_player.duplicate()
		add_child(prev_node)
		prev_node.play(base_music_player.get_playback_position())
		prev_node.remove_from_group('dialogic_music_player')
		fader.tween_method(interpolate_volume_linearly.bind(prev_node), db_to_linear(prev_node.volume_db),0.0,fade_time)
	if path:
		base_music_player.stream = load(path)
		base_music_player.volume_db = volume
		base_music_player.bus = audio_bus
		if not base_music_player.stream is AudioStreamWAV:
			if "loop" in base_music_player.stream:
				base_music_player.stream.loop = loop
			elif "loop_mode" in base_music_player.stream:
				if loop:
					base_music_player.stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
				else:
					base_music_player.stream.loop_mode = AudioStreamWAV.LOOP_DISABLED

		base_music_player.play(0)
		fader.parallel().tween_method(interpolate_volume_linearly.bind(base_music_player), 0.0, db_to_linear(volume),fade_time)
	else:
		base_music_player.stop()
	if prev_node:
		fader.tween_callback(prev_node.queue_free)


func has_music() -> bool:
	return !dialogic.current_state_info.get('music', {}).get('path', '').is_empty()


## Plays a given sound file.
func play_sound(path:String, volume := 0.0, audio_bus := "Master", loop := false) -> void:
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
		new_sound_node.bus = audio_bus
		add_child(new_sound_node)
		new_sound_node.play()
		new_sound_node.finished.connect(new_sound_node.queue_free)


func stop_all_sounds() -> void:
	for node in get_children():
		if node == base_sound_player:
			continue
		if "Sound" in node.name:
			node.queue_free()


func interpolate_volume_linearly(value:float, node:Node) -> void:
	node.volume_db = linear_to_db(value)


## Returns whether the currently playing audio resource is the same as this
## event's [param resource_path].
func is_music_playing_resource(resource_path: String) -> bool:
	var is_playing_resource: bool = (base_music_player.is_playing()
		and base_music_player.stream.resource_path == resource_path)

	return is_playing_resource

#endregion
