@tool
extends DialogicEvent
class_name DialogicCharacterEvent

enum PortraitModes {VisualNovel, RPG}
enum ActionTypes {Join, Leave, Update}

# DEFINE ALL PROPERTIES OF THE EVENT
var ActionType = ActionTypes.Join
var Character : DialogicCharacter
var Portrait:String = ""
var Position:int = 3
var AnimationName:String = ""
var AnimationLength: float = 0.5
var AnimationRepeats: int = 1
var AnimationWait: bool = false
var PositionMoveTime: float = 0.0
var Z_Index: int = 0
var Mirrored: bool = false
var _leave_all:bool = false
var _update_zindex: bool = false
var ExtraData: String = ""

var _character_from_directory: String: 
	get:
		for item in _character_directory.keys():
			if _character_directory[item]['resource'] == Character:
				return item
				break
		return ""
	set(value): 
		_character_from_directory = value
		if value in _character_directory.keys():
			Character = _character_directory[value]['resource']

var _character_directory: Dictionary = {}

func _execute() -> void:
	match ActionType:
		ActionTypes.Join:
			
			if Character:
				if !dialogic.Portraits.is_character_joined(Character):
					var n = dialogic.Portraits.add_portrait(Character, Portrait, Position, Mirrored, Z_Index, ExtraData)
					if n:
						if AnimationName.is_empty():
							AnimationName = DialogicUtil.get_project_setting('dialogic/animations/join_default', 
			get_script().resource_path.get_base_dir().path_join('DefaultAnimations/fade_in_up.gd'))
							AnimationLength = DialogicUtil.get_project_setting('dialogic/animations/join_default_length', 0.5)
							AnimationWait = DialogicUtil.get_project_setting('dialogic/animations/join_default_wait', true)
						if AnimationName:
							var anim:DialogicAnimation = dialogic.Portraits.animate_portrait(Character, AnimationName, AnimationLength, AnimationRepeats)
							
							if AnimationWait:
								dialogic.current_state = Dialogic.states.ANIMATING
								await anim.finished
								dialogic.current_state = Dialogic.states.IDLE
				else:
					dialogic.Portraits.change_portrait(Character, Portrait)
					if AnimationName.is_empty():
						AnimationLength = DialogicUtil.get_project_setting('dialogic/animations/join_default_length', 0.5)
					dialogic.Portraits.move_portrait(Character, Position, Z_Index, false, AnimationLength)
		ActionTypes.Leave:
			if _leave_all:
				if AnimationName.is_empty():
					AnimationName = DialogicUtil.get_project_setting('dialogic/animations/leave_default', 
get_script().resource_path.get_base_dir().path_join('DefaultAnimations/fade_out_down.gd'))
					AnimationLength = DialogicUtil.get_project_setting('dialogic/animations/leave_default_length', 0.5) 
					AnimationWait = DialogicUtil.get_project_setting('dialogic/animations/leave_default_wait', true)
				
				if AnimationName:
					for chara in dialogic.Portraits.get_joined_characters():
						var anim = dialogic.Portraits.animate_portrait(chara, AnimationName, AnimationLength, AnimationRepeats)
						
						anim.finished.connect(dialogic.Portraits.remove_portrait.bind(chara))
						
						if AnimationWait:
							dialogic.current_state = Dialogic.states.ANIMATING
							await anim.finished
							dialogic.current_state = Dialogic.states.IDLE
				
				else:
					for chara in dialogic.Portraits.get_joined_characters():
						dialogic.Portraits.remove_portrait(chara)
			elif Character:
				if dialogic.Portraits.is_character_joined(Character):
					if AnimationName.is_empty():
						AnimationName = DialogicUtil.get_project_setting('dialogic/animations/leave_default', 
	get_script().resource_path.get_base_dir().path_join('DefaultAnimations/fade_out_down.gd'))
						AnimationLength = DialogicUtil.get_project_setting('dialogic/animations/leave_default_length', 0.5) 
						AnimationWait = DialogicUtil.get_project_setting('dialogic/animations/leave_default_wait', true)
					
					if AnimationName:
						var anim = dialogic.Portraits.animate_portrait(Character, AnimationName, AnimationLength, AnimationRepeats)
						
						anim.finished.connect(dialogic.Portraits.remove_portrait.bind(Character))
						
						if AnimationWait:
							dialogic.current_state = Dialogic.states.ANIMATING
							await anim.finished
							dialogic.current_state = Dialogic.states.IDLE
					
					else:
						dialogic.Portraits.remove_portrait(Character)

		ActionTypes.Update:
			if Character:
				if dialogic.Portraits.is_character_joined(Character):
					dialogic.Portraits.change_portrait(Character, Portrait, Mirrored, Z_Index, _update_zindex, ExtraData)
					if Position != 0:
						dialogic.Portraits.move_portrait(Character, Position, Z_Index, _update_zindex, PositionMoveTime)
					
					if AnimationName:
						var anim = dialogic.Portraits.animate_portrait(Character, AnimationName, AnimationLength, AnimationRepeats)
						
						if AnimationWait:
							dialogic.current_state = Dialogic.states.ANIMATING
							await anim.finished
							dialogic.current_state = Dialogic.states.IDLE
					
	finish()


