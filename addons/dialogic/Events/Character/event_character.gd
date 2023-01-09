@tool
class_name DialogicCharacterEvent
extends DialogicEvent
## Event that allows to manipulate character portraits.

enum PortraitModes {VisualNovel, RPG}
enum ActionTypes {Join, Leave, Update}


### Settings

## The type of action of this event (JOIN/LEAVE/UPDATE). See [ActionTypes].
var action_type : int =  ActionTypes.Join
## The character that will join/leave/update.
var character : DialogicCharacter = null
## For Join/Update, this will be the portrait of the character that is shown.
## Not used on Leave.
## If empty, the default portrait will be used.
var portrait: String = ""
## The index of the position this character should move to
var position: int = 1
## Path to an animation script (extending DialogicAnimation). 
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

## Indicates if the z_index should be updated.
var _update_zindex: bool = false
## Used to set the character resource from the unique name identifier and vice versa
var _character_from_directory: String: 
	get:
		if _character_from_directory == '--All--':
			return '--All--'
		for item in _character_directory.keys():
			if _character_directory[item]['resource'] == character:
				return item
				break
		return ""
	set(value): 
		_character_from_directory = value
		if value in _character_directory.keys():
			character = _character_directory[value]['resource']
		else:
			character = null
## Used by [_character_from_directory]
var _character_directory: Dictionary = {}


################################################################################
## 						EXECUTION
################################################################################

func _execute() -> void:
	match action_type:
		ActionTypes.Join:
			
			if character:
				if !dialogic.Portraits.is_character_joined(character):
					var n = dialogic.Portraits.add_portrait(character, portrait, position, mirrored, z_index, extra_data)
					if n:
						if animation_name.is_empty():
							animation_name = DialogicUtil.get_project_setting('dialogic/animations/join_default', 
			get_script().resource_path.get_base_dir().path_join('DefaultAnimations/fade_in_up.gd'))
							animation_length = DialogicUtil.get_project_setting('dialogic/animations/join_default_length', 0.5)
							animation_wait = DialogicUtil.get_project_setting('dialogic/animations/join_default_wait', true)
						if animation_name:
							var anim:DialogicAnimation = dialogic.Portraits.animate_portrait(character, animation_name, animation_length, animation_repeats)
							
							if animation_wait:
								dialogic.current_state = Dialogic.states.ANIMATING
								await anim.finished
								dialogic.current_state = Dialogic.states.IDLE
				else:
					dialogic.Portraits.change_portrait(character, portrait)
					if animation_name.is_empty():
						animation_length = DialogicUtil.get_project_setting('dialogic/animations/join_default_length', 0.5)
					dialogic.Portraits.move_portrait(character, position, z_index, false, animation_length)
		ActionTypes.Leave:
			if _character_from_directory == '--All--':
				if animation_name.is_empty():
					animation_name = DialogicUtil.get_project_setting('dialogic/animations/leave_default', 
							get_script().resource_path.get_base_dir().path_join('DefaultAnimations/fade_out_down.gd'))
					animation_length = DialogicUtil.get_project_setting('dialogic/animations/leave_default_length', 0.5) 
					animation_wait = DialogicUtil.get_project_setting('dialogic/animations/leave_default_wait', true)
				
				if animation_name:
					for chara in dialogic.Portraits.get_joined_characters():
						var anim = dialogic.Portraits.animate_portrait(chara, animation_name, animation_length, animation_repeats)
						
						anim.finished.connect(dialogic.Portraits.remove_portrait.bind(chara))
						
						if animation_wait:
							dialogic.current_state = Dialogic.states.ANIMATING
							await anim.finished
							dialogic.current_state = Dialogic.states.IDLE
				
				else:
					for chara in dialogic.Portraits.get_joined_characters():
						dialogic.Portraits.remove_portrait(chara)
			elif character:
				if dialogic.Portraits.is_character_joined(character):
					if animation_name.is_empty():
						animation_name = DialogicUtil.get_project_setting('dialogic/animations/leave_default', 
								get_script().resource_path.get_base_dir().path_join('DefaultAnimations/fade_out_down.gd'))
						animation_length = DialogicUtil.get_project_setting('dialogic/animations/leave_default_length', 0.5) 
						animation_wait = DialogicUtil.get_project_setting('dialogic/animations/leave_default_wait', true)
					
					if animation_name:
						var anim = dialogic.Portraits.animate_portrait(character, animation_name, animation_length, animation_repeats)
						
						anim.finished.connect(dialogic.Portraits.remove_portrait.bind(character))
						
						if animation_wait:
							dialogic.current_state = Dialogic.states.ANIMATING
							await anim.finished
							dialogic.current_state = Dialogic.states.IDLE
					
					else:
						dialogic.Portraits.remove_portrait(character)

		ActionTypes.Update:
			if character:
				if dialogic.Portraits.is_character_joined(character):
					dialogic.Portraits.change_portrait(character, portrait, mirrored, z_index, _update_zindex, extra_data)
					if position != 0:
						dialogic.Portraits.move_portrait(character, position, z_index, _update_zindex, position_move_time)
					
					if animation_name:
						var anim = dialogic.Portraits.animate_portrait(character, animation_name, animation_length, animation_repeats)
						
						if animation_wait:
							dialogic.current_state = Dialogic.states.ANIMATING
							await anim.finished
							dialogic.current_state = Dialogic.states.IDLE
					
	finish()


