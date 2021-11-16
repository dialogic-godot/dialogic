extends AudioStreamPlayer

var stop_time:float

func play_voice(data:Dictionary) -> void:
	if data == {}:
		stop_voice()
		return 
	
	if data.has('volume'):
		volume_db = data['volume']
	
	if data.has('audio_bus'):
		bus	 = data['audio_bus']
	
	if data.has('file'):
		if data['file'] == '':
			stop_voice()
			return 
		var s:AudioStream = load(data['file'])
		if s != null:
			stream = s
			#Will play from start_time when possible
			if data.has('start_time'):
				play(data['start_time'])
			else:
				play()
			#Stop time will fall back to length of audiostream minus 0.1 secund
			#if not defined otherwise. This should allow _process to stop the
			#audio before it autorepeats
			if data.has('stop_time'):
				stop_time = data['stop_time']
				if stop_time <= 0:
					stop_time = s.get_length() - 0.1
			else:
				stop_time = s.get_length() - 0.1
		else:
			stop_voice()
func stop_voice():
	stop()
#this is part of a hack, and could be replaced with something more elegant. - KvaGram	
func remaining_time():
	if !playing:
		return 0
	return stop_time - get_playback_position()

	
func _process(_delta):
	#Will automatically stop playing when reaching stop_time
	if(playing && get_playback_position() >= stop_time):
		stop_voice()
