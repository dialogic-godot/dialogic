@tool
class_name DialogicStyleEvent
extends DialogicEvent

## Event that allows changing the currently displayed style.


### Settings

## The name of the style to change to. Can be set on the DialogicNode_Style. 
var style_name: String = ""


################################################################################
## 						EXECUTE
################################################################################

func _execute() -> void:
	dialogic.Styles.add_layout_style(style_name)
	
	finish()


################################################################################
## 						INITIALIZE
################################################################################

func _init() -> void:
	event_name = "Change Style"
	set_default_color('Color8')
	event_category = "Visuals"
	event_sorting_index = 1


################################################################################
## 						SAVING/LOADING
################################################################################
func get_shortcode() -> String:
	return "style"


func get_shortcode_parameters() -> Dictionary:
	return {
		#param_name : property_info
		"name" 		: {"property": "style_name", "default": "", 'suggestions':get_style_suggestions},
	}


################################################################################
## 						EDITOR REPRESENTATION
################################################################################

func build_event_editor():
	add_header_edit('style_name', ValueType.COMPLEX_PICKER, {
			'left_text'			:'Use style',
			'placeholder'		: 'Default',
			'suggestions_func' 	: get_style_suggestions, 
			'editor_icon' 		: ["PopupMenu", "EditorIcons"],
			'autofocus'			: true})


func get_style_suggestions(filter:String="") -> Dictionary:
	var styles := ProjectSettings.get_setting('dialogic/layout/styles', {'Default':{}})
	var suggestions := {}
	suggestions['<Default Style>'] = {'value':'', 'editor_icon':["MenuBar", "EditorIcons"]}
	for i in styles:
		suggestions[i] = {'value': i, 'editor_icon': ["PopupMenu", "EditorIcons"]}
	return suggestions
