@tool
## Event that can play audio on a channel. The channel can be prededinfed
## (with default settings defined in the settings) or created on the spot.
## If no channel is given will play as a One-Shot SFX.
class_name DialogicAudioEvent
extends DialogicEvent

### Settings

## The file to play. If empty, the previous audio will be faded out.
var file_path := "":
	set(value):
		if file_path != value:
			file_path = value
			ui_update_needed.emit()
## The channel name to use. If none given plays as a One-Shot SFX.
var channel_name := "":
	set(value):
		if channel_name != channel_name_regex.sub(value, '', true):
			channel_name = channel_name_regex.sub(value, '', true)
			var defaults: Dictionary = DialogicUtil.get_audio_channel_defaults().get(channel_name, {})
			if defaults:
				fade_length = defaults.fade_length
				volume = defaults.volume
				audio_bus = defaults.audio_bus
				loop = defaults.loop
				ui_update_needed.emit()

## The length of the fade. If 0 it's an instant change.
var fade_length: float = 0.0
## The volume in decibel.
var volume: float = 0.0
## The audio bus the audio will be played on.
var audio_bus := ""
## If true, the audio will loop, otherwise only play once.
var loop := true
## Sync starting time with different channel (if playing audio on that channel)
var sync_channel := ""

## Helpers. Set automatically
var set_fade_length := false
var set_volume := false
var set_audio_bus := false
var set_loop := false
var set_sync_channel := false

var regex := RegEx.create_from_string(r'(?:audio)\s*(?<channel>[\w-]{2,}|[\w]*)?\s*(")?(?<file_path>(?(2)[^"\n]*|[^(: \n]*))(?(2)"|)(?:\s*\[(?<shortcode>.*)\])?')
var channel_name_regex := RegEx.create_from_string(r'(?<dash_only>^-$)|(?<invalid>[^\w-]{1})')

################################################################################
## 						EXECUTE
################################################################################

func _execute() -> void:
	var audio_settings_overrides := {}
	if set_audio_bus:
		audio_settings_overrides["audio_bus"] = audio_bus
	if set_volume:
		audio_settings_overrides["volume"] = volume
	if set_fade_length:
		audio_settings_overrides["fade_length"] = fade_length
	if set_loop:
		audio_settings_overrides["loop"] = loop
	audio_settings_overrides["sync_channel"] = sync_channel
	dialogic.Audio.update_audio(channel_name, file_path, audio_settings_overrides)

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
		"path"		: {"property": "file_path", 	"default": "", "custom_stored":true, "ext_file":true},
		"channel"	: {"property": "channel_name", 	"default": "", "custom_stored":true},
		"fade"		: {"property": "fade_length", 	"default": 0.0},
		"volume"	: {"property": "volume", 		"default": 0.0},
		"bus"		: {"property": "audio_bus", 	"default": "",
						"suggestions": DialogicUtil.get_audio_bus_suggestions},
		"loop"		: {"property": "loop", 			"default": true},
		"sync"		: {"property": "sync_channel", 	"default": "",
						"suggestions": get_sync_audio_channel_suggestions},
	}


## Returns a string with all the shortcode parameters.
func store_to_shortcode_parameters(params:Dictionary = {}) -> String:
	if params.is_empty():
		params = get_shortcode_parameters()
	var custom_defaults: Dictionary = DialogicUtil.get_custom_event_defaults(event_name)
	var channel_defaults := DialogicUtil.get_audio_channel_defaults()
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
	if string.strip_edges().begins_with('[music '):
		return true
	if string.strip_edges().begins_with('[sound '):
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
		set_fade_length = true
		fade_length = data['fade'].to_float()
	if data.has('volume'):
		set_volume = true
		volume = data['volume'].to_float()
	if data.has('bus'):
		set_audio_bus = true
		audio_bus = data['bus']
	if data.has('loop'):
		set_loop = true
		loop = str_to_var(data['loop'])
	update_text_version()


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
		set_volume = true
		volume = data['volume'].to_float()
	if data.has('bus'):
		set_audio_bus = true
		audio_bus = data['bus']
	if data.has('loop'):
		set_loop = true
		loop = str_to_var(data['loop'])
	update_text_version()


