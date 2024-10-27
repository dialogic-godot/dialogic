@tool
extends DialogicSettingsPage

## Settings page that contains settings for the audio subsystem

const MUSIC_MAX_CHANNELS := "dialogic/audio/max_channels"
const TYPE_SOUND_AUDIO_BUS := "dialogic/audio/type_sound_bus"

func _ready() -> void:
	%MusicChannelCount.value_changed.connect(_on_music_channel_count_value_changed)
	%TypeSoundBus.item_selected.connect(_on_type_sound_bus_item_selected)


func _refresh() -> void:
	%MusicChannelCount.value = ProjectSettings.get_setting(MUSIC_MAX_CHANNELS, 4)
	%TypeSoundBus.clear()
	var idx := 0
	for i in range(AudioServer.bus_count):
		%TypeSoundBus.add_item(AudioServer.get_bus_name(i))
		if AudioServer.get_bus_name(i) == ProjectSettings.get_setting(TYPE_SOUND_AUDIO_BUS, ""):
			idx = i
	%TypeSoundBus.select(idx)


func _on_music_channel_count_value_changed(value:float) -> void:
	ProjectSettings.set_setting(MUSIC_MAX_CHANNELS, value)
	ProjectSettings.save()


func _on_type_sound_bus_item_selected(index:int) -> void:
	ProjectSettings.set_setting(TYPE_SOUND_AUDIO_BUS, %TypeSoundBus.get_item_text(index))
	ProjectSettings.save()
