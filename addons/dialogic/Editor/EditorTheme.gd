tool
extends Control

var editor_reference

# The amazing and revolutionary path system that magically works and you can't
# complain because "that is not how you are supposed to work". If there was only
# a way to set an id and then access that node via id...
# Here you have paths in all its glory. Praise the paths (っ´ω`c)♡
onready var nodes = {
	'shadow_bool': $VBoxContainer/HBoxContainer2/Text/GridContainer/CheckBoxShadow,
	'shadow_picker': $VBoxContainer/HBoxContainer2/Text/GridContainer/ColorPickerButtonShadow,
	'color_picker': $VBoxContainer/HBoxContainer2/Text/GridContainer/ColorPickerButton,
	'font_button': $VBoxContainer/HBoxContainer2/Text/GridContainer/FontButton,
	'shadow_offset_x': $VBoxContainer/HBoxContainer2/Text/GridContainer/HBoxContainer/ShadowOffsetX,
	'shadow_offset_y': $VBoxContainer/HBoxContainer2/Text/GridContainer/HBoxContainer/ShadowOffsetY,
	'text_speed': $VBoxContainer/HBoxContainer2/Text/GridContainer/TextSpeed,
	'text_offset_v': $VBoxContainer/HBoxContainer2/DialogBox/GridContainer/HBoxContainer/TextOffsetV,
	'text_offset_h': $VBoxContainer/HBoxContainer2/DialogBox/GridContainer/HBoxContainer/TextOffsetH,
	'background_texture_button_visible': $VBoxContainer/HBoxContainer2/DialogBox/GridContainer/HBoxContainer3/CheckBox,
	'background_texture_button': $VBoxContainer/HBoxContainer2/DialogBox/GridContainer/HBoxContainer3/BackgroundTextureButton,
	'next_indicator_button': $VBoxContainer/HBoxContainer2/DialogBox/GridContainer/NextIndicatorButton,
	'next_action_button': $VBoxContainer/HBoxContainer2/DialogBox/GridContainer/BoxContainer/ActionOptionButton,
	'text_preview': $VBoxContainer/HBoxContainer3/TextEdit,
	'preview_panel': $VBoxContainer/Panel,
	'theme_background_color_visible': $VBoxContainer/HBoxContainer2/DialogBox/GridContainer/HBoxContainer2/CheckBox,
	'theme_background_color': $VBoxContainer/HBoxContainer2/DialogBox/GridContainer/HBoxContainer2/ColorPickerButton,
}

func _ready():
	var settings = DialogicUtil.load_settings()
	# Font 
	if settings.has('theme_font'):
		nodes['font_button'].text = DialogicUtil.get_filename_from_path(settings['theme_font'])
	# Text and shadows
	if settings.has('theme_text_color'):
		nodes['color_picker'].color = Color('#' + str(settings['theme_text_color']))
	if settings.has('theme_text_shadow'):
		nodes['shadow_bool'].pressed = settings['theme_text_shadow']
	if settings.has('theme_text_shadow_color'):
		nodes['shadow_picker'].color = Color('#' + str(settings['theme_text_shadow_color']))
	if settings.has('theme_shadow_offset_x'):
		nodes['shadow_offset_x'].value = settings['theme_shadow_offset_x']
	if settings.has('theme_shadow_offset_y'):
		nodes['shadow_offset_y'].value = settings['theme_shadow_offset_y']
	# Text speed
	if settings.has('theme_text_speed'):
		nodes['text_speed'].value = settings['theme_text_speed']
	# Margin
	if settings.has('theme_text_margin'):
		nodes['text_offset_v'].value = settings['theme_text_margin']
	if settings.has('theme_text_margin_h'):
		nodes['text_offset_h'].value = settings['theme_text_margin_h']
	
	# Backgrounds
	if settings.has('theme_background_image'):
		nodes['background_texture_button'].text = DialogicUtil.get_filename_from_path(settings['theme_background_image'])

	if settings.has('background_texture_button_visible'):
		nodes['background_texture_button_visible'].pressed = settings['background_texture_button_visible']
	if settings.has('theme_background_color'):
		nodes['theme_background_color'].color = Color('#' + str(settings['theme_background_color']))
	
	#	if settings.has('theme_background_color_visible'):
	#		nodes['theme_background_color_visible'].pressed = settings['theme_background_color_visible']
	nodes['theme_background_color_visible'].pressed = DialogicUtil.load_key(settings, 'theme_background_color_visible', false)
	
	# Next image
	if settings.has('theme_next_image'):
		nodes['next_indicator_button'].text = DialogicUtil.get_filename_from_path(settings['theme_next_image'])
	
	# Action
	if settings.has('theme_action_key'):
		nodes['next_action_button'].text = settings['theme_action_key']

	#Refreshing the dialog 
	_on_PreviewButton_pressed()