################################################################################
## 						INITIALIZE
################################################################################

func _init() -> void:
	event_name = "Character"
	set_default_color('Color2')
	event_category = Category.Main
	event_sorting_index = 2
	continue_at_end = true
	expand_by_default = false


func _get_icon() -> Resource:
	return load(self.get_script().get_path().get_base_dir().path_join('icon_character.png'))

################################################################################
## 						SAVING/LOADING
################################################################################

func to_text() -> String:
	var result_string := ""
	
	match action_type:
		ActionTypes.Join: result_string += "Join "
		ActionTypes.Leave: result_string += "Leave "
		ActionTypes.Update: result_string += "Update "
	
#	print('to_string')
	
#	print('character ', character)
#	print('characterfrom ', _character_from_directory)
	
	if character or _character_from_directory == '--All--':
		if action_type == ActionTypes.Leave and _character_from_directory == '--All--':
			result_string += "--All--"
		else: 
			var name := ""
			for path in _character_directory.keys():
				if _character_directory[path]['resource'] == character:
					name = path
					break
			if name.count(" ") > 0:
				name = '"' + name + '"'
			result_string += name
			if !portrait.is_empty() and action_type != ActionTypes.Leave:
				result_string+= " ("+portrait+")"
	
	if position and action_type != ActionTypes.Leave:
		result_string += " "+str(position)
	if animation_name != "" or z_index != 0 or mirrored != false or position_move_time != 0.0 or extra_data != "":
		result_string += " ["
		if animation_name:
			result_string += 'animation="'+DialogicUtil.pretty_name(animation_name)+'"'
		
			if animation_length != 0.5:
				result_string += ' length="'+str(animation_length)+'"'
			
			if animation_wait:
				result_string += ' wait="'+str(animation_wait)+'"'
				
			if animation_repeats != 1:
				result_string += ' repeat="'+str(animation_repeats)+'"'
		if z_index != 0:
			result_string += ' z-index="' + str(z_index) + '"'
			
		if mirrored:
			result_string += ' mirrored="' + str(mirrored) + '"'
		
		if position_move_time != 0:
			result_string += ' move_time="' + str(position_move_time) + '"'
		
		if extra_data != "":
			result_string += ' extra_data="' + extra_data + '"'
			
		result_string += "]"
	return result_string


