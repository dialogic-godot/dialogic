@tool
extends AudioStreamPlayer

class_name DialogicDisplay_TypeSounds

#usefel if you want to change the sounds ot different node's sounds
export(bool) var enabled = true

#interrupts the current sound to play a new one
export(bool) var interrupt = true

#will play a random sound between them
export(Array, AudioStream) var sounds

#will play after all text is revealed
export(AudioStream) var end_sound

#play the sound every "N" characters, default is 1 for playing it every character
export(int, 1, 100) var play_every_character

#changes the pitch by a random value from (pitch - pitch_variance) to (pitch + pitch_variance)
export(float, 0, 3, 0.01) var pitch_variance = 0.0

#changes the volume by a random value from (volume - volume_variance) to (volume + volume_variance)
export(float, 0, 10, 0.01) var volume_variance = 0.0

#characters that don't increase the 'characters_since_last_sound' variable, useful for the space or fullstop
export(String) var ignore_characters = ' .,'

var sound_finished = true
var characters_since_last_sound: int = 0
var base_pitch = pitch_scale
var base_volume = volume_db
var RNG = RandomNumberGenerator.new()

var current_overwrite_data = {}

func _ready():
	# add to necessary group
	add_to_group('dialogic_type_sounds')
	if !Engine.editor_hint and get_parent() is DialogicDisplay_DialogText:
		get_parent().connect('started_revealing_text', self, '_on_started_revealing_text')
		get_parent().connect('continued_revealing_text', self, '_on_continued_revealing_text')
		get_parent().connect('finished_revealing_text', self, '_on_finished_revealing_text')

func _on_started_revealing_text() -> void:
	if !enabled:
		return
	characters_since_last_sound = 0

func _on_continued_revealing_text(new_character) -> void:
	#pretty obvious
	if !enabled:
		return
	
	#if sound playing and can't interrupt
	if !sound_finished and !interrupt:
		return
	
	#if no sounds were given
	if current_overwrite_data.get('sounds', sounds).size() == 0:
		return
	
	#if the new character is not allowed
	if new_character in ignore_characters:
		return
	
	characters_since_last_sound += 1
	if characters_since_last_sound < play_every_character:
		return
	characters_since_last_sound = 0
	
	#choose the random sound
	stream = current_overwrite_data.get('sounds', sounds)[RNG.randi_range(0, sounds.size() - 1)]
	
	#choose a random pitch and volume
	pitch_scale = current_overwrite_data.get('pitch_base', base_pitch) + current_overwrite_data.get('pitch_variance', pitch_variance) * RNG.randf_range(-1.0, 1.0)
	volume_db = current_overwrite_data.get('volume_base', base_volume) + current_overwrite_data.get('volume_variance',volume_variance) * RNG.randf_range(-1.0, 1.0)
	
	#play the sound
	play()
	sound_finished = false

func _on_Sound_finished() -> void:
	sound_finished = true

func _on_finished_revealing_text() -> void:
	if end_sound != null:
		stream = end_sound
		pitch_variance = 1.0
		volume_db = 0.0
		play()

func _get_configuration_warning():
	if not get_parent() is DialogicDisplay_DialogText:
		return "This should be the child of a DialogText node!"
	return ""

func load_sounds_from_folder(folder:String):
	var x_sounds = []
	for i in DialogicUtil.listdir(folder, true, false, true):
		if i.get_extension().to_lower() in ['mp3', 'wav', 'ogg'] and load(i) is AudioStream:
			x_sounds.append(load(i))
	return x_sounds

func load_overwrite(dictionary:Dictionary) -> void:
	current_overwrite_data = dictionary
	if dictionary.has('sound_folder'):
		current_overwrite_data['sounds'] = load_sounds_from_folder(dictionary.sound_folder)
