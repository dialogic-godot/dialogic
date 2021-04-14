tool
class_name DialogicNode
extends Control

var DialogicUtil = load("res://addons/dialogic/Core/DialogicUtil.gd")

## The timeline to load when starting the scene
#export(String, "TimelineDropdown") var timeline_name: String
export(String, FILE) var timeline_name: String

export(NodePath) var DialogNode_path:NodePath
export(NodePath) var PortraitsNode_path:NodePath

var timeline
var text_speed = 0.02
var event_finished = false
var next_input = 'ui_accept'

onready var DialogNode := get_node_or_null(DialogNode_path)
onready var PortraitManager := get_node_or_null(PortraitsNode_path)


func _ready() -> void:
	
	if not timeline_name:
		timeline = DialogicUtil.Error.not_found_timeline()
	else:
		load_timeline()

	if not Engine.editor_hint:
		visible = false
		if DialogNode:
			DialogNode.visible = false
		if PortraitManager:
			PortraitManager.visible = false
		load_dialog()
	else:
		set_process(false)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(next_input):
		if event_finished:
			timeline.go_to_next_event(self)


func load_dialog() -> void:
	timeline.start(self)


func load_timeline() -> void:
	timeline = load(timeline_name)


func _on_event_start(_event):
	event_finished = false
	if DialogNode:
		DialogNode.event_finished = event_finished


func _on_event_finished(_event, go_to_next_event=false):
	event_finished = true
	if DialogNode:
		DialogNode.event_finished = event_finished
	
	if go_to_next_event:
		timeline.go_to_next_event(self)
