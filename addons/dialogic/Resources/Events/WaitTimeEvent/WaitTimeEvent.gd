tool
class_name DialogicWaitTimeEvent
extends DialogicEventResource

export(float, 0, 60, 1) var wait_time = 0.0


func excecute(caller:Control) -> void:
	.excecute(caller)
	yield(caller.get_tree().create_timer(wait_time), "timeout")
	finish()


func get_event_editor_node() -> DialogicEditorEventNode:
	var _scene_resource:PackedScene = load("res://addons/dialogic/Nodes/editor_event_nodes/wait_time_event_node/wait_time_event_node.tscn")
	_scene_resource.resource_local_to_scene = true
	var _instance = _scene_resource.instance(PackedScene.GEN_EDIT_STATE_INSTANCE)
	_instance.base_resource = self
	return _instance
