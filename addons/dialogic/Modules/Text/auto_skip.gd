extends DialogicSubsystem
class_name AutoSkip

signal autoskip_changed(is_enabled: bool)

var enabled: bool = false : set = _set_enabled
var disable_on_user_input: bool = true
var disable_on_unread_text: bool = true
var enable_on_seen: bool = false
var skip_voice: bool = true
var time_per_event: float = 0.1

func _init():
	enable_on_seen = ProjectSettings.get_setting('dialogic/text/autoskip_enabled', enable_on_seen)
	time_per_event = ProjectSettings.get_setting('dialogic/text/autoskip_time_per_event', time_per_event)

	if Dialogic.has_subsystem('History'):
		Dialogic.History.already_read_event_reached.connect(_handle_seen_event)
		Dialogic.History.not_read_event_reached.connect(_handle_unseen_event)

func _set_enabled(is_enabled: bool) -> void:
	var previous_enabled = enabled
	enabled = is_enabled

	if enabled != previous_enabled:
		autoskip_changed.emit(enabled)

func _handle_seen_event():
	# If Auto-Skip is disabled but reacts to seen events, we
	# enable Auto-Skip.
	if enabled and enable_on_seen:
		disable_on_unread_text = true

	if enabled:
		Dialogic.Text.input_handler.skip()

func _handle_unseen_event() -> void:
	if not enabled:
		return

	if disable_on_unread_text:
		enabled = false

	else:
		Dialogic.Text.input_handler.skip()
