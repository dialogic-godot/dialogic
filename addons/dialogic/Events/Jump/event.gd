@tool
extends DialogicEvent
class_name DialogicJumpEvent

# DEFINE ALL PROPERTIES OF THE EVENT
var Timeline :DialogicTimeline = null :
	set = _set_timeline
var LabelName : String = ""
var _timeline_file: String = ""
var _timeline_loaded: bool = false

func _execute() -> void:
	if Timeline and Timeline != dialogic.current_timeline:
		#print("---------------switching timelines----------------")
		dialogic.start_timeline(Timeline, LabelName)
	elif _timeline_file != "":
		if _timeline_file.contains("res://"):
			dialogic.start_timeline(_timeline_file, LabelName)
		else: 
			dialogic.start_timeline(Dialogic.find_timeline(_timeline_file), LabelName)
	elif LabelName:
		dialogic.jump_to_label(LabelName)
	

################################################################################
## 						INITIALIZE
################################################################################

# SET ALL VALUES THAT SHOULD NEVER CHANGE HERE
func _init() -> void:
	event_name = "Jump"
	set_default_color('Color2')
	event_category = Category.TIMELINE
	event_sorting_index = 0
	expand_by_default = false

func _set_timeline(value):
	if typeof(value) == TYPE_STRING:
		_timeline_file = value
	else:
		Timeline = value

################################################################################
## 						SAVING/LOADING
################################################################################
func get_shortcode() -> String:
	return "jump"

func get_shortcode_parameters() -> Dictionary:
	return {
		#param_name : property_name
		"timeline"	: "_timeline_file",
		"label"		: "LabelName",
	}

func load_timeline() -> void:
	if Timeline == null:
		if _timeline_file != "":
			Timeline = Dialogic.preload_timeline(_timeline_file)
			_timeline_loaded = true

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
	add_header_edit("LabelName", ValueType.SinglelineText, "at", '', {'placeholder':'the beginning'})
#	add_header_edit('LabelName', ValueType.ComplexPicker, 'at', '', {
#		'suggestions_func': get_label_suggestions,
#		'editor_icon': ['Label', 'EditorIcons'],
#		'empty_text': 'the beginning'
#	})

func get_timeline_suggestions(filter:String) -> Dictionary:
	var suggestions = {}
	var resources = DialogicUtil.list_resources_of_type('.dtl')
	
	suggestions['(this timeline)'] = {'value':'', 'editor_icon':['GuiRadioUnchecked', 'EditorIcons']}
	
	for resource in Engine.get_meta('dialogic_timeline_directory').keys():
		suggestions[resource] = {'value': resource, 'tooltip':Engine.get_meta('dialogic_timeline_directory')[resource], 'editor_icon': ["TripleBar", "EditorIcons"]}
	return suggestions
#
#func get_label_suggestions(search_text:String):
#	var suggestions = {}
#	if !Timeline and !search_text.is_empty():
#		suggestions[search_text] = {'value':search_text, 'editor_icon':['GuiScrollArrowRight', 'EditorIcons']}
#
#	suggestions['the beginning'] = {'value':'', 'editor_icon':['GuiRadioUnchecked', 'EditorIcons']}
#
#	if Timeline:
#		for event in Timeline.events:
#			if event is DialogicLabelEvent:
#				suggestions[event.Name] = {'value':event.Name, 'editor_icon':['Label', 'EditorIcons']}
#	else:
#		var current = load(ProjectSettings.get_setting('dialogic/editor/current_timeline_path'))
#		if current:
#			for event in current.events:
#				if event is DialogicLabelEvent:
#					suggestions[event.Name] = {'value':event.Name, 'editor_icon':['Label', 'EditorIcons']}
#	return suggestions
