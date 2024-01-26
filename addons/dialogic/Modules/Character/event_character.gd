@tool
class_name DialogicCharacterEvent
extends DialogicEvent
## Event that allows to manipulate character portraits.

enum Actions {JOIN, LEAVE, UPDATE}


### Settings

## The type of action of this event (JOIN/LEAVE/UPDATE). See [Actions].
var action : int =  Actions.JOIN
## The character that will join/leave/update.
var character : DialogicCharacter = null
## For Join/Update, this will be the portrait of the character that is shown.
## Not used on Leave.
## If empty, the default portrait will be used.
var portrait: String = ""
## The index of the position this character should move to
var position: int = 1
## Name of the animation script (extending DialogicAnimation).
## On Join/Leave empty (default) will fallback to the animations set in the settings.
## On Update empty will mean no animation.
var animation_name: String = ""
## Length of the animation.
var animation_length: float = 0.5
## How often the animation is repeated. Only for Update events.
var animation_repeats: int = 1
## If true, the events waits for the animation to finish before the next event starts.
var animation_wait: bool = false
## For Update only. If bigger then 0, the portrait will tween to the
## new position (if changed) in this time (in seconds).
var position_move_time: float = 0.0
## The z_index that the portrait should have.
var z_index: int = 0
## If true, the portrait will be set to mirrored.
var mirrored: bool = false
## If set, will be passed to the portrait scene.
var extra_data: String = ""


### Helpers

## Indicators for whether something should be updated (UPDATE mode only)
var set_portrait := false
var set_position := false
var set_z_index := false
var set_mirrored := false
## Used to set the character resource from the unique name identifier and vice versa
var character_identifier: String:
	get:
		if character_identifier == '--All--':
			return '--All--'
		if character:
			var identifier := DialogicResourceUtil.get_unique_identifier(character.resource_path)
			if not identifier.is_empty():
				return identifier
		return character_identifier
	set(value):
		character_identifier = value
		character = DialogicResourceUtil.get_character_resource(value)

# Reference regex without Godot escapes: (?<type>Join|Update|Leave)\s*(")?(?<name>(?(2)[^"\n]*|[^(: \n]*))(?(2)"|)(\W*\((?<portrait>.*)\))?(\s*(?<position>\d))?(\s*\[(?<shortcode>.*)\])?
var regex := RegEx.create_from_string("(?<type>join|update|leave)\\s*(\")?(?<name>(?(2)[^\"\\n]*|[^(: \\n]*))(?(2)\"|)(\\W*\\((?<portrait>.*)\\))?(\\s*(?<position>\\d))?(\\s*\\[(?<shortcode>.*)\\])?")

################################################################################
## 						EXECUTION
################################################################################

func _execute() -> void:
	match action:
		Actions.JOIN:
			if character:
				if dialogic.has_subsystem('History') and !dialogic.Portraits.is_character_joined(character):
					dialogic.History.store_simple_history_entry(character.display_name + " joined", event_name, {'character': character.display_name, 'mode':'Join'})

				var final_animation_length: float = animation_length

				if dialogic.Inputs.auto_skip.enabled:
					var max_time: float = dialogic.Inputs.auto_skip.time_per_event
					final_animation_length = min(max_time, animation_length)

				await dialogic.Portraits.join_character(
					character, portrait, position,
					mirrored, z_index, extra_data,
					animation_name, final_animation_length, animation_wait)

		Actions.LEAVE:
			var final_animation_length: float = animation_length

			if dialogic.Inputs.auto_skip.enabled:
				var max_time: float = dialogic.Inputs.auto_skip.time_per_event
				final_animation_length = min(max_time, animation_length)

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
					dialogic.History.store_simple_history_entry(character.display_name+" left", event_name, {'character': character.display_name, 'mode':'Leave'})

				await dialogic.Portraits.leave_character(
					character,
					animation_name,
					final_animation_length,
					animation_wait
				)

		Actions.UPDATE:
			if !character or !dialogic.Portraits.is_character_joined(character):
				finish()
				return

			if set_portrait:
				dialogic.Portraits.change_character_portrait(character, portrait, false)

			if set_mirrored:
				dialogic.Portraits.change_character_mirror(character, mirrored)

			if set_z_index:
				dialogic.Portraits.change_character_z_index(character, z_index)

			if set_position:
				var final_position_move_time: float = position_move_time

				if dialogic.Inputs.auto_skip.enabled:
					var max_time: float = dialogic.Inputs.auto_skip.time_per_event
					final_position_move_time = min(max_time, position_move_time)

				dialogic.Portraits.move_character(character, position, final_position_move_time)

			if animation_name:
				var final_animation_length: float = animation_length
				var final_animation_repitions: int = animation_repeats

				if dialogic.Inputs.auto_skip.enabled:
					var time_per_event: float = dialogic.Inputs.auto_skip.time_per_event
					var time_for_repitions: float = time_per_event / animation_repeats
					final_animation_length = time_for_repitions

				var anim: DialogicAnimation = dialogic.Portraits.animate_character(
					character,
					animation_name,
					final_animation_length,
					final_animation_repitions
				)

				if animation_wait:
					dialogic.current_state = DialogicGameHandler.States.ANIMATING
					await anim.finished
					dialogic.current_state = DialogicGameHandler.States.IDLE

	finish()


