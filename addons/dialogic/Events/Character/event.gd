tool
extends DialogicEvent
class_name DialogicCharacterEvent

enum ActionTypes {Join, Leave, Update}

# DEFINE ALL PROPERTIES OF THE EVENT
var ActionType = ActionTypes.Join
var Character : DialogicCharacter
var Portrait = ""
var Position = 3
var AnimationName = ""
var AnimationLength = 0.5
var AnimationRepeats = 1
var AnimationWait = false

func _execute() -> void:
	match ActionType:
		ActionTypes.Join:
			
			if Character and Portrait:
				var n = dialogic.Portraits.add_portrait(Character, Portrait, Position)
				
				if AnimationName.empty():
					AnimationName = DialogicUtil.get_project_setting('dialogic/animations_join_default', 
	get_script().resource_path.get_base_dir().plus_file('DefaultAnimations/fade_in_up.gd'))
					AnimationLength = DialogicUtil.get_project_setting('dialogic/animations_join_default_length', 0.5)
					print('using default ', AnimationName, ' at length ', AnimationLength)
					AnimationWait = DialogicUtil.get_project_setting('dialogic/animations_join_default_wait', true)
				if AnimationName:
					var anim = dialogic.Portraits.animate_portrait(Character, AnimationName, AnimationLength, AnimationRepeats)
					
					if AnimationWait:
						yield(anim, 'finished')
				
		ActionTypes.Leave:
			if Character:
				if dialogic.Portraits.is_character_joined(Character):
					if AnimationName.empty():
						AnimationName = DialogicUtil.get_project_setting('dialogic/animations_leaven_default', 
	get_script().resource_path.get_base_dir().plus_file('DefaultAnimations/fade_out_down.gd'))
						AnimationLength = DialogicUtil.get_project_setting('dialogic/animations_leave_default_length', 0.5) 
						AnimationWait = DialogicUtil.get_project_setting('dialogic/animations_leave_default_wait', true)
					if AnimationName:
						var anim = dialogic.Portraits.animate_portrait(Character, AnimationName, AnimationLength, AnimationRepeats)
						
						anim.connect('finished', dialogic.Portraits, 'remove_portrait', [Character])
						
						if AnimationWait:
							yield(anim, 'finished')
					
					else:
						dialogic.Portraits.remove_portrait(Character)

		ActionTypes.Update:
			if Character:
				if dialogic.Portraits.is_character_joined(Character):
					if Portrait:
						dialogic.Portraits.change_portrait(Character, Portrait)
					if Position != -1:
						dialogic.Portraits.move_portrait(Character, Position)
					
					if AnimationName:
						var anim = dialogic.Portraits.animate_portrait(Character, AnimationName, AnimationLength, AnimationRepeats)
						
						if AnimationWait:
							yield(anim, 'finished')
					
	finish()


func get_required_subsystems() -> Array:
	return [
				['Portraits', get_script().resource_path.get_base_dir().plus_file('Subsystem_Portraits.gd'),  get_script().resource_path.get_base_dir().plus_file('AnimationsSettings.tscn'), ],
			]

################################################################################
## 						INITIALIZE
################################################################################

# SET ALL VALUES THAT SHOULD NEVER CHANGE HERE
func _init() -> void:
	event_name = "Character"
	event_color = Color("#12b76a")
	event_category = Category.MAIN
	event_sorting_index = 2
	continue_at_end = true


################################################################################
## 						SAVING/LOADING
################################################################################

## THIS RETURNS A READABLE REPRESENTATION, BUT HAS TO CONTAIN ALL DATA (This is how it's stored)
func get_as_string_to_store() -> String:
	var result_string = ""
	
	match ActionType:
		ActionTypes.Join: result_string += "Join "
		ActionTypes.Leave: result_string += "Leave "
		ActionTypes.Update: result_string += "Update "
	
	if Character:
		result_string += Character.name
		if Portrait:
			result_string+= " ("+Portrait+")"
	
	if Position:
		result_string += " "+str(Position)
	
	if AnimationName:
		result_string += ' [animation="'+DialogicUtil.pretty_name(AnimationName)+'"'
	
		if AnimationLength != 0.5:
			result_string += ' length="'+str(AnimationLength)+'"'
		
		if AnimationWait:
			result_string += ' wait="'+str(AnimationWait)+'"'
			
		if AnimationRepeats != 1:
			result_string += ' repeat="'+str(AnimationRepeats)+'"'
			
		result_string += "]"
	
	return result_string


