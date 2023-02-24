@tool
extends HBoxContainer

# Dialogic Editor toolbar. Works together with editors_mangager.

func _ready() -> void:
	$Panel.add_theme_stylebox_override('panel', get_theme_stylebox("LaunchPadNormal", "EditorStyles"))

################################################################################
## 					EDITOR BUTTONS/LABELS 
################################################################################

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


func set_unsaved_indicator(saved:bool = true) -> void:
	if saved and %CurrentResource.text.ends_with('(*)'):
		%CurrentResource.text = %CurrentResource.text.trim_suffix('(*)')
	if not saved and not %CurrentResource.text.ends_with('(*)'):
		%CurrentResource.text = %CurrentResource.text+"(*)"

