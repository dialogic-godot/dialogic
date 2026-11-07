extends GdUnitTestSuite

func test_audio_signal() -> void:
	const test_audio_file := "res://addons/dialogic/Example Assets/sound-effects/typing1.wav"
	const test_audio_channel := "One-Shot SFX"
	assert(ResourceLoader.exists(test_audio_file), "Failed to load an audio file to test with.")
	
	DialogicUtil.autoload().Audio.update_audio.call_deferred(test_audio_channel, test_audio_file, {'loop':false})
	var info: Dictionary = await DialogicUtil.autoload().Audio.audio_started
	
	assert(info.has('path') and info.has('channel') and info.has('volume') and info.has('audio_bus') and info.has('loop'), "Info received from Audio signal is missing info.")
	assert(info.get('channel', "") == test_audio_channel, "Received info did not contain the correct channel.")
	assert(info.get('path', "") == test_audio_file, "Received info did not contain the correct file path.")