#endregion

################################################################################
## 						EDITOR REPRESENTATION
################################################################################

func build_event_editor() -> void:
	add_header_edit('file_path', ValueType.FILE, {
			'left_text'		: 'Play',
			'file_filter' 	: "*.mp3, *.ogg, *.wav; Supported Audio Files",
			'placeholder' 	: "Nothing",
			'editor_icon' 	: ["AudioStreamMP3", "EditorIcons"]})
	add_header_edit('file_path', ValueType.AUDIO_PREVIEW)

	add_header_edit('channel_name', ValueType.DYNAMIC_OPTIONS, {
		'left_text'			:"on",
		"right_text"		: "channel.",
		'placeholder'		: '(One-Shot SFX)',
		'mode'				: 3,
		'suggestions_func' 	: get_audio_channel_suggestions,
		'validation_func'	: DialogicUtil.validate_audio_channel_name,
		'tooltip'			: 'Use an existing channel or type the name for a new channel.',
	})

	add_header_button('', _open_audio_settings, 'Edit Audio Channels',
		editor_node.get_theme_icon("ExternalLink", "EditorIcons"))

	add_body_edit("set_fade_length", ValueType.BOOL_BUTTON,{
			"editor_icon"	: ["FadeCross", "EditorIcons"],
			"tooltip"		: "Overwrite Fade Length"
			},"!channel_name.is_empty() and has_channel_defaults()")
	add_body_edit('fade_length', ValueType.NUMBER, {'left_text':'Fade Time:'},
	'!channel_name.is_empty() and (not has_channel_defaults() or set_fade_length)')

	add_body_edit("set_volume", ValueType.BOOL_BUTTON,{
			"editor_icon"	: ["AudioStreamPlayer", "EditorIcons"],
			"tooltip"		: "Overwrite Volume"
			},"!file_path.is_empty() and has_channel_defaults()")
	add_body_edit('volume', ValueType.NUMBER, {'left_text':'Volume:', 'mode':2},
		'!file_path.is_empty() and (not has_channel_defaults() or set_volume)')
	add_body_edit("set_audio_bus", ValueType.BOOL_BUTTON,{
			"editor_icon"	: ["AudioBusBypass", "EditorIcons"],
			"tooltip"		: "Overwrite Audio Bus"
			},"!file_path.is_empty() and has_channel_defaults()")
	add_body_edit('audio_bus', ValueType.DYNAMIC_OPTIONS, {
		'left_text':'Audio Bus:',
		'placeholder'		: 'Master',
		'mode'				: 2,
		'suggestions_func' 	: DialogicUtil.get_audio_bus_suggestions,
	}, '!file_path.is_empty() and (not has_channel_defaults() or set_audio_bus)')
	add_body_edit("set_loop", ValueType.BOOL_BUTTON,{
			"editor_icon"	: ["Loop", "EditorIcons"],
			"tooltip"		: "Overwrite Loop"
			},"!channel_name.is_empty() and !file_path.is_empty() and has_channel_defaults()")
	add_body_edit('loop', ValueType.BOOL, {'left_text':'Loop:'},
		'!channel_name.is_empty() and !file_path.is_empty() and (not has_channel_defaults() or set_loop)')
	add_body_line_break("!channel_name.is_empty() and !file_path.is_empty()")
	add_body_edit("set_sync_channel", ValueType.BOOL_BUTTON,{
			"editor_icon"	: ["TransitionSync", "EditorIcons"],
			"tooltip"		: "Enable Syncing"
			},"!channel_name.is_empty() and !file_path.is_empty()")

	add_body_edit('sync_channel', ValueType.DYNAMIC_OPTIONS, {
		'left_text'			:'Sync with:',
		'placeholder'		: '(No Sync)',
		'mode'				: 3,
		'suggestions_func' 	: get_sync_audio_channel_suggestions,
		'validation_func'	: DialogicUtil.validate_audio_channel_name,
		'tooltip'			: "Use an existing channel or type the name for a new channel. If channel doesn't exist, this setting will be ignored.",
	}, '!channel_name.is_empty() and !file_path.is_empty() and set_sync_channel')