func get_required_subsystems() -> Array:
	return [
				{'name':'Portraits',
				'subsystem': get_script().resource_path.get_base_dir().path_join('Subsystem_Portraits.gd'),
				'settings': get_script().resource_path.get_base_dir().path_join('PortraitSettings.tscn'),
				},
			]

################################################################################
## 						INITIALIZE
################################################################################

# SET ALL VALUES THAT SHOULD NEVER CHANGE HERE
func _init() -> void:
	event_name = "Character"
	set_default_color('Color2')
	event_category = Category.MAIN
	event_sorting_index = 2
	continue_at_end = true
	expand_by_default = false


################################################################################
## 						SAVING/LOADING
################################################################################

## THIS RETURNS A READABLE REPRESENTATION, BUT HAS TO CONTAIN ALL DATA (This is how it's stored)
func to_text() -> String:
	var result_string = ""
	
	match ActionType:
		ActionTypes.Join: result_string += "Join "
		ActionTypes.Leave: result_string += "Leave "
		ActionTypes.Update: result_string += "Update "
	
	if Character:
		if ActionType == ActionTypes.Leave and _leave_all:
			result_string += "--All--"
		else: 
			var name = ""
			for path in _character_directory.keys():
				if _character_directory[path]['resource'] == Character:
					name = path
					break
			if name.count(" ") > 0:
				name = '"' + name + '"'
			result_string += name
			if Portrait and ActionType != ActionTypes.Leave:
				result_string+= " ("+Portrait+")"
	
	if Position and ActionType != ActionTypes.Leave:
		result_string += " "+str(Position)
	if AnimationName != "" || Z_Index != 0 || Mirrored != false || PositionMoveTime != 0.0 || ExtraData != "":
		result_string += " ["
		if AnimationName:
			result_string += 'animation="'+DialogicUtil.pretty_name(AnimationName)+'"'
		
			if AnimationLength != 0.5:
				result_string += ' length="'+str(AnimationLength)+'"'
			
			if AnimationWait:
				result_string += ' wait="'+str(AnimationWait)+'"'
				
			if AnimationRepeats != 1:
				result_string += ' repeat="'+str(AnimationRepeats)+'"'
		if Z_Index != 0:
			result_string += ' z-index="' + str(Z_Index) + '"'
			
		if Mirrored:
			result_string += ' mirrored="' + str(Mirrored) + '"'
		
		if PositionMoveTime != 0:
			result_string += ' move_time="' + str(PositionMoveTime) + '"'
		
		if ExtraData != "":
			result_string += ' extra_data="' + ExtraData + '"'
			
		result_string += "]"
	return result_string