## THIS HAS TO READ ALL THE DATA FROM THE SAVED STRING (see above) 
func load_from_string_to_store(string:String):
	var regex = RegEx.new()
	regex.compile("(?<type>Join|Update|Leave) (?<character>[^()\\d\\n]*)( *\\((?<portrait>\\S*)\\))? ?((?<position>\\d*))?\\s*(\\[(?<shortcode>.*)\\])?")
	
	var result = regex.search(string)
	
	match result.get_string('type'):
		"Join":
			ActionType = ActionTypes.Join
		"Leave":
			ActionType = ActionTypes.Leave
		"Update":
			ActionType = ActionTypes.Update
	
	if result.get_string('character').strip_edges():
		var char_guess = DialogicUtil.guess_resource('.dch', result.get_string('character').strip_edges())
		if char_guess:
			Character = load(char_guess)
	
	if result.get_string('portrait').strip_edges():
		Portrait = result.get_string('portrait').strip_edges()

	if result.get_string('position'):
		Position = int(result.get_string('position'))
	
	if result.get_string('shortcode'):
		var shortcode_params = parse_shortcode_parameters(result.get_string('shortcode'))
		AnimationName = shortcode_params.get('animation', '')
		if !AnimationName.ends_with('.gd'):
			AnimationName = guess_animation_file(AnimationName)
		if !AnimationName.ends_with('.gd'):
			printerr("[Dialogic] Couldn't identify animation '"+AnimationName+"'.")
			AnimationName = ""
		AnimationLength = float(shortcode_params.get('length', 0.5))
		AnimationWait = DialogicUtil.str_to_bool(shortcode_params.get('wait', 'False'))
		AnimationRepeats = int(shortcode_params.get('repeat', 1))

# RETURN TRUE IF THE GIVEN LINE SHOULD BE LOADED AS THIS EVENT
func is_valid_event_string(string:String):
	
	if string.begins_with("Join ") or string.begins_with("Leave ") or string.begins_with("Update "):
		return true
	return false


################################################################################
## 						EDITOR REPRESENTATION
################################################################################

func build_event_editor():
	add_header_edit('ActionType', ValueType.FixedOptionSelector, '', '',
		 {'selector_options':{"Join":ActionTypes.Join, "Leave":ActionTypes.Leave, "Update":ActionTypes.Update}})
	add_header_edit('Character', ValueType.Resource, '', '', {'file_extension':'.dch'})
	
	add_header_edit('Portrait', ValueType.Resource, 'Portrait:', '', {'suggestions_func':[self, 'get_portrait_suggestions']}, 'Character != null and ActionType != %s' %ActionTypes.Leave)
	add_header_edit('Position', ValueType.Integer, 'Position:', '', {}, 'Character != null and ActionType != %s' %ActionTypes.Leave)
	
	add_body_edit('AnimationName', ValueType.Resource, 'Animation:', '', {'suggestions_func':[self, 'get_animation_suggestions'], 'empty_text':'Default'}, 'Character != null')
	add_body_edit('AnimationLength', ValueType.Float, 'Length:', '', {}, 'Character != null and AnimationName != "" and AnimationName != null and not "instant" in AnimationName')
	add_body_edit('AnimationWait', ValueType.Bool, 'Wait:', '', {}, 'Character != null and AnimationName != "" and AnimationName != null and not "instant" in AnimationName')
	add_body_edit('AnimationRepeats', ValueType.Integer, 'Repeat:', '', {}, 'Character != null and AnimationName != "" and AnimationName != null and not "instant" in AnimationName and ActionType == %s' %ActionTypes.Update)

func get_portrait_suggestions(search_text):
	var suggestions = {}
	if Character != null:
		for portrait in Character.portraits:
			if search_text.to_lower() in portrait.to_lower():
				suggestions[portrait] = portrait
	return suggestions

func get_animation_suggestions(search_text):
	var suggestions = {}
	
	match ActionType:
		ActionTypes.Join, ActionTypes.Leave:
			suggestions['Default'] = ""
		ActionTypes.Update:
			suggestions['None'] = ""

	for anim in list_animations():
		if search_text.to_lower() in anim.get_file().to_lower():
			match ActionType:
				ActionTypes.Join:
					if '_in' in anim.get_file():
						suggestions[DialogicUtil.pretty_name(anim)] = anim
				ActionTypes.Leave:
					if '_out' in anim.get_file():
						suggestions[DialogicUtil.pretty_name(anim)] = anim
				ActionTypes.Update:
					if not ('_in' in anim.get_file() or '_out' in anim.get_file()):
						suggestions[DialogicUtil.pretty_name(anim)] = anim
						continue
	return suggestions


func list_animations() -> Array:
	var list = DialogicUtil.listdir(get_script().resource_path.get_base_dir().plus_file('DefaultAnimations'), true, false, true)
	list.append_array(DialogicUtil.listdir(DialogicUtil.get_project_setting('dialogic/animations_custom_folder', 'res://addons/dialogic_additions/Animations'), true, false, true))
	return list


func guess_animation_file(animation_name):
	for file in list_animations():
		if DialogicUtil.pretty_name(animation_name) == DialogicUtil.pretty_name(file):
			return file
	return animation_name
