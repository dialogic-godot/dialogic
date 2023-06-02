@tool
extends Node


const TIMELINE_REF_SETTINGS_PATH = 'dialogic/references/timelines'
const VARIABLE_REF_SETTINGS_PATH = 'dialogic/references/variables'

# {
#	timeline.dtl(Resource):	{'variables': ['MyVariable'], 'portraits': ...}
# }
var timeline_references : Dictionary = {}

# {
#	'MyVariable': [timeline.dtl(Resource), foo.dtl]
# }
var variable_references : Dictionary = {}


func _ready() -> void:
#	_get_references_from_settings()
	_inject_dependencies_to_handlers()
	

func _get_references_from_settings():
	timeline_references = ProjectSettings.get_setting(TIMELINE_REF_SETTINGS_PATH)
	variable_references = ProjectSettings.get_setting(VARIABLE_REF_SETTINGS_PATH)


func _inject_dependencies_to_handlers():
	$TimelineHandler.timeline_references = timeline_references

	$VariableHandler.timeline_references = timeline_references
	$VariableHandler.variable_references = variable_references


## TIMELINES

func _on_timeline_saved(timeline: DialogicTimeline):
	if !timeline_references.has(timeline):
		$TimelineHandler.create_key_in_references(timeline)
	
	var variables_in_timeline = $TimelineHandler.get_variables(timeline)

	$VariableHandler.clear_old_timeline_links(timeline, variables_in_timeline)
	$TimelineHandler.clear_variable_links(timeline)

	$TimelineHandler.store_variables(timeline, variables_in_timeline)
	$VariableHandler.store_timeline(timeline)
	
#	ProjectSettings.set_setting(TIMELINE_REF_SETTINGS_PATH, timeline_references)
#	ProjectSettings.set_setting(VARIABLE_REF_SETTINGS_PATH, variable_references)
	

## VARIABLES

func _on_variable_value_changed(old_value: String, new_value: String):
	if variable_references.has(new_value):
		printerr(new_value + " already exists in variable references dictionary.")
		return

	if variable_references.has(old_value):
		$VariableHandler.update_key_in_references(old_value, new_value)
		var old_value_formatted = $VariableHandler.format_as_variable(old_value)
		var new_value_formatted = $VariableHandler.format_as_variable(new_value)
		$ReplaceHandler.replace(old_value_formatted, new_value_formatted, variable_references[new_value])
		return
	
	# If variable_references doesn't have a key for this variable yet
	$VariableHandler.create_key_in_references(new_value)
	
#	ProjectSettings.set_setting(VARIABLE_REF_SETTINGS_PATH, variable_references)

func _on_variable_removed(variable: String):
	$VariableHandler.remove_key_in_references(variable)

#	ProjectSettings.set_setting(VARIABLE_REF_SETTINGS_PATH, variable_references)