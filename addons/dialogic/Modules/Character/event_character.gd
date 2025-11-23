@tool
class_name DialogicCharacterEvent
extends DialogicEvent
## Event that allows to manipulate character portraits.

enum Actions {JOIN, LEAVE, UPDATE}

### Settings

## The type of action of this event (JOIN/LEAVE/UPDATE). See [Actions].
var action :=  Actions.JOIN
## The character that will join/leave/update.
var character: DialogicCharacter = null
## For Join/Update, this will be the portrait of the character that is shown.
## Not used on Leave.
## If empty, the default portrait will be used.
var portrait := ""
## The index of the position this character should move to
var transform := "center"

## Name of the animation script (extending DialogicAnimation).
## On Join/Leave empty (default) will fallback to the animations set in the settings.
## On Update empty will mean no animation.
var animation_name := ""
## Length of the animation.
var animation_length: float = 0.5
## How often the animation is repeated. Only for Update events.
var animation_repeats: int = 1
## If true, the events waits for the animation to finish before the next event starts.
var animation_wait := false

## The fade animation to use. If left empty, the default cross-fade animation AND time will be used.
var fade_animation := ""
var fade_length := 0.5

## For Update only. If bigger then 0, the portrait will tween to the
## new position (if changed) in this time (in seconds).
var transform_time: float = 0.0
var transform_ease := Tween.EaseType.EASE_IN_OUT
var transform_trans := Tween.TransitionType.TRANS_SINE

var ease_options := [
		{'label': 'In', 	 'value': Tween.EASE_IN},
		{'label': 'Out', 	 'value': Tween.EASE_OUT},
		{'label': 'In_Out', 'value': Tween.EASE_IN_OUT},
		{'label': 'Out_In', 'value': Tween.EASE_OUT_IN},
		]

var trans_options := [
		{'label': 'Linear', 	'value': Tween.TRANS_LINEAR},
		{'label': 'Sine', 		'value': Tween.TRANS_SINE},
		{'label': 'Quint', 		'value': Tween.TRANS_QUINT},
		{'label': 'Quart', 		'value': Tween.TRANS_QUART},
		{'label': 'Quad', 		'value': Tween.TRANS_QUAD},
		{'label': 'Expo', 		'value': Tween.TRANS_EXPO},
		{'label': 'Elastic', 	'value': Tween.TRANS_ELASTIC},
		{'label': 'Cubic', 		'value': Tween.TRANS_CUBIC},
		{'label': 'Circ', 		'value': Tween.TRANS_CIRC},
		{'label': 'Bounce', 	'value': Tween.TRANS_BOUNCE},
		{'label': 'Back', 		'value': Tween.TRANS_BACK},
		{'label': 'Spring', 	'value': Tween.TRANS_SPRING}
		]

## The z_index that the portrait should have.
var z_index: int = 0
## If true, the portrait will be set to mirrored.
var mirrored := false
## If set, will be passed to the portrait scene.
var extra_data := ""


### Helpers

## Indicators for whether something should be updated (UPDATE mode only)
var set_portrait := false
var set_transform := false
var set_z_index := false
var set_mirrored := false
## Used to set the character resource from the unique name identifier and vice versa
var character_identifier: String:
	get:
		if character_identifier == '--All--':
			return '--All--'
		if character:
			var identifier := character.get_identifier()
			if not identifier.is_empty():
				return identifier
		return character_identifier
	set(value):
		character_identifier = value
		character = DialogicResourceUtil.get_character_resource(value)
		if (not character) or (character and not character.portraits.has(portrait)):
			portrait = ""
			ui_update_needed.emit()

var regex := RegEx.create_from_string(r'(?<type>join|update|leave)\s*(")?(?<name>(?(2)[^"\n]*|[^(: \n]*))(?(2)"|)(\W*\((?<portrait>.*)\))?(\s*(?<transform>[^\[]*))?(\s*\[(?<shortcode>.*)\])?')

################################################################################
## 						EXECUTION
################################################################################

