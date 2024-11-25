@tool
## Event that can change the currently playing background music.
## This event won't play new music if it's already playing.
class_name DialogicAudioEvent
extends DialogicEvent

### Settings

## The file to play. If empty, the previous music will be faded out.
var file_path := "":
	set(value):
		if file_path != value:
			file_path = value
			ui_update_needed.emit()
## The channel name to use.
var channel_name := "":
	set(value):
		if channel_name != channel_name_regex.sub(value, '', true):
			channel_name = channel_name_regex.sub(value, '', true)
			var defaults := DialogicUtil.get_channel_defaults().get(channel_name, {})
			if defaults:
				fade_length = defaults.fade_length
				volume = defaults.volume
				audio_bus = defaults.audio_bus
				loop = defaults.loop
				ui_update_needed.emit()
## Sync starting time with different channel (if playing audio on that channel)
var sync_channel := ""
## The length of the fade. If 0 (by default) it's an instant change.
var fade_length: float = 0.0
## The volume the music will be played at.
var volume: float = 0.0
## The audio bus the music will be played at.
var audio_bus := ""
## If true, the audio will loop, otherwise only play once.
var loop := true


var regex := RegEx.create_from_string(r'(?:audio)\s*(?<channel>[\w-]{2,}|[\w]*)?\s*(")?(?<file_path>(?(2)[^"\n]*|[^(: \n]*))(?(2)"|)(?:\s*\[(?<shortcode>.*)\])?')
var channel_name_regex := RegEx.create_from_string(r'(?<dash_only>^-$)|(?<invalid>[^\w-]{1})')

################################################################################
## 						EXECUTE
################################################################################

func _execute() -> void:
	if channel_name.is_empty():
		if file_path.is_empty():
			dialogic.Audio.stop_all_sounds()
		else:
			dialogic.Audio.play_sound(file_path, volume, audio_bus)
	elif not dialogic.Audio.is_audio_playing_resource(file_path, channel_name):
		dialogic.Audio.update_audio(channel_name, file_path, volume, audio_bus, fade_length, loop, sync_channel)


	finish()

################################################################################
## 						INITIALIZE
################################################################################

func _init() -> void:
	event_name = "Audio"
	set_default_color('Color7')
	event_category = "Audio"
	event_sorting_index = 2


func _get_icon() -> Resource:
	return load(this_folder.path_join('icon_music.png'))

################################################################################
## 						SAVING/LOADING
################################################################################

func to_text () -> String:
	var result_string := "audio "

	if not channel_name.is_empty():
		result_string += channel_name + " "
	else:
		loop = false

	if not file_path.is_empty():
		result_string += "\"" + file_path + "\""
	else:
		result_string += "-"

	var shortcode := store_to_shortcode_parameters()
	if not shortcode.is_empty():
		result_string += " [" + shortcode + "]"

	return result_string


func from_text(string:String) -> void:
	# Pre Alpha 17 Conversion
	if string.begins_with('[music'):
		_music_from_text(string)
		return
	elif string.begins_with('[sound'):
		_sound_from_text(string)
		return

	var result := regex.search(string)

	channel_name = result.get_string('channel')

	if result.get_string('file_path') == '-':
		file_path = ""
	else:
		file_path = result.get_string('file_path')

	if not result.get_string('shortcode'):
		return

	load_from_shortcode_parameters(result.get_string('shortcode'))


func get_shortcode_parameters() -> Dictionary:
	return {
		#param_name : property_info
		"path"		: {"property": "file_path", 	"default": "", "custom_stored":true},
		"channel"	: {"property": "channel_name", 	"default": "", "custom_stored":true},
		"sync"		: {"property": "sync_channel", 	"default": ""},
		"fade"		: {"property": "fade_length", 	"default": 0.0},
		"volume"	: {"property": "volume", 		"default": 0.0},
		"bus"		: {"property": "audio_bus", 	"default": "",
						"suggestions": get_bus_suggestions},
		"loop"		: {"property": "loop", 			"default": true},
	}


## Returns a string with all the shortcode parameters.
func store_to_shortcode_parameters(params:Dictionary = {}) -> String:
	if params.is_empty():
		params = get_shortcode_parameters()
	var custom_defaults: Dictionary = DialogicUtil.get_custom_event_defaults(event_name)
	var channel_defaults := DialogicUtil.get_channel_defaults()
	var result_string := ""
	for parameter in params.keys():
		var parameter_info: Dictionary = params[parameter]
		var value: Variant = get(parameter_info.property)
		var default_value: Variant = custom_defaults.get(parameter_info.property, parameter_info.default)

		if parameter_info.get('custom_stored', false):
			continue

		if "set_" + parameter_info.property in self and not get("set_" + parameter_info.property):
			continue

		if channel_name in channel_defaults.keys():
			default_value = channel_defaults[channel_name].get(parameter_info.property, default_value)

		if typeof(value) == typeof(default_value) and value == default_value:
			if not "set_" + parameter_info.property in self or not get("set_" + parameter_info.property):
				continue

		result_string += " " + parameter + '="' + value_to_string(value, parameter_info.get("suggestions", Callable())) + '"'

	return result_string.strip_edges()


