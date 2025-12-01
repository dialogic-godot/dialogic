@tool
extends DialogicSettingsPage

## Settings page that contains settings for the audio subsystem

const TYPE_SOUND_AUDIO_BUS := "dialogic/audio/type_sound_bus"
const CHANNEL_DEFAULTS := "dialogic/audio/channel_defaults"

var channel_defaults := {}
var _revalidate_channel_names := false


func _ready() -> void:
	%TypeSoundBus.item_selected.connect(_on_type_sound_bus_item_selected)
	$Panel.add_theme_stylebox_override('panel', get_theme_stylebox("normal", "RichTextLabel"))


func _refresh() -> void:
	%TypeSoundBus.clear()
	var idx := 0
	for i in range(AudioServer.bus_count):
		%TypeSoundBus.add_item(AudioServer.get_bus_name(i))
		if AudioServer.get_bus_name(i) == ProjectSettings.get_setting(TYPE_SOUND_AUDIO_BUS, ""):
			idx = i
	%TypeSoundBus.select(idx)

	load_channel_defaults(DialogicUtil.get_audio_channel_defaults())


func _about_to_close() -> void:
	save_channel_defaults()


## TYPE SOUND AUDIO BUS
func _on_type_sound_bus_item_selected(index:int) -> void:
	ProjectSettings.set_setting(TYPE_SOUND_AUDIO_BUS, %TypeSoundBus.get_item_text(index))
	ProjectSettings.save()


#region AUDIO CHANNELS
################################################################################

func load_channel_defaults(dictionary:Dictionary) -> void:
	channel_defaults.clear()
	for i in %AudioChannelDefaults.get_children():
		i.queue_free()

	var column_names := [
		"Channel Name",
		"Volume",
		"Audio Bus",
		"Fade",
		"Loop",
		""
	]

	for column in column_names:
		var label := Label.new()
		label.text = column
		label.theme_type_variation = 'DialogicHintText2'
		%AudioChannelDefaults.add_child(label)

	var channel_names := dictionary.keys()
	channel_names.sort()

	for channel_name in channel_names:
		add_channel_defaults(
			channel_name,
			dictionary[channel_name].volume,
			dictionary[channel_name].audio_bus,
			dictionary[channel_name].fade_length,
			dictionary[channel_name].loop)

	await get_tree().process_frame

	_revalidate_channel_names = true
	revalidate_channel_names.call_deferred()


func save_channel_defaults() -> void:
	var dictionary := {}

	for i in channel_defaults:
		if is_instance_valid(channel_defaults[i].channel_name):
			var channel_name := ""
			if not channel_defaults[i].channel_name is Label:
				if channel_defaults[i].channel_name.current_value.is_empty():
					continue

				channel_name = channel_defaults[i].channel_name.current_value
				#channel_name = DialogicUtil.channel_name_regex.sub(channel_name, '', true)

			if channel_name.is_empty():
				dictionary[channel_name] = {
					'volume': channel_defaults[i].volume.get_value(),
					'audio_bus': channel_defaults[i].audio_bus.current_value,
					'fade_length': 0.0,
					'loop': false,
				}
			else:
				dictionary[channel_name] = {
					'volume': channel_defaults[i].volume.get_value(),
					'audio_bus': channel_defaults[i].audio_bus.current_value,
					'fade_length': channel_defaults[i].fade_length.get_value(),
					'loop': channel_defaults[i].loop.button_pressed,
				}

	ProjectSettings.set_setting(CHANNEL_DEFAULTS, dictionary)
	ProjectSettings.save()


func _on_add_channel_defaults_pressed() -> void:
	var added_node := add_channel_defaults('new_channel_name', 0.0, '', 0.0, true)
	if added_node:
		added_node.take_autofocus()
	_revalidate_channel_names = true
	revalidate_channel_names.call_deferred()


