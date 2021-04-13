tool
extends Resource
class_name DialogicEventResource

signal event_started(event_resource)
signal event_finished(event_resource)

var _caller:DialogicNode = null

#warning-ignore-all:unused_argument
func excecute(caller:DialogicNode) -> void:
	emit_signal("event_started", self)


func finish() -> void:
	emit_signal("event_finished", self)

func get_event_editor_node() -> DialogicEditorEventNode:
	return DialogicEditorEventNode.new()
