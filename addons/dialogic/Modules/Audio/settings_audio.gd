@tool
extends DialogicSettingsPage

## Settings page that contains settings for the audio subsystem


func _ready() -> void:
	%MusicChannelCount.value_changed.connect(_on_music_channel_count_value_changed)


func _refresh() -> void:
	%MusicChannelCount.value = ProjectSettings.get_setting("dialogic/audio/max_channels", 4)


func _on_music_channel_count_value_changed(value:float) -> void:
	ProjectSettings.set_setting('dialogic/audio/max_channels', value)
	ProjectSettings.save()
