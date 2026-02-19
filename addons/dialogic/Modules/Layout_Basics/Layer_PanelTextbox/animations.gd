@tool
extends AnimationPlayer

## A custom script/node that adds some animations to the textbox.

@export var animation_in := "None"
@export var animation_out := "None"
@export var animation_new_text := "None"

var full_clear := true


func _ready() -> void:
	var text_system: Node = DialogicUtil.autoload().get(&'Text')
	text_system.animation_textbox_hide.connect(_on_textbox_hide)
	text_system.animation_textbox_show.connect(_on_textbox_show)
	text_system.animation_textbox_new_text.connect(_on_textbox_new_text)
	text_system.about_to_show_text.connect(_on_about_to_show_text)

	var animation_system: Node = DialogicUtil.autoload().get(&'Animations')
	animation_system.animation_interrupted.connect(_on_animation_interrupted)
	animation_finished.connect(animation_system.animation_finished)


func _on_textbox_show() -> void:
	if animation_in == "NONE":
		return

	play("RESET")

	var animation_system: Node = DialogicUtil.autoload().get(&'Animations')
	animation_system.start_animating()

	%OutsideMargin.modulate = Color.TRANSPARENT
	play(animation_in)


func _on_textbox_hide() -> void:
	if animation_out == "None":
		return

	play("RESET")

	var animation_system: Node = DialogicUtil.autoload().get(&'Animations')
	animation_system.start_animating()

	play(animation_out)


func _on_about_to_show_text(info:Dictionary) -> void:
	full_clear = !info.append


func _on_textbox_new_text() -> void:
	if DialogicUtil.autoload().Inputs.auto_skip.enabled:
		return

	if animation_new_text == "None":
		return

	var animation_system: Node = DialogicUtil.autoload().get(&'Animations')
	animation_system.start_animating()

	if full_clear:
		(%DialogicNode_DialogText as DialogicNode_DialogText).text = ""

	play(animation_new_text)


func _on_animation_interrupted() -> void:
	if is_playing():
		stop()


func _validate_property(property: Dictionary) -> void:
	var animations: String = "None"
	for i in get_animation_list():
		if i == "RESET": continue
		animations += ","+i

	if property.name.begins_with("animation_") and property.type == TYPE_STRING and property.hint_string != animations:
		property.hint = PROPERTY_HINT_ENUM
		property.hint_string = animations
		notify_property_list_changed()