func _execute() -> void:
	if not character and not character_identifier == "--All--":
		finish()
		return

	# Calculate animation time (can be shortened during skipping)
	var final_animation_length: float = animation_length
	var final_position_move_time: float = transform_time
	if dialogic.Inputs.auto_skip.enabled:
		var max_time: float = dialogic.Inputs.auto_skip.time_per_event
		final_animation_length = min(max_time, animation_length)
		final_position_move_time = min(max_time, transform_time)


	# JOIN -------------------------------------
	if action == Actions.JOIN:
		if dialogic.has_subsystem('History') and !dialogic.Portraits.is_character_joined(character):
			var character_name_text := dialogic.Text.get_character_name_parsed(character)
			dialogic.History.store_simple_history_entry(character_name_text + " joined", event_name, {'character': character_name_text, 'mode':'Join'})

		await dialogic.Portraits.join_character(
			character, portrait, transform,
			mirrored, z_index, extra_data,
			animation_name, final_animation_length, animation_wait)

	# LEAVE -------------------------------------
	elif action == Actions.LEAVE:
		if character_identifier == '--All--':
			if dialogic.has_subsystem('History') and len(dialogic.Portraits.get_joined_characters()):
				dialogic.History.store_simple_history_entry("Everyone left", event_name, {'character': "All", 'mode':'Leave'})

			await dialogic.Portraits.leave_all_characters(
				animation_name,
				final_animation_length,
				animation_wait
			)

		elif character:
			if dialogic.has_subsystem('History') and dialogic.Portraits.is_character_joined(character):
				var character_name_text := dialogic.Text.get_character_name_parsed(character)
				dialogic.History.store_simple_history_entry(character_name_text+" left", event_name, {'character': character_name_text, 'mode':'Leave'})

			await dialogic.Portraits.leave_character(
				character,
				animation_name,
				final_animation_length,
				animation_wait
			)

	# UPDATE -------------------------------------
	elif action == Actions.UPDATE:
		if not character or not dialogic.Portraits.is_character_joined(character):
			finish()
			return

		if set_portrait:
			await dialogic.Portraits.change_character_portrait(character, portrait, fade_animation, fade_length)

		dialogic.Portraits.change_character_extradata(character, extra_data)

		if set_mirrored:
			dialogic.Portraits.change_character_mirror(character, mirrored)

		if set_z_index:
			dialogic.Portraits.change_character_z_index(character, z_index)

		if set_transform:
			dialogic.Portraits.move_character(character, transform, final_position_move_time, transform_ease, transform_trans)

		if animation_name:
			var final_animation_repetitions: int = animation_repeats

			if dialogic.Inputs.auto_skip.enabled:
				var time_per_event: float = dialogic.Inputs.auto_skip.time_per_event
				var time_for_repetitions: float = time_per_event / animation_repeats
				final_animation_length = time_for_repetitions

			var animation := dialogic.Portraits.animate_character(
				character,
				animation_name,
				final_animation_length,
				final_animation_repetitions,
			)

			if animation_wait:
				dialogic.current_state = DialogicGameHandler.States.ANIMATING
				await animation.finished
				dialogic.current_state = DialogicGameHandler.States.IDLE


	finish()


#region INITIALIZE
###############################################################################

func _init() -> void:
	event_name = "Character"
	set_default_color('Color2')
	event_category = "Main"
	event_sorting_index = 2


func _get_icon() -> Resource:
	return load(self.get_script().get_path().get_base_dir().path_join('icon.svg'))

#endregion

#region SAVING, LOADING, DEFAULTS
################################################################################

func to_text() -> String:
	var result_string := ""

	# ACTIONS
	match action:
		Actions.JOIN: result_string += "join "
		Actions.LEAVE: result_string += "leave "
		Actions.UPDATE: result_string += "update "

	var default_values := DialogicUtil.get_custom_event_defaults(event_name)

	# CHARACTER IDENTIFIER
	if action == Actions.LEAVE and character_identifier == '--All--':
		result_string += "--All--"
	elif character:
		var name := character.get_character_name()

		if name.count(" ") > 0:
			name = '"' + name + '"'

		result_string += name

		# PORTRAIT
		if portrait.strip_edges() != default_values.get('portrait', ''):
			if action != Actions.LEAVE and (action != Actions.UPDATE or set_portrait):
				result_string += " (" + portrait + ")"

	# TRANSFORM
	if action == Actions.JOIN or (action == Actions.UPDATE and set_transform):
		result_string += " " + str(transform)

	# SETS:
	if action == Actions.JOIN or action == Actions.LEAVE:
		set_mirrored = mirrored != default_values.get("mirrored", false)
		set_z_index = z_index != default_values.get("z_index", 0)

	var shortcode := store_to_shortcode_parameters()

	if shortcode != "":
		result_string += " [" + shortcode + "]"

	return result_string