## THIS HAS TO READ ALL THE DATA FROM THE SAVED STRING (see above) 
func from_text(string:String) -> void:
	if Engine.is_editor_hint() == false:
		_character_directory = Dialogic.character_directory
	else:
		_character_directory = self.get_meta("editor_character_directory")
		
	var regex = RegEx.new()
	
	# Reference regex without Godot escapes: (?<type>Join|Update|Leave)\s*(")?(?<name>(?(2)[^"\n]*|[^(: \n]*))(?(2)"|)(\W*\((?<portrait>.*)\))?(\s*(?<position>\d))?(\s*\[(?<shortcode>.*)\])?
	regex.compile("(?<type>Join|Update|Leave)\\s*(\")?(?<name>(?(2)[^\"\\n]*|[^(: \\n]*))(?(2)\"|)(\\W*\\((?<portrait>.*)\\))?(\\s*(?<position>\\d))?(\\s*\\[(?<shortcode>.*)\\])?")
	
	var result = regex.search(string)
	
	match result.get_string('type'):
		"Join":
			ActionType = ActionTypes.Join
		"Leave":
			ActionType = ActionTypes.Leave
		"Update":
			ActionType = ActionTypes.Update
	
	if result.get_string('name').strip_edges():
		if ActionType == ActionTypes.Leave and result.get_string('name').strip_edges() == "--All--":
			_leave_all = true
		else: 
			var name = result.get_string('name').strip_edges()
			

			if _character_directory != null:
				if _character_directory.size() > 0:
					Character = null
					if _character_directory.has(name):
						Character = _character_directory[name]['resource']
					else:
						name = name.replace('"', "")
						# First do a full search to see if more of the path is there then necessary:
						for character in _character_directory:
							if name in _character_directory[character]['full_path']:
								Character = _character_directory[character]['resource']
								break								
						
						# If it doesn't exist, we'll consider it a guest and create a temporary character
						if Character == null:
							if Engine.is_editor_hint() == false:
								Character = DialogicCharacter.new()
								Character.display_name = name
								var entry:Dictionary = {}
								entry['resource'] = Character
								entry['full_path'] = "runtime://" + name
								Dialogic.character_directory[name] = entry

	
	if result.get_string('portrait').strip_edges():
		Portrait = result.get_string('portrait').strip_edges()

	if result.get_string('position'):
		Position = result.get_string('position').to_int()
	elif ActionType == ActionTypes.Update:
		# Override the normal default if it's an Update
		Position = 0 
	
	if result.get_string('shortcode'):
		var shortcode_params = parse_shortcode_parameters(result.get_string('shortcode'))
		AnimationName = shortcode_params.get('animation', '')
		if AnimationName != "":
			if !AnimationName.ends_with('.gd'):
				AnimationName = guess_animation_file(AnimationName)
			if !AnimationName.ends_with('.gd'):
				printerr("[Dialogic] Couldn't identify animation '"+AnimationName+"'.")
				AnimationName = ""
			
			var animLength = shortcode_params.get('length', '0.5').to_float()
			if typeof(animLength) == TYPE_FLOAT:
				AnimationLength = animLength
			else:
				AnimationLength = animLength.to_float()
			
		#if typeof(AnimationLength) == TYPE_STRING:
		#	AnimationLength = AnimationLength.to_float()
			AnimationWait = DialogicUtil.str_to_bool(shortcode_params.get('wait', 'false'))
		
		#repeat is supported on Update, the other two should not be checking this
			if ActionType == ActionTypes.Update:
				AnimationRepeats = shortcode_params.get('repeat', 1).to_int()
				PositionMoveTime = shortcode_params.get('move_time', 0.0)
		#move time is only supported on Update, but it isnt part of the animations so its separate
		if ActionType == ActionTypes.Update:
			if typeof(shortcode_params.get('move_time', 0)) == TYPE_STRING:	
				PositionMoveTime = shortcode_params.get('move_time', 0.0).to_float()
		
		if typeof(shortcode_params.get('z-index', 0)) == TYPE_STRING:	
			Z_Index = 	shortcode_params.get('z-index', 0).to_int()
			_update_zindex = true 
		Mirrored = DialogicUtil.str_to_bool(shortcode_params.get('mirrored', 'false'))
		ExtraData = shortcode_params.get('extra_data', "")
		
# RETURN TRUE IF THE GIVEN LINE SHOULD BE LOADED AS THIS EVENT
func is_valid_event(string:String) -> bool:
	if string.begins_with("Join ") or string.begins_with("Leave ") or string.begins_with("Update "):
		return true
	return false


################################################################################
## 						EDITOR REPRESENTATION
################################################################################

