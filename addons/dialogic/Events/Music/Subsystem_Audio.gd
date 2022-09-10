extends DialogicSubsystem


####################################################################################################
##					STATE
####################################################################################################

func clear_game_state():
	update_music()
	stop_all_sounds()

func load_game_state():
	var info = dialogic.current_state_info.get('music')
	if info == null or info.path.is_empty():
		update_music()
	else:
		update_music(info.path, info.volume, info.audio_bus, 0, info.loop)

func pause() -> void:
	for node in get_tree().get_nodes_in_group('dialogic_music_player'):
		node.stream_paused = true
	for child in get_children():
		child.stream_paused = true

func resume() -> void:
	for node in get_tree().get_nodes_in_group('dialogic_music_player'):
		node.stream_paused = false
	for child in get_children():
		child.stream_paused = false

####################################################################################################
##					MAIN METHODS
####################################################################################################
func update_music(path:String = '', volume:float = 0.0, audio_bus:String = "Master", fade_time:float = 0.0, loop:bool = true) -> void:
	dialogic.current_state_info['music'] = {'path':path, 'volume':volume, 'audio_bus':audio_bus, 'loop':loop}
	for node in get_tree().get_nodes_in_group('dialogic_music_player'):
		var fader = null
		if node.playing or path:
			fader = create_tween()
		var prev_node = null
		if node.playing:
			prev_node = node.duplicate()
			add_child(prev_node)
			prev_node.play(node.get_playback_position())
			prev_node.remove_from_group('dialogic_music_player')
			fader.tween_method(interpolate_volume_linearly.bind(prev_node), db_to_linear(prev_node.volume_db),0.0,fade_time)
		if path:
			node.stream = load(path)
			node.volume_db = volume
			node.bus = audio_bus
			if "loop" in node.stream:
				node.stream.loop = loop
			elif "loop_mode" in node.stream:
				if loop:
					node.stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
				else:
					node.stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
			
			node.play()
			fader.parallel().tween_method(interpolate_volume_linearly.bind(node), 0.0,db_to_linear(volume),fade_time)
		else:
			node.stop()
		if prev_node:
			fader.tween_callback(prev_node.queue_free)


func play_sound(path:String, volume:float = 0.0, audio_bus:String = "Master", loop :bool= false) -> void:
	var sound_node = get_tree().get_nodes_in_group('dialogic_sound_player').front()
	if sound_node and path:
		var new_sound_node = sound_node.duplicate()
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
		new_sound_node.finished.connect(queue_free)

func stop_all_sounds() -> void:
	var sound_nodes = get_tree().get_nodes_in_group('dialogic_sound_player')
	if sound_nodes:
		for sound_player in sound_nodes.front().get_children():
			sound_player.queue_free() 

func interpolate_volume_linearly(value, node):
	node.volume_db = linear_to_db(value)
