class_name DialogicNode_ChoiceButton
extends Button
## The button allows the player to make a choice in the Dialogic system.
##
## This class is used in the Choice Layer. [br]
## You may change the [member text_node] to any [class Node] that has a
## `text` property. [br]
## If you don't set the [member text_node], the text will be set on this
## button instead.
##
## Using a different node may allow using rich text effects; they are
## not supported on buttons at this point.


## Emitted when the choice is selected. Unless overridden, this is when the button or its shortcut is pressed.
signal choice_selected


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


func _ready() -> void:
	add_to_group('dialogic_choice_button')
	shortcut_in_tooltip = false
	hide()


## Custom choice buttons can override this for specialized behavior when the choice button is pressed.
func _pressed():
	choice_selected.emit()


## Custom choice buttons can override this if their behavior should change
## based on event data. If the custom choice button does not override
## visibility, disabled-ness, nor the choice text, consider
## calling super(choice_info) at the start of the override.
##
## The choice_info Dictionary has the following keys:
## - event_index:    The index of the choice event in the timeline.
## - button_index:   The relative index of the choice (starts from 1).
## - visible:        If the choice should be visible.
## - disabled:       If the choice should be selectable.
## - text:           The text of the choice.
## - visited_before: If the choice has been selected before. Only available is the History submodule is enabled.
## - *:              Information from the event's additional info.
func _load_info(choice_info: Dictionary) -> void:
	set_choice_text(choice_info.text)
	visible = choice_info.visible
	disabled = choice_info.disabled


## Called when the text changes.
func set_choice_text(new_text: String) -> void:
	if text_node:
		text_node.text = new_text
	else:
		text = new_text