func build_event_editor():
	add_header_edit('ActionType', ValueType.FixedOptionSelector, '', '', {
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
	add_header_edit('_character_from_directory', ValueType.ComplexPicker, '', '', {'empty_text':'Character', 'file_extension':'.dch', 'suggestions_func':get_character_suggestions, 'icon':load("res://addons/dialogic/Editor/Images/Resources/character.svg")})
	
	add_header_edit('Portrait', ValueType.ComplexPicker, '', '', {'empty_text':'Default', 'suggestions_func':get_portrait_suggestions, 'icon':load("res://addons/dialogic/Editor/Images/Resources/Portrait.svg")}, 'Character != null and !has_no_portraits() and ActionType != %s' %ActionTypes.Leave)
	
	# I think it is better not to show the picker. Leaving the commented out version to re-add or replace if needed.
	# add_header_label('(Character has no portraits)', 'has_no_portraits()')
	
	add_header_edit('Position', ValueType.Integer, ' at position', '', {}, 'Character != null and !has_no_portraits() and ActionType != %s' %ActionTypes.Leave)
	
	add_body_edit('AnimationName', ValueType.ComplexPicker, 'Animation:', '', {'suggestions_func':get_animation_suggestions, 'editor_icon':["Animation", "EditorIcons"], 'placeholder':'Default', 'enable_pretty_name':true}, 'Character != null')
	add_body_edit('AnimationLength', ValueType.Float, 'Length:', '', {}, 'Character and !AnimationName.is_empty()')
	add_body_edit('AnimationWait', ValueType.Bool, 'Wait for animation to finish:', '', {}, 'Character and !AnimationName.is_empty()')
	add_body_edit('AnimationRepeats', ValueType.Integer, 'Repeat:', '', {},'Character and !AnimationName.is_empty() and ActionType == %s)' %ActionTypes.Update)
	add_body_edit('Z_Index', ValueType.Integer, 'Portrait z-index:', "",{},'ActionType != %s' %ActionTypes.Leave)
	add_body_edit('Mirrored', ValueType.Bool, 'Mirrored:', "",{},'ActionType != %s' %ActionTypes.Leave)
	add_body_edit('PositionMoveTime', ValueType.Float, 'Transiton time to change position:', '', {}, 'ActionType == %s' %ActionTypes.Update)
	add_body_edit('_leave_all', ValueType.Bool, 'Leave All:', "",{},'ActionType == %s' %ActionTypes.Leave)

func has_no_portraits() -> bool:
	return Character and Character.portraits.is_empty()

func get_character_suggestions(search_text:String):
	var suggestions = {}
	
	#override the previous _character_directory with the meta, specifically for searching otherwise new nodes wont work
	_character_directory = Engine.get_meta('dialogic_character_directory')

	var icon = load("res://addons/dialogic/Editor/Images/Resources/character.svg")

	suggestions['(No one)'] = {'value':'', 'editor_icon':["GuiRadioUnchecked", "EditorIcons"]}
	
	for resource in _character_directory.keys():
		suggestions[resource] = {'value': resource, 'tooltip': _character_directory[resource]['full_path'], 'icon': icon.duplicate()}
	return suggestions
	

func get_portrait_suggestions(search_text):
	var suggestions = {}
	var icon = load("res://addons/dialogic/Editor/Images/Resources/Portrait.svg")
	if ActionType == ActionTypes.Update:
		suggestions["Don't Change"] = {'value':'', 'editor_icon':["GuiRadioUnchecked", "EditorIcons"]}
	if ActionType == ActionTypes.Join:
		suggestions["Default Portrait"] = {'value':'', 'editor_icon':["GuiRadioUnchecked", "EditorIcons"]}
	if Character != null:
		for portrait in Character.portraits:
			suggestions[portrait] = {'value':portrait, 'icon':icon.duplicate()}
	return suggestions

func get_animation_suggestions(search_text):
	var suggestions = {}
	
	match ActionType:
		ActionTypes.Join, ActionTypes.Leave:
			suggestions['Default'] = {'value':"", 'editor_icon':["GuiRadioUnchecked", "EditorIcons"]}
		ActionTypes.Update:
			suggestions['None'] = {'value':"", 'editor_icon':["GuiRadioUnchecked", "EditorIcons"]}
	
	for anim in list_animations():
		match ActionType:
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
	var list = DialogicUtil.listdir(get_script().resource_path.get_base_dir().path_join('DefaultAnimations'), true, false, true)
	list.append_array(DialogicUtil.listdir(DialogicUtil.get_project_setting('dialogic/animations/custom_folder', 'res://addons/dialogic_additions/Animations'), true, false, true))
	return list


func guess_animation_file(animation_name):
	for file in list_animations():
		if DialogicUtil.pretty_name(animation_name) == DialogicUtil.pretty_name(file):
			return file
	return animation_name