################################################################################
## 						INITIALIZE
################################################################################

func _init() -> void:
	event_name = "Character"
	set_default_color('Color2')
	event_category = "Main"
	event_sorting_index = 2


func _get_icon() -> Resource:
	return load(self.get_script().get_path().get_base_dir().path_join('icon_character.png'))

################################################################################
## 						SAVING/LOADING
################################################################################

func to_text() -> String:
	var result_string := ""

	match action:
		Actions.JOIN: result_string += "join "
		Actions.LEAVE: result_string += "leave "
		Actions.UPDATE: result_string += "update "

	var default_values := DialogicUtil.get_custom_event_defaults(event_name)

	if character or character_identifier == '--All--':
		if action == Actions.LEAVE and character_identifier == '--All--':
			result_string += "--All--"
		else:
			var name := DialogicResourceUtil.get_unique_identifier(character.resource_path)
			if name.count(" ") > 0:
				name = '"' + name + '"'
			result_string += name
			if portrait.strip_edges() != default_values.get('portrait', '') and action != Actions.LEAVE and (action != Actions.UPDATE or set_portrait):
				result_string+= " ("+portrait+")"

	if action != Actions.LEAVE and (action != Actions.UPDATE or set_position):
		result_string += " "+str(position)

	var shortcode := "["
	if animation_name:
		shortcode += 'animation="'+animation_name+'"'

		if animation_length != default_values.get('animation_length', 0.5):
			shortcode += ' length="'+str(animation_length)+'"'

		if animation_wait != default_values.get('animation_wait', false):
			shortcode += ' wait="'+str(animation_wait)+'"'

		if animation_repeats != default_values.get('animation_repeats', 1) and action == Actions.UPDATE:
			shortcode += ' repeat="'+str(animation_repeats)+'"'

	if z_index != default_values.get('z_index', 0) or (action == Actions.UPDATE and set_z_index):
		shortcode += ' z_index="' + str(z_index) + '"'

	if mirrored != default_values.get('mirrored', false) or (action == Actions.UPDATE and set_mirrored):
		shortcode += ' mirrored="' + str(mirrored) + '"'

	if position_move_time != default_values.get('position_move_time', 0) and action == Actions.UPDATE and set_position:
		shortcode += ' move_time="' + str(position_move_time) + '"'

	if extra_data != "":
		shortcode += ' extra_data="' + extra_data + '"'

	shortcode += "]"

	if shortcode != "[]":
		result_string += " "+shortcode
	return result_string


