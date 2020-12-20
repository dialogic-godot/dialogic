tool
extends Control

var editor_reference

func _ready():
	var action_option_button = $VBoxContainer/VBoxContainer/HBoxContainer/VBoxContainer/ActionOptionButton
	action_option_button.add_item('[Select Action]')
	for a in InputMap.get_actions():
		action_option_button.add_item(a)
	DialogicUtil.test()
	
	
	var settings = DialogicUtil.load_settings()
	if settings.has('theme_text_color'):
		$VBoxContainer/HBoxContainer6/ColorPickerButton.color = Color('#' + str(settings['theme_text_color']))
	if settings.has('theme_text_shadow'):
		$VBoxContainer/HBoxContainer/CheckBoxShadow.pressed = settings['theme_text_shadow']
	if settings.has('theme_text_shadow_color'):
		$VBoxContainer/HBoxContainer/ColorPickerButtonShadow.color = Color('#' + str(settings['theme_text_shadow_color']))
	
	if settings.has('theme_shadow_offset_x'):
		$VBoxContainer/HBoxContainer/ShadowOffsetX.value = settings['theme_shadow_offset_x']
	if settings.has('theme_shadow_offset_y'):
		$VBoxContainer/HBoxContainer/ShadowOffsetY.value = settings['theme_shadow_offset_y']

	#Refreshing the dialog 
	#_on_PreviewButton_pressed()

func _on_BackgroundTextureButton_pressed():
	editor_reference.godot_dialog("*.png")
	editor_reference.godot_dialog_connect(self, "_on_background_selected")


func _on_background_selected(path, target):
	$VBoxContainer/HBoxContainer4/BackgroundTextureButton.icon = load(path)


func _on_NextIndicatorButton_pressed():
	editor_reference.godot_dialog("*.png")
	editor_reference.godot_dialog_connect(self, "_on_indicator_selected")


func _on_indicator_selected(path, target):
	$VBoxContainer/HBoxContainer4/NextIndicatorButton.icon = load(path)


func _on_ColorPickerButton_color_changed(color):
	DialogicUtil.update_setting('theme_text_color', color.to_html())


func _on_ColorPickerButtonShadow_color_changed(color):
	DialogicUtil.update_setting('theme_text_shadow_color', color.to_html())
	$VBoxContainer/HBoxContainer/CheckBoxShadow.pressed = true


func _on_CheckBoxShadow_toggled(button_pressed):
	DialogicUtil.update_setting('theme_text_shadow', button_pressed)


func _on_ShadowOffset_value_changed(_value):
	DialogicUtil.update_setting('theme_shadow_offset_x', $VBoxContainer/HBoxContainer/ShadowOffsetX.value)
	DialogicUtil.update_setting('theme_shadow_offset_y', $VBoxContainer/HBoxContainer/ShadowOffsetY.value)


func _on_PreviewButton_pressed():
	if $VBoxContainer/Panel.has_node("DialogNode"):
		$VBoxContainer/Panel/DialogNode.free()
	var dialogic_node = load("res://addons/dialogic/Nodes/Dialog.tscn")
	var preview_dialog = dialogic_node.instance()
	preview_dialog.dialog_script['events'] = [{
		"character":"",
		"portrait":"",
		"text": $VBoxContainer/HBoxContainer5/TextEdit.text
	}]
	$VBoxContainer/Panel.add_child(preview_dialog)
