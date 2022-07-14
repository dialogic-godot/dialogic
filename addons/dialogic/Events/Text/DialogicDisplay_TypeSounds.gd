tool
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
export(String) var disallowed_characters = ' .,'

#might want to change how to get the dialog node
onready var dialog_text_node = get_parent()

var sound_finished = true
var characters_since_last_sound: int = 0
var base_pitch = pitch_scale
var base_volume = volume_db
var RNG = RandomNumberGenerator.new()

func _ready():
	assert(dialog_text_node is DialogicDisplay_DialogText, "[Dialogic] DialogicDisplay_TypeSound needs to be the child of a DialogText node!")
	if !Engine.editor_hint:
		dialog_text_node.connect('started_revealing_text', self, '_on_started_revealing_text')
		dialog_text_node.connect('continued_revealing_text', self, '_on_continued_revealing_text')
		dialog_text_node.connect('finished_revealing_text', self, '_on_finished_revealing_text')

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
	if sounds.size() == 0:
		return
	
	#if the new character is not allowed
	if new_character in disallowed_characters:
		return
	
	characters_since_last_sound += 1
	if characters_since_last_sound < play_every_character:
		return
	characters_since_last_sound = 0
	
	#choose the random sound
	stream = sounds[RNG.randi_range(0, sounds.size() - 1)]
	
	#choose a random pitch and volume
	pitch_scale = base_pitch + pitch_variance * RNG.randf_range(-1.0, 1.0)
	volume_db = base_volume + volume_variance * RNG.randf_range(-1.0, 1.0)
	
	#play the sound
	play()
	sound_finished = false


func _on_Sound_finished() -> void:
	sound_finished = true

func _on_finished_revealing_text() -> void:
	if end_sound != null:
		stream = end_sound
		play()

func _get_configuration_warning():
	if not get_parent() is DialogicDisplay_DialogText:
		return "This should be the child of a DialogText node!"
	return ""
