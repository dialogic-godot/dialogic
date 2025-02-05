@tool
extends DialogicSettingsPage

## Settings page that contains settings for the audio subsystem

const TYPE_SOUND_AUDIO_BUS := "dialogic/audio/type_sound_bus"
const CHANNEL_DEFAULTS := "dialogic/audio/channel_defaults"

var channel_defaults := {}
var _revalidate_channel_names := false


func _ready() -> void:
	%TypeSoundBus.item_selected.connect(_on_type_sound_bus_item_selected)
	$Panel.add_theme_stylebox_override('panel', get_theme_stylebox("Background", "EditorStyles"))



func _refresh() -> void:
	%TypeSoundBus.clear()
	var idx := 0
	for i in range(AudioServer.bus_count):
		%TypeSoundBus.add_item(AudioServer.get_bus_name(i))
		if AudioServer.get_bus_name(i) == ProjectSettings.get_setting(TYPE_SOUND_AUDIO_BUS, ""):
			idx = i
	%TypeSoundBus.select(idx)

	load_channel_defaults(DialogicUtil.get_channel_defaults())


func _about_to_close() -> void:
	save_channel_defaults()


func _on_type_sound_bus_item_selected(index:int) -> void:
	ProjectSettings.set_setting(TYPE_SOUND_AUDIO_BUS, %TypeSoundBus.get_item_text(index))
	ProjectSettings.save()


## CHANNEL DEFAULTS
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


func add_channel_defaults(channel_name: String, volume: float, audio_bus: String, fade: float, loop: bool) -> Control:
	var info := {}

	if channel_name.is_empty():
		var channel_label = Label.new()
		channel_label.text = 'One-Shot SFX'
		channel_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info['channel_name'] = channel_label
		%AudioChannelDefaults.add_child(channel_label)
	else:
		var channel_options := preload("res://addons/dialogic/Editor/Events/Fields/field_options_dynamic.tscn").instantiate()
		channel_options._load_display_info({
			'placeholder'		: 'Enter channel name',
			'mode'				: 3,
			'suggestions_func' 	: get_channel_suggestions,
			'validation_func'	: validate_channel_names.bind(channel_options)
		})
		channel_options.set_value(channel_name)
		channel_options.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info['channel_name'] = channel_options
		%AudioChannelDefaults.add_child(channel_options)

	var volume_field := preload("res://addons/dialogic/Editor/Events/Fields/field_number.tscn").instantiate()
	volume_field.use_decibel_mode(0.1)
	volume_field.set_value(volume)
	info['volume'] = volume_field
	%AudioChannelDefaults.add_child(volume_field)

	var bus_options := preload("res://addons/dialogic/Editor/Events/Fields/field_options_dynamic.tscn").instantiate()
	bus_options._load_display_info({
		'placeholder'		: 'Master',
		'mode'				: 2,
		'suggestions_func' 	: get_bus_suggestions
	})
	bus_options.set_value(audio_bus)
	info['audio_bus'] = bus_options
	%AudioChannelDefaults.add_child(bus_options)

	if channel_name.is_empty():
		var fade_disabled := TextureRect.new()
		fade_disabled.texture = get_theme_icon('NodeInfo', 'EditorIcons')
		fade_disabled.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		fade_disabled.set_anchors_preset(Control.PRESET_FULL_RECT)
		fade_disabled.tooltip_text = "Fading is disbaled for this channel."
		info['fade_length'] = fade_disabled
		%AudioChannelDefaults.add_child(fade_disabled)

		info['loop'] = fade_disabled.duplicate()
		info['loop'].tooltip_text = "Looping is disabled for this channel."
		%AudioChannelDefaults.add_child(info['loop'])
	else:
		var fade_field := preload("res://addons/dialogic/Editor/Events/Fields/field_number.tscn").instantiate()
		fade_field.use_float_mode(0.1)
		fade_field.set_value(fade)
		fade_field.min = 0.0
		info['fade_length'] = fade_field
		%AudioChannelDefaults.add_child(fade_field)

		var loop_button := CheckButton.new()
		loop_button.set_pressed_no_signal(loop)
		info['loop'] = loop_button
		%AudioChannelDefaults.add_child(loop_button)

	var remove_btn := Button.new()
	remove_btn.icon = get_theme_icon(&'Remove', &'EditorIcons')
	remove_btn.pressed.connect(_on_remove_channel_defaults_pressed.bind(len(channel_defaults)))
	remove_btn.disabled = channel_name.is_empty()
	info['delete'] = remove_btn
	%AudioChannelDefaults.add_child(remove_btn)
	channel_defaults[len(channel_defaults)] = info

	return info['channel_name']


func _on_remove_channel_defaults_pressed(index: int) -> void:
	for key in channel_defaults[index]:
		channel_defaults[index][key].queue_free()
	channel_defaults.erase(index)


func get_bus_suggestions(search_text:String) -> Dictionary:
	var bus_name_list := {}
	for i in range(AudioServer.bus_count):
		bus_name_list[AudioServer.get_bus_name(i)] = {'value':AudioServer.get_bus_name(i)}
	return bus_name_list


func get_channel_suggestions(search_text:String) -> Dictionary:
	var suggestions := DialogicUtil.get_channel_suggestions(search_text)

	var suggestion_values := []
	for key in suggestions.keys():
		if suggestions[key].value:
			suggestion_values.append(suggestions[key].value)
		else:
			suggestions.erase(key)

	for i in channel_defaults:
		if (is_instance_valid(channel_defaults[i].channel_name)
				and not channel_defaults[i].channel_name is Label
				and channel_defaults[i].channel_name.current_value in suggestion_values):
			suggestions.erase(channel_defaults[i].channel_name.current_value)

	for key in suggestions.keys():
		suggestions[key].erase('tooltip')
		suggestions[key]['editor_icon'] = ["AudioStream", "EditorIcons"]

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
	result = DialogicUtil.validate_channel_name(search_text)
	if result:
		tooltips.append(result.error_tooltip)
		result.error_tooltip = "\n".join(tooltips)
	elif not tooltips.is_empty():
		result['error_tooltip'] = "\n".join(tooltips)

	return result
