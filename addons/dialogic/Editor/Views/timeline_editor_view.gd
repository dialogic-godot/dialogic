tool
extends Control

const DialogicUtil = preload("res://addons/dialogic/Core/DialogicUtil.gd")

export(NodePath) var TimelineEventsContainer_path:NodePath

var base_resource:Resource setget _set_base_resource
var _resource = null

onready var timeline_events_container_node = get_node_or_null(TimelineEventsContainer_path)

func _draw() -> void:
	if not visible:
		_unload_events()

func _unload_events():
	for child in timeline_events_container_node.get_children():
		child.queue_free()

func _load_events() -> void:
	_unload_events()
	var _idx = 0
	for event in (_resource as DialogicTimelineResource).events.get_resources():
		DialogicUtil.Logger.print(self,["Trying to load event's node in:", event.resource_path])
		var event_node:DialogicEditorEventNode = (event as DialogicEventResource).get_event_editor_node()
		var _err = event_node.connect("delelete_item_requested", self, "_on_EventNode_deletion_requested")
		assert(_err == OK)
		_err = event_node.connect("save_item_requested", self, "_on_EventNode_save_requested")
		timeline_events_container_node.add_child(event_node)
		event_node.idx = _idx
		_idx += 1


func _set_base_resource(_r:Resource) -> void:
	if not _r:
#		push_error("No resource")
		return

	base_resource = _r
	_resource = _r
	DialogicUtil.Logger.print(self,["Using {res} at {path}".format({"res":_resource.get_class(), "path":_r.resource_path})])
	_load_events()


func _on_EventButtonsContainer_event_pressed(event_resource:DialogicEventResource) -> void:
	if not _resource:
		return
	
	(_resource as DialogicTimelineResource).events.add(event_resource)
	var _err = ResourceSaver.save(_resource.resource_path, _resource)
	assert(_err == OK)
	_load_events()

func _on_EventNode_deletion_requested(event) -> void:
	var _events:Array = (_resource as DialogicTimelineResource).events.get_resources()
	_events.erase(event)
	var _err = ResourceSaver.save(_resource.resource_path, _resource, ResourceSaver.FLAG_CHANGE_PATH)
	assert(_err == OK)
	_unload_events()
	_load_events()

func _on_EventNode_save_requested(event:DialogicEventResource) -> void:
	var _events:ResourceArray = (_resource as DialogicTimelineResource).events
	var _events_array:Array = _events.get_resources()
	assert(event in _events_array)
	var _idx = _events_array.find(event)
	if _idx != -1:
		assert(_events_array[_idx] == event)
		
#	var _err = ResourceSaver.save(_resource.resource_path, _resource)
#	assert(_err == OK)