func _on_BackgroundTextureButton_pressed():
	editor_reference.godot_dialog("*.png")
	editor_reference.godot_dialog_connect(self, "_on_background_selected")


func _on_background_selected(path, target):
	DialogicUtil.update_setting('theme_background_image', path)
	nodes['background_texture_button'].text = DialogicUtil.get_filename_from_path(path)


func _on_NextIndicatorButton_pressed():
	editor_reference.godot_dialog("*.png")
	editor_reference.godot_dialog_connect(self, "_on_indicator_selected")


func _on_indicator_selected(path, target):
	DialogicUtil.update_setting('theme_next_image', path)
	nodes['next_indicator_button'].text = DialogicUtil.get_filename_from_path(path)


func _on_ColorPickerButton_color_changed(color):
	DialogicUtil.update_setting('theme_text_color', color.to_html())


func _on_ColorPickerButtonShadow_color_changed(color):
	DialogicUtil.update_setting('theme_text_shadow_color', color.to_html())
	nodes['shadow_bool'].pressed = true


func _on_CheckBoxShadow_toggled(button_pressed):
	DialogicUtil.update_setting('theme_text_shadow', button_pressed)


func _on_ShadowOffset_value_changed(_value):
	DialogicUtil.update_setting('theme_shadow_offset_x', nodes['shadow_offset_x'].value)
	DialogicUtil.update_setting('theme_shadow_offset_y', nodes['shadow_offset_y'].value)


func _on_PreviewButton_pressed():
	for i in nodes['preview_panel'].get_children():
		i.free()
	var dialogic_node = load("res://addons/dialogic/Nodes/Dialog.tscn")
	var preview_dialog = dialogic_node.instance()
	preview_dialog.get_node('TextBubble/NextIndicator/AnimationPlayer').play('IDLE')
	preview_dialog.dialog_script['events'] = [{
		"character":"",
		"portrait":"",
		"text": nodes['text_preview'].text
	}]
	nodes['preview_panel'].add_child(preview_dialog)


func _on_ActionOptionButton_item_selected(index):
	DialogicUtil.update_setting('theme_action_key', nodes['next_action_button'].text)


func _on_ActionOptionButton_pressed():
	nodes['next_action_button'].clear()
	nodes['next_action_button'].add_item('[Select Action]')
	InputMap.load_from_globals()
	print(InputMap.get_actions())
	for a in InputMap.get_actions():
		nodes['next_action_button'].add_item(a)


func _on_FontButton_pressed():
	editor_reference.godot_dialog("*.tres")
	editor_reference.godot_dialog_connect(self, "_on_Font_selected")


func _on_Font_selected(path, target):
	DialogicUtil.update_setting('theme_font', path)
	nodes['font_button'].text = DialogicUtil.get_filename_from_path(path)


func _on_textSpeed_value_changed(value):
	DialogicUtil.update_setting('theme_text_speed', value)


func _on_TextMargin_value_changed(value):
	DialogicUtil.update_setting('theme_text_margin', value)


func _on_TextMarginH_value_changed(value):
	DialogicUtil.update_setting('theme_text_margin_h', value)


func _on_BackgroundColor_CheckBox_toggled(button_pressed):
	DialogicUtil.update_setting('theme_background_color_visible', button_pressed)


func _on_BackgroundColor_ColorPickerButton_color_changed(color):
	DialogicUtil.update_setting('theme_background_color', color.to_html())


func _on_BackgroundTexture_CheckBox_toggled(button_pressed):
	DialogicUtil.update_setting('background_texture_button_visible', button_pressed)
