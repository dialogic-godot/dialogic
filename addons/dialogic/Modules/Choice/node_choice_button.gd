class_name DialogicNode_ChoiceButton
extends Button
## This button allows the player to make a choice in the Dialogic system.
##
## When a choice is reached Dialogic will automatically show ChoiceButtons 
## and call their [code]_load_info()[/code] method which will display the choices.
## You will need to ensure that enough choice buttons are available in the tree 
## to display all choices.[br]
## 
## [br]  
## You can extend this node and implement some custom logic by overwriting
## the [code]_load_info(info:Dictionary)[/code] method. [br]
## [br]
## If you need RichText support, consider adding a RichTextLabel child and setting it as the [member text_node].[br]
## 
## [br]
## DialogicChoiceButtons will grab the focus when hovered to avoid a confusing 
## focus style being present for players who use the mouse.[br]
## To avoid the opposite situation, when the focus is changed by the player 
## and a different button is still hovered the mouse pointer will be moved
## to the now focused button as well.


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
## This can be used to have a custom text rendering child, like a RichTextLabel.
@export var text_node: Node


func _ready() -> void:
	add_to_group('dialogic_choice_button')
	shortcut_in_tooltip = false
	hide()
	
	# For players who use a mouse to make choices, mouse hover should grab focus.
	# Otherwise the auto-focused button will always show a highlighted color when
	# the mouse cursor is hovering on another button.
	if not mouse_entered.is_connected(grab_focus):
		mouse_entered.connect(grab_focus)
	if not focus_entered.is_connected(_on_choice_button_focus_entred):
		focus_entered.connect(_on_choice_button_focus_entred.bind(self))


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


## This method moves the mouse to the focused choice when the focus changes 
## while a choice button was hovered. [br]
## For players who use many devices (mouse/keyboard/gamepad, etc) at the same time to make choices,
## a grabing-focus triggered by keyboard/gamepad should also change the mouse cursor's
## position otherwise two buttons will have highlighted color(one highlighted button
## triggered by mouse hover and another highlighted button triggered by other devices' choice).
func _on_choice_button_focus_entred(focused_button: Button):
	var global_mouse_pos = get_global_mouse_position()
	var focused_button_rect = focused_button.get_global_rect()
	if focused_button_rect.has_point(global_mouse_pos):
		return
	# Only change mouse curor position when an unfocused button' rect has the cursor.
	for node in get_tree().get_nodes_in_group('dialogic_choice_button'):
		if node is Button:
			if node != focused_button and node.get_global_rect().has_point(global_mouse_pos):
				# We prefer to change only mouse_position.y or mouse_position.x to warp the
				# mouse to the focused button's rect to achieve the best visual effect.
				var modify_y_pos = Vector2(global_mouse_pos.x, focused_button.get_global_rect().get_center().y)
				if focused_button_rect.has_point(modify_y_pos):
					get_viewport().warp_mouse(modify_y_pos)
					return
					
				var modify_x_pos = Vector2(focused_button.get_global_rect().get_center().x, global_mouse_pos.y)
				if focused_button_rect.has_point(modify_x_pos):
					get_viewport().warp_mouse(modify_x_pos)
					return
					
				# Maybe the buttons are not aligned as vertically or horizontlly.
				# Or perhaps the length difference between the two buttons is quite large.
				# So we just make the cursor hover on the center of the focused button.
				get_viewport().warp_mouse(focused_button.get_global_rect().get_center())
				return
