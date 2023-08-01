@tool
extends HBoxContainer

# Dialogic Editor toolbar. Works together with editors_mangager.

################################################################################
## 					EDITOR BUTTONS/LABELS 
################################################################################

func add_icon_button(icon: Texture, tooltip: String) -> Button:
	var button := Button.new()
	button.icon = icon
	button.tooltip_text = tooltip
	button.flat = true
	add_child(button)
	move_child(button, -2)
	return button


func add_custom_button(label:String, icon:Texture) -> Button:
	var button := Button.new()
	button.text = label
	button.icon = icon
	button.flat = true
	%CustomButtons.add_child(button)
	custom_minimum_size.y = button.size.y
	return button


func hide_all_custom_buttons() -> void:
	for button in %CustomButtons.get_children():
		button.hide()


func set_current_resource_text(text:String) -> void:
	%CurrentResource.text = text

