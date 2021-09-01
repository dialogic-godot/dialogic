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
		var s = load(data['file'])
		if s != null:
			stream =  s 
			if data.has('audio_start'):
				play(data['audio_start'])
			else:
				play()
		else:
			stop_voice()
			

func stop_voice():
	stop()
func _process(_delta):
	if(playing && stop_time > 0 && get_playback_position() >= stop_time):
		stop_voice()
