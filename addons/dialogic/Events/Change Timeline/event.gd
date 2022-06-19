tool
extends DialogicEvent


# DEFINE ALL PROPERTIES OF THE EVENT
var Timeline :DialogicTimeline = null
var Anchor : String = ""

func _execute() -> void:
	if Timeline:
		dialogic_game_handler.start_timeline(Timeline)
	else:
		finish()


################################################################################
## 						INITIALIZE
################################################################################

# SET ALL VALUES THAT SHOULD NEVER CHANGE HERE
func _init() -> void:
	event_name = "Change Timeline"
	event_color = Color("#12b76a")
	event_category = Category.TIMELINE
	event_sorting_index = 0
	


################################################################################
## 						SAVING/LOADING
################################################################################

## THIS RETURNS A READABLE REPRESENTATION, BUT HAS TO CONTAIN ALL DATA (This is how it's stored)
func get_as_string_to_store() -> String:
	var result_string = ""
	
	if Timeline is DialogicTimeline:
		result_string = 'Start Timeline "'+Timeline.resource_path+'"'
	else:
		result_string = 'Start Timeline " "'
	return result_string


## THIS HAS TO READ ALL THE DATA FROM THE SAVED STRING (see above) 
func load_from_string_to_store(string:String):
	
	var timeline_name_or_path = string.strip_edges().trim_prefix('Start Timeline "').trim_suffix('"').strip_edges()
	var timeline_resource = null
	if not timeline_name_or_path.ends_with('.dtl'):
		timeline_resource = DialogicUtil.guess_resource('.dtl', timeline_name_or_path)
	else: timeline_resource = timeline_name_or_path
	if timeline_resource:
		var tl = load(timeline_resource)
		if tl is DialogicTimeline:
			Timeline = tl
		else:
			print('[Dialogic] Error loading timeline "'+timeline_name_or_path+'"')
		

# RETURN TRUE IF THE GIVEN LINE SHOULD BE LOADED AS THIS EVENT
static func is_valid_event_string(string:String):
	
	if string.begins_with('Start Timeline "'):
		return true
	return false


################################################################################
## 						EDITOR REPRESENTATION
################################################################################

func _get_property_list() -> Array:

	clear_editor()
	add_header_edit('Timeline', ValueType.Timeline, 'Timeline:')

	return editor_list