## Used by the button on the visual event
func _open_audio_settings() -> void:
	var editor_manager := editor_node.find_parent('EditorsManager')
	if editor_manager:
		editor_manager.open_editor(editor_manager.editors['Settings']['node'], true, "Audio")


## Helper for the visibility conditions
func has_channel_defaults() -> bool:
	var defaults := DialogicUtil.get_audio_channel_defaults()
	return defaults.has(channel_name)


func get_audio_channel_suggestions(filter:String) -> Dictionary:
	var suggestions := {}
	suggestions["(One-Shot SFX)"] = {
		"value":"",
		"tooltip": "Used for one shot sounds effects. Plays each sound in its own AudioStreamPlayer.",
		"editor_icon": ["GuiRadioUnchecked", "EditorIcons"]
		}
	# TODO use .merged after dropping 4.2 support
	suggestions.merge(DialogicUtil.get_audio_channel_suggestions(filter))
	return suggestions

func get_sync_audio_channel_suggestions(filter:="") -> Dictionary:
	return DialogicUtil.get_audio_channel_suggestions(filter)



####################### CODE COMPLETION ########################################
################################################################################

func _get_code_completion(CodeCompletionHelper:Node, TextNode:TextEdit, line:String, word:String, symbol:String) -> void:
	var line_until: String = CodeCompletionHelper.get_line_untill_caret(line)
	if symbol == ' ':
		if line_until.count(' ') == 1:
			TextNode.add_code_completion_option(CodeEdit.KIND_MEMBER, "One-Shot SFX", ' ', event_color.lerp(TextNode.syntax_highlighter.normal_color, 0.6))
			for i in DialogicUtil.get_audio_channel_suggestions(""):
				TextNode.add_code_completion_option(CodeEdit.KIND_MEMBER, i, i, event_color.lerp(TextNode.syntax_highlighter.normal_color, 0.6), null, " ")
		elif line_until.count(" ") == 2:
			TextNode.add_code_completion_option(CodeEdit.KIND_MEMBER, '"', '"', event_color.lerp(TextNode.syntax_highlighter.normal_color, 0.6))

	if symbol == "[" or (symbol == " " and line.count("[")):
		for i in ["fade", "volume", "bus", "loop", "sync"]:
			if not i+"=" in line:
				TextNode.add_code_completion_option(CodeEdit.KIND_MEMBER, i, i+'="', event_color.lerp(TextNode.syntax_highlighter.normal_color, 0.6))

	if (symbol == '"' or symbol == "=") and line.count("["):
		CodeCompletionHelper.suggest_shortcode_values(TextNode, self, line, word)


func _get_start_code_completion(_CodeCompletionHelper:Node, TextNode:TextEdit) -> void:
	TextNode.add_code_completion_option(CodeEdit.KIND_PLAIN_TEXT, 'audio', 'audio ', event_color.lerp(TextNode.syntax_highlighter.normal_color, 0.3))


#################### SYNTAX HIGHLIGHTING #######################################
################################################################################

func _get_syntax_highlighting(Highlighter:SyntaxHighlighter, dict:Dictionary, line:String) -> Dictionary:
	var result := regex.search(line)

	dict[result.get_start()] = {"color":event_color.lerp(Highlighter.normal_color, 0.3)}
	dict[result.get_start("channel")] = {"color":event_color.lerp(Highlighter.normal_color, 0.8)}
	dict[result.get_start("file_path")] = {"color":event_color.lerp(Highlighter.string_color, 0.8)}
	if result.get_string("shortcode"):
		dict[result.get_start("shortcode")-1] = {"color":Highlighter.normal_color}
		dict = Highlighter.color_shortcode_content(dict, line, result.get_start("shortcode"), 0, event_color)

	return dict
