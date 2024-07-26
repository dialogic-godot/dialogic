extends DialogicSubsystem
## Subsystem that manages setting voice lines for text events.
##
## It's recommended to use the [class DialogicVoiceEvent] to set the voice lines
## for text events and not start playing them directly.


## Emitted whenever a new voice line starts playing.
## The [param info] contains the following keys and values:
## [br]
## Key      |   Value Type  | Value [br]
## -------- | ------------- | ----- [br]
## `file`   | [type String] | The path to file played. [br]
signal voiceline_started(info: Dictionary)


## Emitted whenever a voice line finished playing.
## The [param info] contains the following keys and values:
## [br]
## Key              |   Value Type  | Value [br]
## ---------------- | ------------- | ----- [br]
## `file`           | [type String] | The path to file played. [br]
## `remaining_time` | [type float]  | The remaining time of the voiceline. [br]
signal voiceline_finished(info: Dictionary)


## Emitted whenever a voice line gets interrupted and does not finish playing.
## The [param info] contains the following keys and values:
## [br]
## Key              |   Value Type  | Value [br]
## ---------------- | ------------- | ----- [br]
## `file`           | [type String] | The path to file played. [br]
## `remaining_time` | [type float]  | The remaining time of the voiceline. [br]
signal voiceline_stopped(info: Dictionary)


## The current audio file being played.
var current_audio_file: String

## The audio player for the voiceline.
var voice_player := AudioStreamPlayer.new()

#region STATE
####################################################################################################

## Stops the current voice from playing.
func pause() -> void:
	voice_player.stream_paused = true


## Resumes a paused voice.
func resume() -> void:
	voice_player.stream_paused = false

#endregion


#region MAIN METHODS
####################################################################################################

func _ready() -> void:
	add_child(voice_player)
	voice_player.finished.connect(_on_voice_finished)


## Whether the current event is a text event and has a voice
## event before it.
func is_voiced(index: int) -> bool:
	if index > 0 and dialogic.current_timeline_events[index] is DialogicTextEvent:
		if dialogic.current_timeline_events[index-1] is DialogicVoiceEvent:
			return true

	return false


## Plays the voice line. This will be invoked by Dialogic.
## Requires [method set_file] to be called before or nothing plays.
func play_voice() -> void:
	voice_player.play()
	voiceline_started.emit({'file': current_audio_file})


## Set a voice file [param path] to be played, then invoke [method play_voice].
##
## This method does not check if [param path] is a valid file.
func set_file(path: String) -> void:
	if current_audio_file == path:
		return

	current_audio_file = path
	var audio: AudioStream = load(path)
	voice_player.stream = audio


## Set the volume to a [param value] in decibels.
func set_volume(value: float) -> void:
	voice_player.volume_db = value


## Set the voice player's bus to a [param bus_name].
func set_bus(bus_name: String) -> void:
	voice_player.bus = bus_name


## Stops the current voice line from playing.
func stop_audio() -> void:
	if voice_player.playing:
		voiceline_stopped.emit({'file':current_audio_file, 'remaining_time':get_remaining_time()})

	voice_player.stop()


## Called when the voice line finishes playing.
## Connected to [signal finished] on [member voice_player]
func _on_voice_finished() -> void:
	voiceline_finished.emit({'file':current_audio_file, 'remaining_time':get_remaining_time()})


## Returns the remaining time of the current voice line in seconds.
##
## If there is no voice line playing, returns `0`.
func get_remaining_time() -> float:
	if not voice_player or not voice_player.playing:
		return 0.0

	var stream_length := voice_player.stream.get_length()
	var playback_position := voice_player.get_playback_position()
	var remaining_seconds := stream_length - playback_position

	return remaining_seconds


## Whether there is still positive time remaining for the current voiceline.
func is_running() -> bool:
	return get_remaining_time() > 0.0

#endregion
