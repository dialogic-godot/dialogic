tool
extends Control

const DialogicUtil = preload("res://addons/dialogic/Core/DialogicUtil.gd")

export(NodePath) var TimelineEventsContainer_path:NodePath

var base_resource_path:String = "" setget _set_base_resource
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
	for event in (_resource as DialogicTimelineResource).events.get_resources():
		DialogicUtil.Logger.print(self,["Trying to load event's node in:", event.resource_path])
		var event_node = (event as DialogicEventResource).get_event_editor_node()
		timeline_events_container_node.add_child(event_node)


func _set_base_resource(path:String) -> void:
	var f = File.new()
	if not f.file_exists(path):
		DialogicUtil.Logger.print(self,"File {} doesn't exist".format(path))
		return

	base_resource_path = path
	_resource = ResourceLoader.load(path)
	DialogicUtil.Logger.print(self,["Using {res} at {path}".format({"res":_resource.get_class(), "path":path})])
	_load_events()
