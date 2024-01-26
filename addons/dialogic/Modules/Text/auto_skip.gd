extends RefCounted
class_name DialogicAutoSkip
## This class holds the settings for the Auto-Skip feature.
## Changing the variables will alter the behaviour of Auto-Skip.
##
## Auto-Skip must be implemented per event.

## Emitted whenever the Auto-Skip state changes, from `true` to `false` or
## vice-versa.
signal toggled(is_enabled: bool)

## Whether Auto-Skip is enabled or not.
## If Auto-Skip is referred to be [i]disabled[/i], it refers to setting this
## this variable to `false`.
## This variable will automatically emit [signal autoskip_changed] when changed.
var enabled: bool = false : set = _set_enabled

## If `true`, Auto-Skip will be disabled when the user presses a recognised
## input action.
var disable_on_user_input: bool = true

## If `true`, Auto-Skip will be disabled when the timeline advances to a
## unread Text event or an event requesting user input.
var disable_on_unread_text: bool = true

## If `true`, Auto-Skip will be enabled when the timeline advances to a seen
## Text event.
## Useful if the player always wants to skip seen Text events.
var enable_on_seen: bool = true

## If `true`, Auto-Skip will skip Voice events instead of playing them.
var skip_voice: bool = true

## The amount of seconds each event may take.
## This is not enforced, each event must implement this behaviour.
var time_per_event: float = 0.1


## Setting up Auto-Skip.
func _init():
	enable_on_seen = ProjectSettings.get_setting('dialogic/text/autoskip_enabled', enable_on_seen)
	time_per_event = ProjectSettings.get_setting('dialogic/text/autoskip_time_per_event', time_per_event)

	if Dialogic.has_subsystem('History'):
		Dialogic.History.already_read_event_reached.connect(_handle_seen_event)
		Dialogic.History.not_read_event_reached.connect(_handle_unseen_event)

## Called when Auto-Skip is enabled or disabled.
## Emits [signal autoskip_changed] if the state changed.
func _set_enabled(is_enabled: bool) -> void:
	var previous_enabled := enabled
	enabled = is_enabled

	if enabled != previous_enabled:
		toggled.emit(enabled)

func _handle_seen_event():
	# If Auto-Skip is disabled but reacts to seen events, we
	# enable Auto-Skip.
	if not enabled and enable_on_seen:
		enabled = true

func _handle_unseen_event() -> void:
	if not enabled:
		return

	if disable_on_unread_text:
		enabled = false
