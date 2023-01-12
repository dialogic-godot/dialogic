@tool
class_name DialogicJumpEvent
extends DialogicEvent

## Event that allows starting another timeline. Also can jump to a label in that or the current timeline.


### Settings

## The timeline to jump to, if null then it's the current one. This setting should be a dialogic timeline resource.
var timeline :DialogicTimeline = null:
	get:
		if timeline == null:
			if !_timeline_file.is_empty():
				if _timeline_file.contains("res://"):
					return load(_timeline_file)
				else: 
					return load(Dialogic.find_timeline(_timeline_file))
		return timeline
## If not empty, the event will try to find a Label event with this set as name. Empty by default..
var label_name : String = ""
## If true when the timeline this event jumps to finishes, dialogic will continue this one from here.
var return_after: bool = false


### Helpers

## Path to the timeline. Mainly used by the editor.
var _timeline_file: String = ""
## Helper that indicates if [timeline] has been loaded from [_timeline_file].
var _timeline_loaded: bool = false


################################################################################
## 						EXECUTION
################################################################################

func _execute() -> void:
	if return_after:
		dialogic.Jump.push_to_jump_stack()
	if timeline and timeline != dialogic.current_timeline:
		dialogic.start_timeline(timeline, label_name)
	else:
		if label_name:
			dialogic.Jump.jump_to_label(label_name)
			finish()
		else:
			dialogic.start_timeline(dialogic.current_timeline)


################################################################################
## 						INITIALIZE
################################################################################

func _init() -> void:
	event_name = "Jump"
	set_default_color('Color2')
	event_category = Category.Timeline
	event_sorting_index = 0
	expand_by_default = false


func _get_icon() -> Resource:
	return load(self.get_script().get_path().get_base_dir().path_join('icon_jump.png'))


################################################################################
## 						SAVING/LOADING
################################################################################

func get_shortcode() -> String:
	return "jump"


func get_shortcode_parameters() -> Dictionary:
	return {
		#param_name 	: property_info
		"timeline"		: {"property": "_timeline_file", 	"default": null, 
							"suggestions": get_timeline_suggestions},
		"label"			: {"property": "label_name", 		"default": ""},
		"return_after"	: {"property": "return_after", 		"default": false, 
							"suggestions": func(): return {'True':{'value':'true'}, 'False':{'value':'false'}}}
	}


################################################################################
## 						EDITOR REPRESENTATION
################################################################################

func build_event_editor():
	add_header_edit('_timeline_file', ValueType.ComplexPicker, 'to', '', {
		'file_extension': '.dtl',
		'suggestions_func': get_timeline_suggestions,
		'editor_icon': ["TripleBar", "EditorIcons"],
		'empty_text': '(this timeline)'
	})
	add_header_edit("label_name", ValueType.SinglelineText, "at", '', {'placeholder':'the beginning'})
	add_body_edit("return_after", ValueType.Bool, "Return to this spot after completed?")


func get_timeline_suggestions(filter:String= "") -> Dictionary:
	var suggestions := {}
	var resources := DialogicUtil.list_resources_of_type('.dtl')
	
	suggestions['(this timeline)'] = {'value':'', 'editor_icon':['GuiRadioUnchecked', 'EditorIcons']}
	
	for resource in Engine.get_meta('dialogic_timeline_directory').keys():
		suggestions[resource] = {'value': resource, 'tooltip':Engine.get_meta('dialogic_timeline_directory')[resource], 'editor_icon': ["TripleBar", "EditorIcons"]}
	return suggestions