func from_text(string:String) -> void:
	var character_directory := DialogicResourceUtil.get_character_directory()

	# load default character
	character = DialogicResourceUtil.get_character_resource(character_identifier)

	var result := regex.search(string)

	match result.get_string('type'):
		"join":
			action = Actions.JOIN
		"leave":
			action = Actions.LEAVE
		"update":
			action = Actions.UPDATE

	if result.get_string('name').strip_edges():
		if action == Actions.LEAVE and result.get_string('name').strip_edges() == "--All--":
			character_identifier = '--All--'
		else:
			var name := result.get_string('name').strip_edges()
			character = DialogicResourceUtil.get_character_resource(name)


	if !result.get_string('portrait').is_empty():
		portrait = result.get_string('portrait').strip_edges().trim_prefix('(').trim_suffix(')')
		set_portrait = true

	if result.get_string('position'):
		position = int(result.get_string('position'))
		set_position = true

	if result.get_string('shortcode'):
		var shortcode_params = parse_shortcode_parameters(result.get_string('shortcode'))
		animation_name = shortcode_params.get('animation', '')

		var animLength = shortcode_params.get('length', '0.5').to_float()
		if typeof(animLength) == TYPE_FLOAT:
			animation_length = animLength
		else:
			animation_length = animLength.to_float()

		animation_wait = DialogicUtil.str_to_bool(shortcode_params.get('wait', 'false'))

		#repeat is supported on Update, the other two should not be checking this
		if action == Actions.UPDATE:
			animation_repeats = int(shortcode_params.get('repeat', animation_repeats))
			position_move_time = float(shortcode_params.get('move_time', position_move_time))

		#move time is only supported on Update, but it isnt part of the animations so its separate
		if action == Actions.UPDATE:
			position_move_time = float(shortcode_params.get('move_time', position_move_time))

		z_index = int(shortcode_params.get('z_index', z_index))
		set_z_index = shortcode_params.has('z_index')

		mirrored = DialogicUtil.str_to_bool(shortcode_params.get('mirrored', str(mirrored)))
		set_mirrored = shortcode_params.has('mirrored')
		extra_data = shortcode_params.get('extra_data', "")


## this is only here to provide a list of default values
## this way the module manager can add custom default overrides to this event.
## this is also why some properties are commented out,
## because it's not recommended to overwrite them this way
func get_shortcode_parameters() -> Dictionary:
	return {
		#param_name 	: property_info
		"action" 		: {"property": "action", 					"default": 0,
							"suggestions": func(): return {'Join':
										{'value':Actions.JOIN},
										'Leave':{'value':Actions.LEAVE},
										'Update':{'value':Actions.UPDATE}}},
		"character" 	: {"property": "character_identifier", 	"default": ""},
		"portrait" 		: {"property": "portrait", 						"default": ""},
		"position" 		: {"property": "position", 						"default": 1},

#		"animation_name"	: {"property": "animation_name", 			"default": ""},
		"animation_length"	: {"property": "animation_length", 			"default": 0.5},
		"animation_wait" 	: {"property": "animation_wait", 			"default": false},
		"animation_repeats"	: {"property": "animation_repeats", 		"default": 1},

		"z_index" 		: {"property": "z_index", 						"default": 0},
		"move_time"		: {"property": "position_move_time", 			"default": 0.0},
		"mirrored"		: {"property": "mirrored", 						"default": false},
		"extra_data"	: {"property": "extra_data", 					"default": ""},
	}


func is_valid_event(string:String) -> bool:
	if string.begins_with("join") or string.begins_with("leave") or string.begins_with("update"):
		return true
	return false


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
		]
	})
	add_header_edit('character_identifier', ValueType.DYNAMIC_OPTIONS,
			{'placeholder'		: 'Character',
			'file_extension' 	: '.dch',
			'mode'				: 2,
			'suggestions_func' 	: get_character_suggestions,
			'icon' 				: load("res://addons/dialogic/Editor/Images/Resources/character.svg"),
			'autofocus'			: true})
