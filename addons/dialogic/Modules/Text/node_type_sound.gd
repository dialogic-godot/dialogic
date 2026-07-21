@tool
@icon("node_type_sound_icon.svg")
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
## Characters that don't increase the '_characters_since_last_sound' variable, useful for the space or fullstop
@export var ignore_characters: String = ' .,'

var _characters_since_last_sound: int = 0
## The base pitch
var base_pitch: float = pitch_scale
var base_volume: float = volume_db
var _RNG := RandomNumberGenerator.new()

var _current_overwrite_data := {}

func _ready() -> void:
	# add to necessary group
	add_to_group('dialogic_type_sounds')

	if not Engine.is_editor_hint() and get_parent() is DialogicNode_DialogText:
		if bus == "Master":
			bus = ProjectSettings.get_setting("dialogic/audio/type_sound_bus", "Master")

		get_parent().started_revealing_text.connect(_on_started_revealing_text)
		get_parent().continued_revealing_text.connect(_on_continued_revealing_text)
		get_parent().finished_revealing_text.connect(_on_finished_revealing_text)


func _on_started_revealing_text() -> void:
	if !enabled or (get_parent() is DialogicNode_DialogText and !get_parent().enabled):
		return
	_characters_since_last_sound = _current_overwrite_data.get('skip_characters', play_every_character-1)+1


func _on_continued_revealing_text(new_character:String) -> void:
	if !enabled or (get_parent() is DialogicNode_DialogText and !get_parent().enabled):
		return

	# We don't want to play type sounds if Auto-Skip is enabled.
	if !Engine.is_editor_hint() and DialogicUtil.autoload().Inputs.auto_skip.enabled:
		return

	# don't play if a voice-track is running
	if !Engine.is_editor_hint() and get_parent() is DialogicNode_DialogText:
		if DialogicUtil.autoload().has_subsystem("Voice") and DialogicUtil.autoload().Voice.is_running():
			return

	# if sound playing and can't interrupt
	if playing and _current_overwrite_data.get('mode', mode) == Modes.AWAIT:
		return

	# if no sounds were given
	if _current_overwrite_data.get('sounds', sounds).size() == 0:
		return

	# if the new character is not allowed
	if new_character in ignore_characters:
		return

	_characters_since_last_sound += 1
	if _characters_since_last_sound < _current_overwrite_data.get('skip_characters', play_every_character-1)+1:
		return

	_characters_since_last_sound = 0

	var audio_player: AudioStreamPlayer = self
	if _current_overwrite_data.get('mode', mode) == Modes.OVERLAP:
		audio_player = AudioStreamPlayer.new()
		audio_player.bus = bus
		add_child(audio_player)
	elif _current_overwrite_data.get('mode', mode) == Modes.INTERRUPT:
		stop()

	#choose the random sound
	audio_player.stream = _current_overwrite_data.get('sounds', sounds)[_RNG.randi_range(0, _current_overwrite_data.get('sounds', sounds).size() - 1)]

	#choose a random pitch and volume
	audio_player.pitch_scale = max(0.0001, _current_overwrite_data.get('pitch_base', base_pitch) + _current_overwrite_data.get('pitch_variance', pitch_variance) * _RNG.randf_range(-1.0, 1.0))
	audio_player.volume_db = _current_overwrite_data.get('volume_base', base_volume) + _current_overwrite_data.get('volume_variance',volume_variance) * _RNG.randf_range(-1.0, 1.0)

	#play the sound
	audio_player.play(0)

	if _current_overwrite_data.get('mode', mode) == Modes.OVERLAP:
		audio_player.finished.connect(audio_player.queue_free)


func _on_finished_revealing_text() -> void:
	# We don't want to play type sounds if Auto-Skip is enabled.
	if !Engine.is_editor_hint() and DialogicUtil.autoload().Inputs.auto_skip.enabled:
		return

	if end_sound != null:
		stream = end_sound
		play()


func load_overwrite(dictionary:Dictionary) -> void:
	_current_overwrite_data = dictionary
	if dictionary.has('sound_path'):
		_current_overwrite_data['sounds'] = DialogicNode_TypeSounds.load_sounds_from_path(dictionary.sound_path)


static func load_sounds_from_path(path:String) -> Array[AudioStream]:
	if path.get_extension().to_lower() in ['mp3', 'wav', 'ogg'] and load(path) is AudioStream:
		return [load(path)]
	var _sounds: Array[AudioStream] = []
	for file in DialogicUtil.listdir(path, true, false, true, true):
		if !file.ends_with('.import'):
			continue
		if file.trim_suffix('.import').get_extension().to_lower() in ['mp3', 'wav', 'ogg'] and ResourceLoader.load(file.trim_suffix('.import')) is AudioStream:
			_sounds.append(ResourceLoader.load(file.trim_suffix('.import')))
	return _sounds


############# USER INTERFACE ###################################################

func _get_configuration_warnings() -> PackedStringArray:
	if not get_parent() is DialogicNode_DialogText:
		return ["This should be the child of a DialogText node!"]
	return []
