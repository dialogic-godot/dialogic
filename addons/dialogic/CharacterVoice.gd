extends AudioStreamPlayer


func play_voice(data:Dictionary) -> void:
	print(data)
	if data == {}:
		stop_voice()
		return 
	
	if data.has('volume'):
		volume_db = data['volume']
	
	if data.has('audio_bus'):
		bus	 = data['audio_bus']
	
	if data.has('file'):
		if data['file'] == null:
			stop_voice()
			return 
		var s = load(data['file'])
		if s != null:
			stream =  s 
			play()
		else:
			stop_voice()
			

func stop_voice():
	stop()
