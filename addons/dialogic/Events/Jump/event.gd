@tool
extends DialogicEvent
class_name DialogicJumpEvent

# DEFINE ALL PROPERTIES OF THE EVENT
var Timeline :DialogicTimeline = null
var Label : String = ""

func _execute() -> void:
	if Timeline and Timeline != dialogic.current_timeline:
		#print("---------------switching timelines----------------")
		dialogic.start_timeline(Timeline, Label)
	elif Label:
		dialogic.jump_to_label(Label)
	finish()


################################################################################
## 						INITIALIZE
################################################################################

# SET ALL VALUES THAT SHOULD NEVER CHANGE HERE
func _init() -> void:
	event_name = "Jump"
	set_default_color('Color2')
	event_category = Category.TIMELINE
	event_sorting_index = 0
	


################################################################################
## 						SAVING/LOADING
################################################################################
func get_shortcode() -> String:
	return "jump"

func get_shortcode_parameters() -> Dictionary:
	return {
		#param_name : property_name
		"timeline"		: "Timeline",
		"label"		: "Label",
	}


################################################################################
## 						EDITOR REPRESENTATION
################################################################################

func build_event_editor():
	add_header_edit('Timeline', ValueType.ComplexPicker, 'to', '', {'file_extension':'.dtl', 'suggestions_func':[self, 'get_timeline_suggestions'], 'icon':load("res://addons/dialogic/Editor/Images/Resources/timeline.svg"), 'empty_text':'this timeline'})
	add_header_edit('Label', ValueType.ComplexPicker, 'at', '', {'suggestions_func':[self, 'get_label_suggestions'], 'editor_icon':['Label', 'EditorIcons'], 'empty_text':'the beginning'})

func get_timeline_suggestions(search_text:String):
	var suggestions = {}
	var resources = DialogicUtil.list_resources_of_type('.dtl')
	
	suggestions['this timeline'] = {'value':'', 'editor_icon':['GuiRadioUnchecked', 'EditorIcons']}
	
	for resource in resources:
		if search_text.is_empty() or search_text.to_lower() in DialogicUtil.pretty_name(resource).to_lower():
			suggestions[DialogicUtil.pretty_name(resource)] = {'value':resource, 'tooltip':resource, 'icon':load("res://addons/dialogic/Editor/Images/Resources/timeline.svg")}
	
	return suggestions
	
func get_label_suggestions(search_text:String):
	var suggestions = {}
	if !Timeline and search_text:
		suggestions[search_text] = {'value':search_text, 'editor_icon':['GuiScrollArrowRight', 'EditorIcons']}
	
	suggestions['the beginning'] = {'value':'', 'editor_icon':['GuiRadioUnchecked', 'EditorIcons']}
	
	if Timeline:
		for event in Timeline._events:
			if event is DialogicLabelEvent:
				if event.Name and !search_text or search_text.to_lower() in event.Name.to_lower():
					suggestions[event.Name] = {'value':event.Name, 'editor_icon':['Label', 'EditorIcons']}
	else:
		var current = load(ProjectSettings.get_setting('dialogic/editor/current_timeline_path'))
		if current:
			for event in current._events:
				if event is DialogicLabelEvent:
					if event.Name and !search_text or search_text.to_lower() in event.Name.to_lower():
						suggestions[event.Name] = {'value':event.Name, 'editor_icon':['Label', 'EditorIcons']}
	return suggestions