func from_text(string:String) -> void:
	# Load default character
	character = DialogicResourceUtil.get_character_resource(character_identifier)

	var result := regex.search(string)

	# ACTION
	match result.get_string('type'):
		"join": action = Actions.JOIN
		"leave": action = Actions.LEAVE
		"update": action = Actions.UPDATE

	# CHARACTER
	var given_name := result.get_string('name').strip_edges()
	var given_portrait := result.get_string('portrait').strip_edges()
	var given_transform := result.get_string('transform').strip_edges()

	if given_name:
		if action == Actions.LEAVE and given_name == "--All--":
			character_identifier = '--All--'
		else:
			character = DialogicResourceUtil.get_character_resource(given_name)

	# PORTRAIT
	if given_portrait:
		portrait = given_portrait.trim_prefix('(').trim_suffix(')')
		set_portrait = true

	# TRANSFORM
	if given_transform:
		transform = given_transform
		set_transform = true

	# SHORTCODE
	if not result.get_string('shortcode'):
		return

	load_from_shortcode_parameters(result.get_string('shortcode'))


func get_shortcode_parameters() -> Dictionary:
	return {
		#param_name 	: property_info
		"action" 		: {"property": "action", 					"default": 0, "custom_stored":true,
							"suggestions": func(): return {'Join':
										{'value':Actions.JOIN},
										'Leave':{'value':Actions.LEAVE},
										'Update':{'value':Actions.UPDATE}}},
		"character" 	: {"property": "character_identifier",	"default": "", "custom_stored":true, "ext_file":true},
		"portrait" 		: {"property": "portrait", 				"default": "", "custom_stored":true,},
		"transform" 	: {"property": "transform", 			"default": "center", "custom_stored":true,},

		"animation"		: {"property": "animation_name", 			"default": ""},
		"length"		: {"property": "animation_length", 			"default": 0.5},
		"wait" 			: {"property": "animation_wait", 			"default": false},
		"repeat"		: {"property": "animation_repeats", 		"default": 1},

		"z_index" 		: {"property": "z_index", 						"default": 0},
		"mirrored"		: {"property": "mirrored", 						"default": false},
		"fade"			: {"property": "fade_animation", 				"default":""},
		"fade_length"	: {"property": "fade_length", 					"default":0.5},
		"move_time"		: {"property": "transform_time", 				"default": 0.0},
		"move_ease" 	: {"property": "transform_ease", 	"default": Tween.EaseType.EASE_IN_OUT,
								"suggestions": func(): return list_to_suggestions(ease_options)},
		"move_trans"	: {"property": "transform_trans", 	"default": Tween.TransitionType.TRANS_SINE,
								"suggestions": func(): return list_to_suggestions(trans_options)},
		"extra_data"	: {"property": "extra_data", 					"default": ""},
	}


func is_valid_event(string:String) -> bool:
	if string.begins_with("join") or string.begins_with("leave") or string.begins_with("update"):
		return true
	return false

#endregion

################################################################################
## 						EDITOR REPRESENTATION
################################################################################

