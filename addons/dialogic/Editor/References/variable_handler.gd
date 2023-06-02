@tool
extends Node

const VARIABLES = 'variables'

var timeline_references : Dictionary = {}
var variable_references : Dictionary = {}


func format_as_variable(variable: String):
	var formatted_variable = '{' + variable + '}'
	return formatted_variable


func create_key_in_references(variable: String):
	variable_references[variable] = []


func update_key_in_references(old_value: String, new_value: String):
	variable_references[new_value] = variable_references[old_value]
	variable_references.erase(old_value)


func remove_key_in_references(variable: String):
	variable_references.erase(variable)


func store_timeline(timeline: DialogicTimeline):
	print(timeline_references)
	for variable in timeline_references[timeline][VARIABLES]:
		if !variable_references.has(variable):
			printerr("Variable: " + variable + ". Don't exist in the current project!")
			continue
		
		if not timeline in variable_references[variable]:
			variable_references[variable].append(timeline)


func clear_old_timeline_links(timeline: DialogicTimeline, variables_in_timeline: Array):
	for variable in timeline_references[timeline][VARIABLES]:
		if variables_in_timeline.has(variable):
			continue
		
		variable_references[variable].erase(timeline)