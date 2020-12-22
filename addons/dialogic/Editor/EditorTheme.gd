tool
extends Control

var editor_reference

func _ready():
	var settings = DialogicUtil.load_settings()
	# Font 
	if settings.has('theme_font'):
		$VBoxContainer/HBoxContainer6/FontButton.text = settings['theme_font']
	# Text and shadows
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
	# Text speed
	if settings.has('theme_text_speed'):
		$VBoxContainer/HBoxContainer6/TextSpeed.value = settings['theme_text_speed']

	
	# Images
	if settings.has('theme_background_image'):
		$VBoxContainer/HBoxContainer4/BackgroundTextureButton.text = settings['theme_background_image']
	if settings.has('theme_next_image'):
		$VBoxContainer/HBoxContainer4/NextIndicatorButton.text = settings['theme_next_image']
	
	# Action
	if settings.has('theme_action_key'):
		$VBoxContainer/VBoxContainer/HBoxContainer/VBoxContainer/ActionOptionButton.text = settings['theme_action_key']

	#Refreshing the dialog 
	_on_PreviewButton_pressed()

func _on_BackgroundTextureButton_pressed():
	editor_reference.godot_dialog("*.png")
	editor_reference.godot_dialog_connect(self, "_on_background_selected")


func _on_background_selected(path, target):
	DialogicUtil.update_setting('theme_background_image', path)
	$VBoxContainer/HBoxContainer4/BackgroundTextureButton.text = path


func _on_NextIndicatorButton_pressed():
	editor_reference.godot_dialog("*.png")
	editor_reference.godot_dialog_connect(self, "_on_indicator_selected")


func _on_indicator_selected(path, target):
	DialogicUtil.update_setting('theme_next_image', path)
	$VBoxContainer/HBoxContainer4/NextIndicatorButton.text = path


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
	for i in $VBoxContainer/Panel.get_children():
		i.free()
	var dialogic_node = load("res://addons/dialogic/Nodes/Dialog.tscn")
	var preview_dialog = dialogic_node.instance()
	preview_dialog.get_node('TextBubble/NextIndicator/AnimationPlayer').play('IDLE')
	preview_dialog.dialog_script['events'] = [{
		"character":"",
		"portrait":"",
		"text": $VBoxContainer/HBoxContainer5/TextEdit.text
	}]
	$VBoxContainer/Panel.add_child(preview_dialog)


func _on_ActionOptionButton_item_selected(index):
	DialogicUtil.update_setting('theme_action_key', $VBoxContainer/VBoxContainer/HBoxContainer/VBoxContainer/ActionOptionButton.text)


func _on_ActionOptionButton_pressed():
	var action_option_button = $VBoxContainer/VBoxContainer/HBoxContainer/VBoxContainer/ActionOptionButton
	action_option_button.clear()
	action_option_button.add_item('[Select Action]')
	InputMap.load_from_globals()
	print(InputMap.get_actions())
	for a in InputMap.get_actions():
		action_option_button.add_item(a)


func _on_FontButton_pressed():
	editor_reference.godot_dialog("*.tres")
	editor_reference.godot_dialog_connect(self, "_on_Font_selected")


func _on_Font_selected(path, target):
	DialogicUtil.update_setting('theme_font', path)
	$VBoxContainer/HBoxContainer6/FontButton.text = path


func _on_textSpeed_value_changed(value):
	DialogicUtil.update_setting('theme_text_speed', value)
	