func build_event_editor() -> void:
	add_header_edit('action', ValueType.FIXED_OPTIONS, {
		'options': [
			{
				'label': 'Join',
				'value': Actions.JOIN,
				'icon': load("res://addons/dialogic/Editor/Images/Dropdown/join.svg")
			},
			{
				'label': 'Leave',
				'value': Actions.LEAVE,
				'icon': load("res://addons/dialogic/Editor/Images/Dropdown/leave.svg")
			},
			{
				'label': 'Update',
				'value': Actions.UPDATE,
				'icon': load("res://addons/dialogic/Editor/Images/Dropdown/update.svg")
			}
		],
		"tooltip": "Switch the action: Join/Leave/Update."
	})
	add_header_edit('character_identifier', ValueType.DYNAMIC_OPTIONS,
			{'placeholder'		: 'Character',
			'file_extension' 	: '.dch',
			'mode'				: 2,
			'suggestions_func' 	: get_character_suggestions,
			'icon' 				: load("res://addons/dialogic/Editor/Images/Resources/character.svg"),
			'autofocus'			: true})

	add_header_edit('set_portrait', ValueType.BOOL_BUTTON,
			{'icon':load("res://addons/dialogic/Modules/Character/update_portrait.svg"),
			 'tooltip':'Change Portrait'}, "should_show_portrait_selector() and action == Actions.UPDATE")
	add_header_edit('portrait', ValueType.DYNAMIC_OPTIONS,
			{'placeholder'		: 'Default',
			'collapse_when_empty':true,
			'suggestions_func' 	: get_portrait_suggestions,
			'icon' 				: load("res://addons/dialogic/Editor/Images/Resources/portrait.svg")},
			'should_show_portrait_selector() and (action != Actions.UPDATE or set_portrait)')
	add_header_edit('set_transform', ValueType.BOOL_BUTTON,
			{'icon': load("res://addons/dialogic/Modules/Character/update_position.svg"), 'tooltip':'Change Position'}, "character != null and !has_no_portraits() and action == Actions.UPDATE")
	add_header_label('at position', 'character != null and !has_no_portraits() and action == Actions.JOIN')
	add_header_label('to position', 'character != null and !has_no_portraits() and action == Actions.UPDATE and set_transform')
	add_header_edit('transform', ValueType.DYNAMIC_OPTIONS,
			{'placeholder'		: 'center',
			'mode'				: 0,
			'suggestions_func' 	: get_position_suggestions,
			'tooltip'		: "You can use a predefined position or a custom transform like 'pos=x0.5y1 size=x0.5y1 rot=10'.\nLearn more about this in the documentation."},
			'character != null and !has_no_portraits() and action != %s and (action != Actions.UPDATE or set_transform)' %Actions.LEAVE)

	# Body
	add_body_edit('fade_animation', ValueType.DYNAMIC_OPTIONS,
			{'left_text'		: 'Fade:',
			'suggestions_func' 	: get_fade_suggestions,
			'editor_icon' 			: ["Animation", "EditorIcons"],
			'placeholder' 			: 'Default',
			'enable_pretty_name' 	: true,
			'tooltip'				: "Choose the fading to use when changing to a different portrait."},
			'should_show_fade_options()')
	add_body_edit('fade_length', ValueType.NUMBER, {'left_text':'Length:', 'suffix':'s', "min":0},
			'should_show_fade_options() and !fade_animation.is_empty()')
	add_body_line_break("should_show_fade_options()")
	add_body_edit('animation_name', ValueType.DYNAMIC_OPTIONS,
			{'left_text'		: 'Animation:',
			'suggestions_func' 	: get_animation_suggestions,
			'editor_icon' 			: ["Animation", "EditorIcons"],
			'placeholder' 			: 'Default',
			'enable_pretty_name' 	: true,
			'tooltip'				: "Plays an animation on this character."},
			'should_show_animation_options()')
	add_body_edit('animation_length', ValueType.NUMBER, {'left_text':'Length:', 'suffix':'s', "min":0},
			'should_show_animation_options() and !animation_name.is_empty()')
	add_body_edit('animation_wait', ValueType.BOOL, {'left_text':'Await end:'},
			'should_show_animation_options() and !animation_name.is_empty()')
	add_body_edit('animation_repeats', ValueType.NUMBER, {'left_text':'Repeat:', 'mode':1, "min":1},
			'should_show_animation_options() and !animation_name.is_empty() and action == %s)' %Actions.UPDATE)
	add_body_line_break()
	add_body_edit('transform_time', ValueType.NUMBER, {'left_text':'Movement duration:', "min":0, "tooltip": "When changing the characters position, this is how fast it will happen."},
			"should_show_transform_options()")
	add_body_edit("transform_trans", ValueType.FIXED_OPTIONS, {'options':trans_options, 'left_text':"Trans:", "tooltip":"The transition type to use for moving the character to its new position."}, 'should_show_transform_options() and transform_time > 0')
	add_body_edit("transform_ease", ValueType.FIXED_OPTIONS, {'options':ease_options, 'left_text':"Ease:", "tooltip":"The easing to use for moving the character to its new position."}, 'should_show_transform_options() and transform_time > 0')

	add_body_edit('set_z_index', ValueType.BOOL_BUTTON, {'icon':load("res://addons/dialogic/Modules/Character/update_z_index.svg"), 'tooltip':'Change Z-Index'}, "character != null and action == Actions.UPDATE")
	add_body_edit('z_index', ValueType.NUMBER, {'left_text':'Z-index:', 'mode':1, "tooltip": "The Z-Index controls the visual order of characters. Higher z-index makes a character appear further in front."},
			'action != %s and (action != Actions.UPDATE or set_z_index)' %Actions.LEAVE)
	add_body_edit('set_mirrored', ValueType.BOOL_BUTTON, {'icon':load("res://addons/dialogic/Modules/Character/update_mirror.svg"), 'tooltip':'Change Mirroring'}, "character != null and action == Actions.UPDATE")
	add_body_edit('mirrored', ValueType.BOOL, {'left_text':'Mirrored:', "tooltip": "Mirrors the character. This applies on top of the mirroring of the portrait and the position container."},
			'action != %s and (action != Actions.UPDATE or set_mirrored)' %Actions.LEAVE)
	add_body_edit('extra_data', ValueType.SINGLELINE_TEXT, {'left_text':'Extra Data:', "tooltip": "Data that is given to the portrait. To be used on custom portrait scenes."}, 'action != Actions.LEAVE')