func from_text(string:String) -> void:
	if Engine.is_editor_hint() == false:
		_character_directory = Dialogic.character_directory
	else:
		_character_directory = self.get_meta("editor_character_directory")
		
	var regex := RegEx.new()
	
	# Reference regex without Godot escapes: (?<type>Join|Update|Leave)\s*(")?(?<name>(?(2)[^"\n]*|[^(: \n]*))(?(2)"|)(\W*\((?<portrait>.*)\))?(\s*(?<position>\d))?(\s*\[(?<shortcode>.*)\])?
	regex.compile("(?<type>Join|Update|Leave)\\s*(\")?(?<name>(?(2)[^\"\\n]*|[^(: \\n]*))(?(2)\"|)(\\W*\\((?<portrait>.*)\\))?(\\s*(?<position>\\d))?(\\s*\\[(?<shortcode>.*)\\])?")
	
	var result := regex.search(string)
	
	match result.get_string('type'):
		"Join":
			action_type = ActionTypes.Join
		"Leave":
			action_type = ActionTypes.Leave
		"Update":
			action_type = ActionTypes.Update
	
	if result.get_string('name').strip_edges():
		if action_type == ActionTypes.Leave and result.get_string('name').strip_edges() == "--All--":
			_character_from_directory = '--All--'
		else: 
			var name := result.get_string('name').strip_edges()
			

			if _character_directory != null:
				if _character_directory.size() > 0:
					character = null
					if _character_directory.has(name):
						character = _character_directory[name]['resource']
					else:
						name = name.replace('"', "")
						# First do a full search to see if more of the path is there then necessary:
						for character in _character_directory:
							if name in _character_directory[character]['full_path']:
								character = _character_directory[character]['resource']
								break
						
						# If it doesn't exist, we'll consider it a guest and create a temporary character
						if character == null:
							if Engine.is_editor_hint() == false:
								character = DialogicCharacter.new()
								character.display_name = name
								var entry:Dictionary = {}
								entry['resource'] = character
								entry['full_path'] = "runtime://" + name
								Dialogic.character_directory[name] = entry
	
	if result.get_string('portrait').strip_edges():
		portrait = result.get_string('portrait').strip_edges()

	if result.get_string('position'):
		position = result.get_string('position').to_int()
	elif action_type == ActionTypes.Update:
		# Override the normal default if it's an Update
		position = 0 
	
	if result.get_string('shortcode'):
		var shortcode_params = parse_shortcode_parameters(result.get_string('shortcode'))
		animation_name = shortcode_params.get('animation', '')
		if animation_name != "":
			if !animation_name.ends_with('.gd'):
				animation_name = guess_animation_file(animation_name)
			if !animation_name.ends_with('.gd'):
				printerr("[Dialogic] Couldn't identify animation '"+animation_name+"'.")
				animation_name = ""
			
			var animLength = shortcode_params.get('length', '0.5').to_float()
			if typeof(animLength) == TYPE_FLOAT:
				animation_length = animLength
			else:
				animation_length = animLength.to_float()
			
			animation_wait = DialogicUtil.str_to_bool(shortcode_params.get('wait', 'false'))
		
		#repeat is supported on Update, the other two should not be checking this
			if action_type == ActionTypes.Update:
				animation_repeats = shortcode_params.get('repeat', 1).to_int()
				position_move_time = shortcode_params.get('move_time', 0.0)
		#move time is only supported on Update, but it isnt part of the animations so its separate
		if action_type == ActionTypes.Update:
			if typeof(shortcode_params.get('move_time', 0)) == TYPE_STRING:	
				position_move_time = shortcode_params.get('move_time', 0.0).to_float()
		
		if typeof(shortcode_params.get('z-index', 0)) == TYPE_STRING:	
			z_index = 	shortcode_params.get('z-index', 0).to_int()
			_update_zindex = true 
		mirrored = DialogicUtil.str_to_bool(shortcode_params.get('mirrored', 'false'))
		extra_data = shortcode_params.get('extra_data', "")


func is_valid_event(string:String) -> bool:
	if string.begins_with("Join ") or string.begins_with("Leave ") or string.begins_with("Update "):
		return true
	return false


################################################################################
## 						EDITOR REPRESENTATION
################################################################################

func build_event_editor() -> void:
	add_header_edit('action_type', ValueType.FixedOptionSelector, '', '', {
		'selector_options': [
			{
				'label': 'Join',
				'value': ActionTypes.Join,
				'icon': load("res://addons/dialogic/Editor/Images/Dropdown/join.svg")
			},
			{
				'label': 'Leave',
				'value': ActionTypes.Leave,
				'icon': load("res://addons/dialogic/Editor/Images/Dropdown/leave.svg")
			},
			{
				'label': 'Update',
				'value': ActionTypes.Update,
				'icon': load("res://addons/dialogic/Editor/Images/Dropdown/update.svg")
			}
		]
	})
	add_header_edit('_character_from_directory', ValueType.ComplexPicker, '', '', 
			{'empty_text' 		: 'Character', 
			'file_extension' 	: '.dch', 
			'suggestions_func' 	: get_character_suggestions, 
			'icon' 				: load("res://addons/dialogic/Editor/Images/Resources/character.svg")})
	add_header_button('', _on_character_edit_pressed, 'Edit character', ["Edit", "EditorIcons"], 'character != null and _character_from_directory != "--All--"')
	
	add_header_edit('portrait', ValueType.ComplexPicker, '', '', 
			{'empty_text' 		: 'Default', 
			'suggestions_func' 	: get_portrait_suggestions, 
			'icon' 				: load("res://addons/dialogic/Editor/Images/Resources/portrait.svg")}, 
			'character != null and !has_no_portraits() and action_type != %s' %ActionTypes.Leave)
	add_header_edit('position', ValueType.Integer, ' at position', '', {}, 
			'character != null and !has_no_portraits() and action_type != %s' %ActionTypes.Leave)
	
	# Body
	add_body_edit('animation_name', ValueType.ComplexPicker, 'Animation:', '', 
			{'suggestions_func' 	: get_animation_suggestions, 
			'editor_icon' 			: ["Animation", "EditorIcons"], 
			'placeholder' 			: 'Default',
			'enable_pretty_name' 	: true}, 
			'should_show_animation_options()')
	add_body_edit('animation_length', ValueType.Float, 'Length:', '', {}, 
			'should_show_animation_options() and !animation_name.is_empty()')
	add_body_edit('animation_wait', ValueType.Bool, 'Wait for animation to finish:', '', {}, 
			'should_show_animation_options() and !animation_name.is_empty()')
	add_body_edit('animation_repeats', ValueType.Integer, 'Repeat:', '', {},
			'should_show_animation_options() and !animation_name.is_empty() and action_type == %s)' %ActionTypes.Update)
	add_body_edit('z_index', ValueType.Integer, 'portrait z-index:', "",{},
			'action_type != %s' %ActionTypes.Leave)
	add_body_edit('mirrored', ValueType.Bool, 'mirrored:', "",{},
			'action_type != %s' %ActionTypes.Leave)
	add_body_edit('position_move_time', ValueType.Float, 'Transiton time to change position:', '', {}, 
			'action_type == %s' %ActionTypes.Update)