func add_channel_defaults(channel_name: String, volume: float, audio_bus: String, fade_length: float, loop: bool) -> Control:
	var info := {}

	for i in %AudioChannelDefaultRow.get_children():
		var x := i.duplicate()
		%AudioChannelDefaults.add_child(x)
		info[i.name] = x


	if channel_name.is_empty():
		var channel_label := Label.new()
		channel_label.text = &"One-Shot SFX"
		channel_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		%AudioChannelDefaults.add_child(channel_label)
		%AudioChannelDefaults.move_child(channel_label, info.channel_name.get_index())
		info.channel_name.queue_free()
		info.channel_name = channel_label

		var HintTooltip := preload("res://addons/dialogic/Editor/Common/hint_tooltip_icon.tscn")
		var fade_hint := HintTooltip.instantiate()
		fade_hint.hint_text = "Fading is disabled for this channel."
		%AudioChannelDefaults.add_child(fade_hint)
		%AudioChannelDefaults.move_child(fade_hint, info.fade_length.get_index())
		info.fade_length.queue_free()
		info.fade_length = fade_hint

		var loop_hint := HintTooltip.instantiate()
		loop_hint.hint_text = "Looping is disabled for this channel."
		%AudioChannelDefaults.add_child(loop_hint)
		%AudioChannelDefaults.move_child(loop_hint, info.loop.get_index())
		info.loop.queue_free()
		info.loop = loop_hint

		info.delete.disabled = true

	else:
		info.channel_name.suggestions_func = get_audio_channel_suggestions
		info.channel_name.validation_func = validate_channel_names.bind(info.channel_name)
		info.channel_name.set_value(channel_name)

		info.fade_length.set_value(fade_length)

		info.loop.set_pressed_no_signal(loop)

	info.audio_bus.suggestions_func = DialogicUtil.get_audio_bus_suggestions
	info.audio_bus.set_value(audio_bus)

	info.delete.icon = get_theme_icon(&"Remove", &"EditorIcons")
	info.delete.pressed.connect(_on_remove_channel_defaults_pressed.bind(len(channel_defaults)))

	channel_defaults[len(channel_defaults)] = info
	return info['channel_name']


func _on_remove_channel_defaults_pressed(index: int) -> void:
	for key in channel_defaults[index]:
		channel_defaults[index][key].queue_free()
	channel_defaults.erase(index)


func get_audio_channel_suggestions(search_text:String) -> Dictionary:
	var suggestions := DialogicUtil.get_audio_channel_suggestions(search_text)

	for i in channel_defaults.values():
		if i.channel_name is DialogicVisualEditorField:
			suggestions.erase(i.channel_name.current_value)

	for key in suggestions.keys():
		suggestions[key].erase('tooltip')
		suggestions[key]['editor_icon'] = ["AudioStreamPlayer", "EditorIcons"]

	return suggestions


func revalidate_channel_names() -> void:
	_revalidate_channel_names = false
	for i in channel_defaults:
		if (is_instance_valid(channel_defaults[i].channel_name)
				and not channel_defaults[i].channel_name is Label):
			channel_defaults[i].channel_name.validate()


func validate_channel_names(search_text: String, field_node: Control) -> Dictionary:
	var channel_cache = {}
	var result := {}
	var tooltips := []

	if search_text.is_empty():
		result['error_tooltip'] = 'Must not be empty.'
		return result

	if field_node:
		channel_cache[search_text] = [field_node]
		if field_node.current_value != search_text:
			_revalidate_channel_names = true
			revalidate_channel_names.call_deferred()

	# Collect all channel names entered
	for i in channel_defaults:
		if (is_instance_valid(channel_defaults[i].channel_name)
				and not channel_defaults[i].channel_name is Label
				and channel_defaults[i].channel_name != field_node):
			var text := channel_defaults[i].channel_name.current_value as String
			if not channel_cache.has(text):
				channel_cache[text] = []

			channel_cache[text].append(channel_defaults[i].channel_name)

	# Check for duplicate names
	if channel_cache.has(search_text) and channel_cache[search_text].size() > 1:
		tooltips.append("Duplicate channel name.")

	# Check for invalid characters
	result = DialogicUtil.validate_audio_channel_name(search_text)
	if result:
		tooltips.append(result.error_tooltip)
		result.error_tooltip = "\n".join(tooltips)
	elif not tooltips.is_empty():
		result['error_tooltip'] = "\n".join(tooltips)

	return result
#endregion
