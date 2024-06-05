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


func add_icon_button(icon: Texture, tooltip: String) -> Button:
	var button := Button.new()
	button.icon = icon
	button.tooltip_text = tooltip
	button.flat = true
	button.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	button.add_theme_color_override('icon_hover_color', get_theme_color('warning_color', 'Editor'))
	button.add_theme_stylebox_override('focus', StyleBoxEmpty.new())
	add_child(button)
	move_child(button, -2)
	return button


func add_custom_button(label:String, icon:Texture) -> Button:
	var button := Button.new()
	button.text = label
	button.icon = icon
#	button.flat = true

	button.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	%CustomButtons.add_child(button)
#	custom_minimum_size.y = button.size.y
	return button


func hide_all_custom_buttons() -> void:
	for button in %CustomButtons.get_children():
		button.hide()



