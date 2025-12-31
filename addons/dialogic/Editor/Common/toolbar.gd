@tool
extends HBoxContainer

# Dialogic Editor toolbar. Works together with editors_mangager.

################################################################################
## 					EDITOR BUTTONS/LABELS
################################################################################
func _ready() -> void:
	if owner.get_parent() is SubViewport:
		return
	%CustomButtons.custom_minimum_size.y = 33 * DialogicUtil.get_editor_scale()

	for child in get_children():
		if child is Button:
			child.queue_free()


func add_button(icon: Texture, label:String, tooltip: String, placement:int) -> Button:
	var button := Button.new()
	button.icon = icon
	button.text = label
	button.tooltip_text = tooltip
	button.theme_type_variation = "FlatButton"
	button.size_flags_vertical = Control.SIZE_FILL
	%CustomButtons.add_child(button)
	return button
