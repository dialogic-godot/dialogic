@tool
extends Node

# {
#	timeline.dtl(Resource):	{'variables': ['MyVariable'], 'portraits': ...}
# }
var timeline_references : Dictionary = {}

# {
#	'MyVariable': [timeline.dtl(Resource), foo.dtl]
# }
var variable_references : Dictionary = {}


## VARIABLES

func _on_variable_value_changed(old_value: String, new_value: String):
	print("OLD::" + old_value + "::NEW::" + new_value)
	pass

func _on_variable_removed(variable: String):
	print("REMOVED::" + variable)
	pass