func should_show_animation_options() -> bool:
	return (character != null and !character.portraits.is_empty()) or _character_from_directory == '--All--' 

func has_no_portraits() -> bool:
	return character and character.portraits.is_empty()


func get_character_suggestions(search_text:String) -> Dictionary:
	var suggestions := {}
	
	#override the previous _character_directory with the meta, specifically for searching otherwise new nodes wont work
	_character_directory = Engine.get_meta('dialogic_character_directory')

	var icon = load("res://addons/dialogic/Editor/Images/Resources/character.svg")

	suggestions['(No one)'] = {'value':'', 'editor_icon':["GuiRadioUnchecked", "EditorIcons"]}
	if action_type == ActionTypes.Leave:
		suggestions['ALL'] = {'value':'--All--', 'tooltip':'All currently joined characters leave', 'editor_icon':["GuiEllipsis", "EditorIcons"]}
	for resource in _character_directory.keys():
		suggestions[resource] = {'value': resource, 'tooltip': _character_directory[resource]['full_path'], 'icon': icon.duplicate()}
	return suggestions
	

func get_portrait_suggestions(search_text:String) -> Dictionary:
	var suggestions := {}
	var icon = load("res://addons/dialogic/Editor/Images/Resources/portrait.svg")
	if action_type == ActionTypes.Update:
		suggestions["Don't Change"] = {'value':'', 'editor_icon':["GuiRadioUnchecked", "EditorIcons"]}
	if action_type == ActionTypes.Join:
		suggestions["Default portrait"] = {'value':'', 'editor_icon':["GuiRadioUnchecked", "EditorIcons"]}
	if character != null:
		for portrait in character.portraits:
			suggestions[portrait] = {'value':portrait, 'icon':icon.duplicate()}
	return suggestions


func get_animation_suggestions(search_text:String) -> Dictionary:
	var suggestions := {}
	
	match action_type:
		ActionTypes.Join, ActionTypes.Leave:
			suggestions['Default'] = {'value':"", 'editor_icon':["GuiRadioUnchecked", "EditorIcons"]}
		ActionTypes.Update:
			suggestions['None'] = {'value':"", 'editor_icon':["GuiRadioUnchecked", "EditorIcons"]}
	
	for anim in list_animations():
		match action_type:
			ActionTypes.Join:
				if '_in' in anim.get_file():
					suggestions[DialogicUtil.pretty_name(anim)] = {'value':anim, 'editor_icon':["Animation", "EditorIcons"]}
			ActionTypes.Leave:
				if '_out' in anim.get_file():
					suggestions[DialogicUtil.pretty_name(anim)] = {'value':anim, 'editor_icon':["Animation", "EditorIcons"]}
			ActionTypes.Update:
				if not ('_in' in anim.get_file() or '_out' in anim.get_file()):
					suggestions[DialogicUtil.pretty_name(anim)] = {'value':anim, 'editor_icon':["Animation", "EditorIcons"]}
					continue
	return suggestions


func list_animations() -> Array:
	var list := DialogicUtil.listdir(get_script().resource_path.get_base_dir().path_join('DefaultAnimations'), true, false, true)
	list.append_array(DialogicUtil.listdir(DialogicUtil.get_project_setting('dialogic/animations/custom_folder', 'res://addons/dialogic_additions/Animations'), true, false, true))
	return list


func guess_animation_file(animation_name: String) -> String:
	for file in list_animations():
		if DialogicUtil.pretty_name(animation_name) == DialogicUtil.pretty_name(file):
			return file
	return animation_name

func _on_character_edit_pressed() -> void:
	var editor_manager := _editor_node.find_parent('EditorsManager')
	if editor_manager:
		editor_manager.edit_resource(character)
