extends Control

## The timeline to load when starting the scene
#export(String, "TimelineDropdown") var timeline_name: String
export(String, FILE) var timeline_name: String

var timeline
var text_speed = 0.02
var event_finished = false
var next_input = 'ui_accept'

onready var TextNode:RichTextLabel = $TextBubble/RichTextLabel
onready var NameNode:Label = $TextBubble/NameLabel
onready var NextIndicatorNode:Control = $TextBubble/NextIndicator

func _ready() -> void:

	if not timeline_name:
		var _text_event = DialogicTextEventResource.new()
		_text_event.text = "[Dialogic Error] No timeline specified."
		timeline = DialogicTimelineResource.new()
		timeline.events.append(_text_event)
	else:
		load_timeline()

	if not Engine.editor_hint:
		load_dialog()


func _process(_delta: float) -> void:
	NextIndicatorNode.visible = event_finished


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(next_input):
		if event_finished:
			timeline.go_to_next_event(self)


func load_dialog() -> void:
	timeline.start(self)


func load_timeline() -> void:
	timeline = load(timeline_name)


func _on_event_start(event):
	event_finished = false


func _on_event_finished():
	event_finished = true