func is_valid_event(string:String) -> bool:
	if string.begins_with("audio"):
		return true
	# Pre Alpha 17 Converter
	if string.strip_edges().begins_with('[music ') or string.strip_edges().begins_with('[music]'):
		return true
	if string.strip_edges().begins_with('[sound ') or string.strip_edges().begins_with('[sound]'):
		return true
	return false

#region PreAlpha17 Conversion

func _music_from_text(string:String) -> void:
	var data := parse_shortcode_parameters(string)

	if data.has('channel') and data['channel'].to_int() > 0:
		channel_name = 'music' + str(data['channel'].to_int() + 1)
	else:
		channel_name = 'music'

	# Reapply original defaults as setting channel name may have overridden them
	fade_length = 0.0
	volume = 0.0
	audio_bus = ''
	loop = true

	# Apply any custom event defaults
	for default_prop in DialogicUtil.get_custom_event_defaults('music'):
		if default_prop in self:
			set(default_prop, DialogicUtil.get_custom_event_defaults('music')[default_prop])

	# Apply shortcodes that exist
	if data.has('path'):
		file_path = data['path']
	if data.has('fade'):
		fade_length = data['fade'].to_float()
	if data.has('volume'):
		volume = data['volume'].to_float()
	if data.has('bus'):
		audio_bus = data['bus']
	if data.has('loop'):
		loop = str_to_var(data['loop'])


func _sound_from_text(string:String) -> void:
	var data := parse_shortcode_parameters(string)

	channel_name = ''

	# Reapply original defaults as setting channel name may have overridden them
	fade_length = 0.0
	volume = 0.0
	audio_bus = ''
	loop = false

	# Apply any custom event defaults
	for default_prop in DialogicUtil.get_custom_event_defaults('sound'):
		if default_prop in self:
			set(default_prop, DialogicUtil.get_custom_event_defaults('sound')[default_prop])

	# Apply shortcodes that exist
	if data.has('path'):
		file_path = data['path']
	if data.has('volume'):
		volume = data['volume'].to_float()
	if data.has('bus'):
		audio_bus = data['bus']
	if data.has('loop'):
		loop = str_to_var(data['loop'])

#endregion

################################################################################
## 						EDITOR REPRESENTATION
################################################################################

func build_event_editor() -> void:
	add_header_edit('file_path', ValueType.FILE, {
			'left_text'		: 'Play',
			'file_filter' 	: "*.mp3, *.ogg, *.wav; Supported Audio Files",
			'placeholder' 	: "Silence",
			'editor_icon' 	: ["AudioStreamPlayer", "EditorIcons"]})
	add_header_edit('file_path', ValueType.AUDIO_PREVIEW)

	add_header_edit('channel_name', ValueType.DYNAMIC_OPTIONS, {
		'left_text'			:'on:',
		'placeholder'		: '(One-Shot SFX)',
		'mode'				: 3,
		'suggestions_func' 	: DialogicUtil.get_channel_suggestions.bind(false, self),
		'validation_func'	: DialogicUtil.validate_channel_name,
		'tooltip'			: 'Use an existing channel or type the name for a new channel.',
	})
	add_header_button('', _update_defaults_for_channel, 'Add/Update defaults for this channel',
		editor_node.get_theme_icon('Favorites', 'EditorIcons'), '!file_path.is_empty()')

	add_header_edit('sync_channel', ValueType.DYNAMIC_OPTIONS, {
		'left_text'			:'sync with:',
		'placeholder'		: '(No Sync)',
		'mode'				: 3,
		'suggestions_func' 	: DialogicUtil.get_channel_suggestions.bind(true, self),
		'validation_func'	: DialogicUtil.validate_channel_name,
		'tooltip'			: "Use an existing channel or type the name for a new channel. If channel doesn't exist, this setting will be ignored.",
	}, '!channel_name.is_empty() and !file_path.is_empty()')

	add_body_edit('fade_length', ValueType.NUMBER, {'left_text':'Fade Time:'}, '!channel_name.is_empty()')
	add_body_edit('volume', ValueType.NUMBER, {'left_text':'Volume:', 'mode':2}, '!file_path.is_empty()')
	add_body_edit('audio_bus', ValueType.DYNAMIC_OPTIONS, {
		'left_text':'Audio Bus:',
		'placeholder'		: 'Master',
		'mode'				: 2,
		'suggestions_func' 	: get_bus_suggestions,
	}, '!file_path.is_empty()')
	add_body_edit('loop', ValueType.BOOL, {'left_text':'Loop:'}, '!channel_name.is_empty() and !file_path.is_empty()')


func _update_defaults_for_channel() -> void:
	var defaults := DialogicUtil.get_channel_defaults()
	defaults[channel_name] = {
		'volume': volume,
		'audio_bus': audio_bus,
		'fade_length': fade_length,
		'loop': loop,
	}
	ProjectSettings.set_setting('dialogic/audio/channel_defaults', defaults)
	ProjectSettings.save()


func get_bus_suggestions(search_text:String) -> Dictionary:
	var bus_name_list := {}
	for i in range(AudioServer.bus_count):
		if i == 0:
			bus_name_list[AudioServer.get_bus_name(i)] = {'value':''}
		else:
			bus_name_list[AudioServer.get_bus_name(i)] = {'value':AudioServer.get_bus_name(i)}
	return bus_name_list
