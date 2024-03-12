## Dialogic Node that displays choices.

class_name DialogicNode_ChoiceButton
extends Button



## Used to identify what choices to put on. If you leave it at -1, choices will be distributed automatically.
@export var choice_index: int = -1

## Can be set to play this sound when pressed. Requires a sibling DialogicNode_ButtonSound node.
@export var sound_pressed: AudioStream
## Can be set to play this sound when hovered. Requires a sibling DialogicNode_ButtonSound node.
@export var sound_hover: AudioStream
## Can be set to play this sound when focused. Requires a sibling DialogicNode_ButtonSound node.
@export var sound_focus: AudioStream
## If set, the text will be set on this node's `text` property instead.
@export var text_node: Node


## Called when the text changes.
func _set_text_changed(new_text: String) -> void:
	if text_node == null:
		text = new_text

	else:
		text_node.text = new_text


func _ready() -> void:
	add_to_group('dialogic_choice_button')
	shortcut_in_tooltip = false
	hide()
