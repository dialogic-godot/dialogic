@tool
@icon("node_next_indicator_icon.svg")
class_name DialogicNode_NextIndicator
extends Control
## A dialogic node that is shown when the text is fully revealed and hidden when the next event starts.

## If false, this indicator will not be used.
@export var enabled := true

## If true the next indicator will also be shown if the text is a question.
@export var show_on_questions := false
## If true the next indicator will be shown even if dialogic will autocontinue.
@export var show_on_autoadvance := false


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	add_to_group('dialogic_next_indicator')
	gui_input.connect(_on_gui_input)
	hide()


func _on_gui_input(event: InputEvent) -> void:
	DialogicUtil.autoload().Inputs.handle_node_gui_input(event)