#	add_header_button('', _on_character_edit_pressed, 'Edit character', ["ExternalLink", "EditorIcons"], 'character != null and character_identifier != "--All--"')

	add_header_edit('set_portrait', ValueType.BOOL_BUTTON,
			{'icon':load("res://addons/dialogic/Modules/Character/update_portrait.svg"),
			 'tooltip':'Change Portrait'}, "should_show_portrait_selector() and action == Actions.UPDATE")
	add_header_edit('portrait', ValueType.DYNAMIC_OPTIONS,
			{'placeholder'		: 'Default',
			'collapse_when_empty':true,
			'suggestions_func' 	: get_portrait_suggestions,
			'icon' 				: load("res://addons/dialogic/Editor/Images/Resources/portrait.svg")},
			'should_show_portrait_selector() and (action != Actions.UPDATE or set_portrait)')
	add_header_edit('set_position', ValueType.BOOL_BUTTON,
			{'icon': load("res://addons/dialogic/Modules/Character/update_position.svg"), 'tooltip':'Change Position'}, "character != null and !has_no_portraits() and action == Actions.UPDATE")
	add_header_label('at position', 'character != null and !has_no_portraits() and action == Actions.JOIN')
	add_header_label('to position', 'character != null and !has_no_portraits() and action == Actions.UPDATE and set_position')
	add_header_edit('position', ValueType.NUMBER, {'mode':1},
			'character != null and !has_no_portraits() and action != %s and (action != Actions.UPDATE or set_position)' %Actions.LEAVE)

	# Body
	add_body_edit('animation_name', ValueType.DYNAMIC_OPTIONS,
			{'left_text'		: 'Animation:',
			'suggestions_func' 	: get_animation_suggestions,
			'editor_icon' 			: ["Animation", "EditorIcons"],
			'placeholder' 			: 'Default',
			'enable_pretty_name' 	: true},
			'should_show_animation_options()')
	add_body_edit('animation_length', ValueType.NUMBER, {'left_text':'Length:'},
			'should_show_animation_options() and !animation_name.is_empty()')
	add_body_edit('animation_wait', ValueType.BOOL, {'left_text':'Await end:'},
			'should_show_animation_options() and !animation_name.is_empty()')
	add_body_edit('animation_repeats', ValueType.NUMBER, {'left_text':'Repeat:', 'mode':1},
			'should_show_animation_options() and !animation_name.is_empty() and action == %s)' %Actions.UPDATE)
	add_body_line_break()
	add_body_edit('position_move_time', ValueType.NUMBER, {'left_text':'Movement duration:'},
			'action == %s and set_position' %Actions.UPDATE)
	add_body_edit('set_z_index', ValueType.BOOL_BUTTON, {'icon':load("res://addons/dialogic/Modules/Character/update_z_index.svg"), 'tooltip':'Change Z-Index'}, "character != null and action == Actions.UPDATE")
	add_body_edit('z_index', ValueType.NUMBER, {'left_text':'Z-index:', 'mode':1},
			'action != %s and (action != Actions.UPDATE or set_z_index)' %Actions.LEAVE)
	add_body_edit('set_mirrored', ValueType.BOOL_BUTTON, {'icon':load("res://addons/dialogic/Modules/Character/update_mirror.svg"), 'tooltip':'Change Mirroring'}, "character != null and action == Actions.UPDATE")
	add_body_edit('mirrored', ValueType.BOOL, {'left_text':'Mirrored:'},
			'action != %s and (action != Actions.UPDATE or set_mirrored)' %Actions.LEAVE)


func should_show_animation_options() -> bool:
	return (character != null and !character.portraits.is_empty()) or character_identifier == '--All--'

func should_show_portrait_selector() -> bool:
	return character != null and len(character.portraits) > 1 and action != Actions.LEAVE

func has_no_portraits() -> bool:
	return character and character.portraits.is_empty()


func get_character_suggestions(search_text:String) -> Dictionary:
	var suggestions := {}
	#override the previous _character_directory with the meta, specifically for searching otherwise new nodes wont work

	var icon = load("res://addons/dialogic/Editor/Images/Resources/character.svg")

	suggestions['(No one)'] = {'value':'', 'editor_icon':["GuiRadioUnchecked", "EditorIcons"]}
	var character_directory = DialogicResourceUtil.get_character_directory()
	if action == Actions.LEAVE:
		suggestions['ALL'] = {'value':'--All--', 'tooltip':'All currently joined characters leave', 'editor_icon':["GuiEllipsis", "EditorIcons"]}
	for resource in character_directory.keys():
		suggestions[resource] = {'value': resource, 'tooltip': character_directory[resource], 'icon': icon.duplicate()}
	return suggestions


func get_portrait_suggestions(search_text:String) -> Dictionary:
	var suggestions := {}
	var icon = load("res://addons/dialogic/Editor/Images/Resources/portrait.svg")
	if action == Actions.UPDATE:
		suggestions["Don't Change"] = {'value':'', 'editor_icon':["GuiRadioUnchecked", "EditorIcons"]}
	if action == Actions.JOIN:
		suggestions["Default portrait"] = {'value':'', 'editor_icon':["GuiRadioUnchecked", "EditorIcons"]}
	if character != null:
		for portrait in character.portraits:
			suggestions[portrait] = {'value':portrait, 'icon':icon.duplicate()}
	return suggestions