func should_show_transform_options() -> bool:
	return action == Actions.UPDATE and set_transform


func should_show_animation_options() -> bool:
	return (character and !character.portraits.is_empty()) or character_identifier == '--All--'


func should_show_fade_options() -> bool:
	return action == Actions.UPDATE and set_portrait and character and not character.portraits.is_empty()


func should_show_portrait_selector() -> bool:
	return character and len(character.portraits) > 1 and action != Actions.LEAVE


func has_no_portraits() -> bool:
	return character and character.portraits.is_empty()


func get_character_suggestions(search_text:String) -> Dictionary:
	return DialogicUtil.get_character_suggestions(search_text, character, false, action == Actions.LEAVE, editor_node)


func get_portrait_suggestions(search_text:String) -> Dictionary:
	var empty_text := "Don't Change"
	if action == Actions.JOIN:
		empty_text = "Default"
	return DialogicUtil.get_portrait_suggestions(search_text, character, true, empty_text)


func get_position_suggestions(search_text:String='') -> Dictionary:
	return DialogicUtil.get_portrait_position_suggestions(search_text)


func get_animation_suggestions(search_text:String='') -> Dictionary:
	var DPAU := DialogicPortraitAnimationUtil
	match action:
		Actions.JOIN:
			return DPAU.get_suggestions(search_text, animation_name, "Default", DPAU.AnimationType.IN)
		Actions.LEAVE:
			return DPAU.get_suggestions(search_text, animation_name, "Default", DPAU.AnimationType.OUT)
		Actions.UPDATE:
			return DPAU.get_suggestions(search_text, animation_name, "None", DPAU.AnimationType.ACTION)
	return {}


func get_fade_suggestions(search_text:String='') -> Dictionary:
	return DialogicPortraitAnimationUtil.get_suggestions(search_text, fade_animation, "Default", DialogicPortraitAnimationUtil.AnimationType.CROSSFADE)


####################### CODE COMPLETION ########################################
################################################################################

