tool
extends Control

const TimelineDisplayer = preload("res://addons/dialogic/Editor/TimelineEditor/timeline_displayer.gd")
const EventNode = preload("res://addons/dialogic/Editor/event_node/event_node.gd")

var timeline_displayer:TimelineDisplayer setget set_timeline_displayer

func set_timeline_displayer(displayer:TimelineDisplayer) -> void:
	if is_instance_valid(timeline_displayer):
		if timeline_displayer.is_connected("load_ended", self, "_load_ended"):
			timeline_displayer.disconnect("load_ended",self,"_load_ended")
	
	timeline_displayer = displayer
	
	if is_instance_valid(timeline_displayer):
		timeline_displayer.connect("load_ended", self, "_load_ended")


func _displayer_draw() -> void:
	var child_size:int = timeline_displayer.get_children().size()
	var td = timeline_displayer # timeline_displayer is too long, and i'm too lazy
	for node in timeline_displayer.get_children():
		node = node as Control
		if not node:
			continue
#		td.draw_line(node.rect_position, Vector2(0, node.rect_size.y), Color.red, 2)
		draw_rect(node.get_rect(), Color.red, false, 4)


func _load_ended() -> void:
	update()

func _init():
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE
