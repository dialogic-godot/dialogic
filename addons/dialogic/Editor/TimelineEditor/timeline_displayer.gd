tool
extends VBoxContainer

const EventClass = preload("res://addons/dialogic/resources/event_class.gd")
const TimelineClass = preload("res://addons/dialogic/resources/timeline_class.gd")

signal event_node_added(event_node)
signal load_started
signal load_ended

const EventNode = preload("res://addons/dialogic/Editor/event_node/event_node.gd")
const DEFAULT_MIN_SIZE = Vector2(128, 32)

var data := []
var loading := false

# Hint for editor
var last_used_timeline:Resource = null


func load_timeline(timeline) -> void:
	remove_all_displayed_events()
	data = timeline.get_events()
	last_used_timeline = timeline
	update_view()


func is_loading() -> bool:
	return loading


func update_view() -> void:
	_notify_load_started()
	
	for event_idx in data.size():
		var event = data[event_idx]
		var event_node = _get_event_node(event)
		event_node.set("timeline",last_used_timeline)
		event_node.set("idx", event_idx)
		emit_signal("event_node_added", event_node)
		add_child(event_node)
		event_node.call_deferred("update_values")
	
	_notify_load_ended()


func remove_all_displayed_events() -> void:
	for child in get_children():
		child.queue_free()


func reload() -> void:
	remove_all_displayed_events()
	load_timeline(last_used_timeline)


func _get_event_node(event:EventClass) -> EventNode:
	if not event:
		return null
	
	var event_node:EventNode
	event_node = event.get("custom_event_node") as EventNode
	if event_node == null:
		event_node = EventNode.new()
	
	event_node.event = event
	return event_node


func _notify_load_started() -> void:
	loading = true
	emit_signal("load_started")


func _notify_load_ended() -> void:
	loading = false
	emit_signal("load_ended")
	queue_sort()


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	size_flags_horizontal = SIZE_EXPAND_FILL
	size_flags_vertical = SIZE_EXPAND_FILL
	rect_min_size = DEFAULT_MIN_SIZE