func _get_code_completion(CodeCompletionHelper:Node, TextNode:TextEdit, line:String, _word:String, symbol:String) -> void:
	var line_until_caret: String = CodeCompletionHelper.get_line_untill_caret(line)
	if symbol == ' ' and line_until_caret.count(" ") == 1:
		CodeCompletionHelper.suggest_characters(TextNode, CodeEdit.KIND_MEMBER, self)
		if line.begins_with('leave'):
			TextNode.add_code_completion_option(CodeEdit.KIND_MEMBER, 'All', '--All-- ', event_color, TextNode.get_theme_icon("GuiEllipsis", "EditorIcons"))

	if symbol == '(':
		var completion_character := regex.search(line).get_string('name')
		CodeCompletionHelper.suggest_portraits(TextNode, completion_character)

	elif not '[' in line_until_caret and symbol == ' ' and line_until_caret.split(" ", false).size() > 1:
		if not line.begins_with("leave"):
			if not line_until_caret.split(" ", false)[-1] in get_position_suggestions():
				for position in get_position_suggestions():
					TextNode.add_code_completion_option(CodeEdit.KIND_MEMBER, position, position+' ', TextNode.syntax_highlighter.normal_color)

	# Shortcode Part
	if '[' in line_until_caret:
		# Suggest Parameters
		if symbol == '[' or symbol == ' ' and line_until_caret.count('"')%2 == 0:# and (symbol == "[" or (symbol == " " and line_until_caret.rfind('="') < line_until_caret.rfind('"')-1)):
			suggest_parameter("animation", line, TextNode)

			if "animation=" in line:
				for param in ["length", "wait"]:
					suggest_parameter(param, line, TextNode)
				if line.begins_with('update'):
					suggest_parameter("repeat", line, TextNode)
			if line.begins_with("update"):
				for param in ["move_time", "move_trans", "move_ease", "fade"]:
					suggest_parameter(param, line, TextNode)
				if "fade=" in line_until_caret:
					suggest_parameter("fade_length", line, TextNode)
			if not line.begins_with('leave'):
				for param in ["mirrored", "z_index", "extra_data"]:
					suggest_parameter(param, line, TextNode)

		# Suggest Values
		else:
			var current_param: RegExMatch = CodeCompletionHelper.completion_shortcode_param_getter_regex.search(line)
			if not current_param:
				return

			match current_param.get_string("param"):
				"animation":
					var animations := {}
					if line.begins_with('join'):
						animations = DialogicPortraitAnimationUtil.get_portrait_animations_filtered(DialogicPortraitAnimationUtil.AnimationType.IN)
					elif line.begins_with('update'):
						animations = DialogicPortraitAnimationUtil.get_portrait_animations_filtered(DialogicPortraitAnimationUtil.AnimationType.ACTION)
					elif line.begins_with('leave'):
						animations = DialogicPortraitAnimationUtil.get_portrait_animations_filtered(DialogicPortraitAnimationUtil.AnimationType.OUT)

					for script: String  in animations:
						TextNode.add_code_completion_option(CodeEdit.KIND_VARIABLE, DialogicUtil.pretty_name(script), DialogicUtil.pretty_name(script), TextNode.syntax_highlighter.normal_color, null, '" ')

				"wait", "mirrored":
					CodeCompletionHelper.suggest_bool(TextNode, TextNode.syntax_highlighter.normal_color)
				"move_trans":
					CodeCompletionHelper.suggest_custom_suggestions(list_to_suggestions(trans_options), TextNode, TextNode.syntax_highlighter.normal_color)
				"move_ease":
					CodeCompletionHelper.suggest_custom_suggestions(list_to_suggestions(ease_options), TextNode, TextNode.syntax_highlighter.normal_color)


func suggest_parameter(parameter:String, line:String, TextNode:TextEdit) -> void:
	if not parameter + "=" in line:
		TextNode.add_code_completion_option(CodeEdit.KIND_MEMBER, parameter, parameter + '="', TextNode.syntax_highlighter.normal_color)


func _get_start_code_completion(_CodeCompletionHelper:Node, TextNode:TextEdit) -> void:
	TextNode.add_code_completion_option(CodeEdit.KIND_PLAIN_TEXT, 'join', 'join ', event_color, load('res://addons/dialogic/Editor/Images/Dropdown/join.svg'))
	TextNode.add_code_completion_option(CodeEdit.KIND_PLAIN_TEXT, 'leave', 'leave ', event_color, load('res://addons/dialogic/Editor/Images/Dropdown/leave.svg'))
	TextNode.add_code_completion_option(CodeEdit.KIND_PLAIN_TEXT, 'update', 'update ', event_color, load('res://addons/dialogic/Editor/Images/Dropdown/update.svg'))


#################### SYNTAX HIGHLIGHTING #######################################
################################################################################

func _get_syntax_highlighting(Highlighter:SyntaxHighlighter, dict:Dictionary, line:String) -> Dictionary:
	var word := line.get_slice(' ', 0)

	dict[line.find(word)] = {"color":event_color}
	dict[line.find(word)+len(word)] = {"color":Highlighter.normal_color}
	var result := regex.search(line)
	if result.get_string('name'):
		dict[result.get_start('name')] = {"color":event_color.lerp(Highlighter.normal_color, 0.5)}
		dict[result.get_end('name')] = {"color":Highlighter.normal_color}
	if result.get_string('portrait'):
		dict[result.get_start('portrait')] = {"color":event_color.lerp(Highlighter.normal_color, 0.6)}
		dict[result.get_end('portrait')] = {"color":Highlighter.normal_color}
	if result.get_string('shortcode'):
		dict = Highlighter.color_shortcode_content(dict, line, result.get_start('shortcode'), result.get_end('shortcode'), event_color)
	return dict


## HELPER
func list_to_suggestions(list:Array) -> Dictionary:
	return list.reduce(
		func(accum, value):
			accum[value.label] = value
			accum[value.label]["text_alt"] = [value.label.to_lower()]
			return accum,
		{})
