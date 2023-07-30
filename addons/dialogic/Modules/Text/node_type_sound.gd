@tool
class_name DialogicNode_TypeSounds
extends AudioStreamPlayer

## Node that allows playing sounds when text characters are revealed.
## Should be the child of a DialogicNode_DialogText node!

## Usefull if you want to change the sounds of different node's sounds
@export var enabled := true
enum Modes {INTERRUPT, OVERLAP, AWAIT}
## If true, interrupts the current sound to play a new one
@export var mode := Modes.INTERRUPT
## Array of sounds. Will pick a random one each time.
@export var sounds: Array[AudioStream] = []
## A sound to be played as the last sound.
@export var end_sound:AudioStream
## Determines how many characters are between each sound. Default is 1 for playing it every character.
@export var play_every_character  := 1
## Allows changing the pitch by a random value from (pitch - pitch_variance) to (pitch + pitch_variance)
@export_range(0, 3, 0.01) var pitch_variance := 0.0
## Allows changing the volume by a random value from (volume - volume_variance) to (volume + volume_variance)
@export_range(0, 10, 0.01) var volume_variance := 0.0
## Characters that don't increase the 'characters_since_last_sound' variable, useful for the space or fullstop
@export var ignore_characters:String = ' .,'

var characters_since_last_sound: int = 0
var base_pitch :float = pitch_scale
var base_volume :float = volume_db
var RNG := RandomNumberGenerator.new()

var current_overwrite_data := {}

func _ready():
	# add to necessary group
	add_to_group('dialogic_type_sounds')
	
	if !Engine.is_editor_hint() and get_parent() is DialogicNode_DialogText:
		get_parent().started_revealing_text.connect(_on_started_revealing_text)
		get_parent().continued_revealing_text.connect(_on_continued_revealing_text)
		get_parent().finished_revealing_text.connect(_on_finished_revealing_text)


func _on_started_revealing_text() -> void:
	if !enabled or (get_parent() is DialogicNode_DialogText and !get_parent().enabled):
		return
	characters_since_last_sound = 0


func _on_continued_revealing_text(new_character:String) -> void:
	if !enabled or (get_parent() is DialogicNode_DialogText and !get_parent().enabled):
		return
	
	# don't play if a voice-track is running
	if !Engine.is_editor_hint() and get_parent() is DialogicNode_DialogText:
		if Dialogic.has_subsystem("Voice") and Dialogic.Voice.is_running():
			return
	
	# if sound playing and can't interrupt
	if playing and current_overwrite_data.get('mode', mode) == Modes.AWAIT:
		return
	
	# if no sounds were given
	if current_overwrite_data.get('sounds', sounds).size() == 0:
		return
	
	# if the new character is not allowed
	if new_character in ignore_characters:
		return
	
	characters_since_last_sound += 1
	if characters_since_last_sound < current_overwrite_data.get('skip_characters', play_every_character-1)+1:
		return
	
	characters_since_last_sound = 0
	
	var audio_player : AudioStreamPlayer = self
	if current_overwrite_data.get('mode', mode) == Modes.OVERLAP:
		audio_player = AudioStreamPlayer.new()
		audio_player.bus = bus
		add_child(audio_player)
	elif current_overwrite_data.get('mode', mode) == Modes.INTERRUPT:
		stop()
	
	#choose the random sound
	audio_player.stream = current_overwrite_data.get('sounds', sounds)[RNG.randi_range(0, sounds.size() - 1)]
	
	#choose a random pitch and volume
	audio_player.pitch_scale = max(0, current_overwrite_data.get('pitch_base', base_pitch) + current_overwrite_data.get('pitch_variance', pitch_variance) * RNG.randf_range(-1.0, 1.0))
	audio_player.volume_db = current_overwrite_data.get('volume_base', base_volume) + current_overwrite_data.get('volume_variance',volume_variance) * RNG.randf_range(-1.0, 1.0)
	
	#play the sound
	audio_player.play(0)
	
	if current_overwrite_data.get('mode', mode) == Modes.OVERLAP:
		audio_player.finished.connect(audio_player.queue_free)


func _on_finished_revealing_text() -> void:
	if end_sound != null:
		stream = end_sound
		play()


func load_overwrite(dictionary:Dictionary) -> void:
	current_overwrite_data = dictionary
	if dictionary.has('sound_path'):
		current_overwrite_data['sounds'] = load_sounds_from_path(dictionary.sound_path)


func load_sounds_from_path(path:String) -> Array:
	if path.get_extension().to_lower() in ['mp3', 'wav', 'ogg'] and load(path) is AudioStream:
		return [load(path)]
	var _sounds := []
	for file in DialogicUtil.listdir(path, true, false, true):
		if file.get_extension().to_lower() in ['mp3', 'wav', 'ogg'] and load(file) is AudioStream:
			_sounds.append(load(file))
	return _sounds


############# USER INTERFACE ###################################################

func _get_configuration_warnings():
	if not get_parent() is DialogicNode_DialogText:
		return ["This should be the child of a DialogText node!"]
	return []