func get_animation_suggestions(search_text:String) -> Dictionary:
	var suggestions := {}

	match action:
		Actions.JOIN, Actions.LEAVE:
			suggestions['Default'] = {'value':"", 'editor_icon':["GuiRadioUnchecked", "EditorIcons"]}
		Actions.UPDATE:
			suggestions['None'] = {'value':"", 'editor_icon':["GuiRadioUnchecked", "EditorIcons"]}

	for anim in DialogicUtil.get_portrait_animation_scripts(action+1):
		suggestions[DialogicUtil.pretty_name(anim)] = {'value':DialogicUtil.pretty_name(anim), 'editor_icon':["Animation", "EditorIcons"]}

	return suggestions


func _on_character_edit_pressed() -> void:
	var editor_manager := _editor_node.find_parent('EditorsManager')
	if editor_manager:
		editor_manager.edit_resource(character)


####################### CODE COMPLETION ########################################
################################################################################

func _get_code_completion(CodeCompletionHelper:Node, TextNode:TextEdit, line:String, word:String, symbol:String) -> void:
	if symbol == ' ' and line.count(' ') == 1:
		CodeCompletionHelper.suggest_characters(TextNode, CodeEdit.KIND_MEMBER)
		if line.begins_with('leave'):
			TextNode.add_code_completion_option(CodeEdit.KIND_MEMBER, 'All', '--All-- ', event_color, TextNode.get_theme_icon("GuiEllipsis", "EditorIcons"))

	if symbol == '(':
		var character:= regex.search(line).get_string('name')
		CodeCompletionHelper.suggest_portraits(TextNode, character)

	if '[' in line and (symbol == "[" or symbol == " "):
		if !'animation=' in line:
			TextNode.add_code_completion_option(CodeEdit.KIND_MEMBER, 'animation', 'animation="', TextNode.syntax_highlighter.normal_color)
		if !'length=' in line:
			TextNode.add_code_completion_option(CodeEdit.KIND_MEMBER, 'length', 'length="', TextNode.syntax_highlighter.normal_color)
		if !'wait=' in line:
			TextNode.add_code_completion_option(CodeEdit.KIND_MEMBER, 'wait', 'wait="', TextNode.syntax_highlighter.normal_color)
		if line.begins_with('update'):
			if !'repeat=' in line:
				TextNode.add_code_completion_option(CodeEdit.KIND_MEMBER, 'repeat', 'repeat="', TextNode.syntax_highlighter.normal_color)
			if !'move_time=' in line:
				TextNode.add_code_completion_option(CodeEdit.KIND_MEMBER, 'move_time', 'move_time="', TextNode.syntax_highlighter.normal_color)
		if !line.begins_with('leave'):
			if !'mirrored=' in line:
				TextNode.add_code_completion_option(CodeEdit.KIND_MEMBER, 'mirrored', 'mirrored="', TextNode.syntax_highlighter.normal_color)
			if !'z_index=' in line:
				TextNode.add_code_completion_option(CodeEdit.KIND_MEMBER, 'z_index', 'z_index="', TextNode.syntax_highlighter.normal_color)
		TextNode.add_code_completion_option(CodeEdit.KIND_MEMBER, 'extra_data', 'extra_data="', TextNode.syntax_highlighter.normal_color)

	if '[' in line:
		if CodeCompletionHelper.get_line_untill_caret(line).ends_with('animation="'):
			var animations := []
			if line.begins_with('join'):
				animations = DialogicUtil.get_portrait_animation_scripts(DialogicUtil.AnimationType.IN)
			if line.begins_with('update'):
				animations = DialogicUtil.get_portrait_animation_scripts(DialogicUtil.AnimationType.ACTION)
			if line.begins_with('leave'):
				animations = DialogicUtil.get_portrait_animation_scripts(DialogicUtil.AnimationType.OUT)
			for script in animations:
				TextNode.add_code_completion_option(CodeEdit.KIND_MEMBER, DialogicUtil.pretty_name(script), DialogicUtil.pretty_name(script)+'" ', TextNode.syntax_highlighter.normal_color)
		elif CodeCompletionHelper.get_line_untill_caret(line).ends_with('wait="') or CodeCompletionHelper.get_line_untill_caret(line).ends_with('mirrored="'):
			CodeCompletionHelper.suggest_bool(TextNode, TextNode.syntax_highlighter.normal_color)


func _get_start_code_completion(CodeCompletionHelper:Node, TextNode:TextEdit) -> void:
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
