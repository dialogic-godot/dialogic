@tool
class_name DialogicNode_TypeSounds
extends AudioStreamPlayer

## Node that allows playing sounds when text characters are revealed.
## Should be the child of a DialogicNode_DialogText node!

## Usefull if you want to change the sounds ot different node's sounds
@export var enabled := true
## If true, interrupts the current sound to play a new one
@export var interrupt := true
## Array of sounds. Will pick a random one each time.
@export var sounds: Array
## A sound to be played as the last sound.
@export var end_sound:AudioStream
## Determines how many characters are between each sound. Default is 1 for playing it every character.
@export var play_every_character  := 1
## Allows changing the pitch by a random value from (pitch - pitch_variance) to (pitch + pitch_variance)
@export_range(0, 3, 0.01) var pitch_variance := 0.0
## Allows changing the volume by a random value from (volume - volume_variance) to (volume + volume_variance)
@export_range(0, 10, 0.01) var volume_variance := 0.0
## Allow ters that don't increase the 'characters_since_last_sound' variable, useful for the space or fullstop
@export var ignore_characters:String = ' .,'

var dialogic:Node #singleton refrence
var sound_finished = true
var characters_since_last_sound: int = 0
var base_pitch = pitch_scale
var base_volume = volume_db
var RNG = RandomNumberGenerator.new()

var current_overwrite_data = {}

func _ready():
	# add to necessary group
	add_to_group('dialogic_type_sounds')
	if !Engine.is_editor_hint() and get_parent() is DialogicNode_DialogText:
		dialogic = get_node("/root/Dialogic")
		get_parent().started_revealing_text.connect(_on_started_revealing_text)
		get_parent().continued_revealing_text.connect(_on_continued_revealing_text)
		get_parent().finished_revealing_text.connect(_on_finished_revealing_text)

func _on_started_revealing_text() -> void:
	if !enabled:
		return
	characters_since_last_sound = 0

func _on_continued_revealing_text(new_character) -> void:
	#pretty obvious
	if !enabled:
		return
		
	#don't play if a voice-track is running
	if !Engine.is_editor_hint() and get_parent() is DialogicNode_DialogText:
		if dialogic.has_subsystem("Voice") and dialogic.Voice.is_running():
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
	pitch_scale = max(0, current_overwrite_data.get('pitch_base', base_pitch) + current_overwrite_data.get('pitch_variance', pitch_variance) * RNG.randf_range(-1.0, 1.0))
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
	if not get_parent() is DialogicNode_DialogText:
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
