tool
extends Control

var editor_reference

# The amazing and revolutionary path system that magically works and you can't
# complain because "that is not how you are supposed to work". If there was only
# a way to set an id and then access that node via id...
# Here you have paths in all its glory. Praise the paths (っ´ω`c)♡
onready var nodes = {
	'shadow_bool': $VBoxContainer/HBoxContainer2/Text/GridContainer/HBoxContainer2/CheckBoxShadow,
	'shadow_picker': $VBoxContainer/HBoxContainer2/Text/GridContainer/HBoxContainer2/ColorPickerButtonShadow,
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
	# Buttons
	'button_background': $VBoxContainer/HBoxContainer2/ButtonStyle/GridContainer/HBoxContainer2/ColorPickerButton,
	'button_background_visible': $VBoxContainer/HBoxContainer2/ButtonStyle/GridContainer/HBoxContainer2/CheckBox,
	'button_image': $VBoxContainer/HBoxContainer2/ButtonStyle/GridContainer/HBoxContainer3/BackgroundTextureButton,
	'button_image_visible': $VBoxContainer/HBoxContainer2/ButtonStyle/GridContainer/HBoxContainer3/CheckBox,
	'button_offset_x': $VBoxContainer/HBoxContainer2/ButtonStyle/GridContainer/HBoxContainer/TextOffsetH,
	'button_offset_y': $VBoxContainer/HBoxContainer2/ButtonStyle/GridContainer/HBoxContainer/TextOffsetV,
	'button_separation': $VBoxContainer/HBoxContainer2/ButtonStyle/GridContainer/VerticalSeparation,
}

func _ready():
	var settings = DialogicUtil.load_settings()
	# Font 
	nodes['font_button'].text = DialogicUtil.get_filename_from_path(DialogicUtil.load_key(settings, 'theme_font', 'res://addons/dialogic/Fonts/DefaultFont.tres'))
	
	# Text and shadows
	nodes['color_picker'].color = Color('#' + str(DialogicUtil.load_key(settings, 'theme_text_color', 'ff000000')))
	nodes['shadow_bool'].pressed = DialogicUtil.load_key(settings, 'theme_text_shadow', false)
	nodes['shadow_picker'].color = Color('#' + str(DialogicUtil.load_key(settings, 'theme_text_shadow_color', 'ff000000')))
	nodes['shadow_offset_x'].value = DialogicUtil.load_key(settings, 'theme_shadow_offset_x', 2)
	nodes['shadow_offset_y'].value = DialogicUtil.load_key(settings, 'theme_shadow_offset_y', 2)
	
	# Text speed
	nodes['text_speed'].value = DialogicUtil.load_key(settings, 'theme_text_speed', 2)
		
	# Margin	
	nodes['text_offset_v'].value = DialogicUtil.load_key(settings, 'theme_text_margin', 10)
	nodes['text_offset_h'].value = DialogicUtil.load_key(settings, 'theme_text_margin_h', 10)
	
	# Backgrounds
	nodes['background_texture_button'].text = DialogicUtil.get_filename_from_path(DialogicUtil.load_key(settings, 'theme_background_image', 'res://addons/dialogic/Images/background/background-2.png'))
	nodes['background_texture_button_visible'].pressed = DialogicUtil.load_key(settings, 'background_texture_button_visible', true)
	nodes['theme_background_color'].color = Color('#' + str(DialogicUtil.load_key(settings, 'theme_background_color', 'ff000000')))
	nodes['theme_background_color_visible'].pressed = DialogicUtil.load_key(settings, 'theme_background_color_visible', false)
	
	# Next image
	nodes['next_indicator_button'].text = DialogicUtil.get_filename_from_path(DialogicUtil.load_key(settings, 'theme_next_image', 'res://addons/dialogic/Images/next-indicator.png'))

	# Action
	nodes['next_action_button'].text = DialogicUtil.load_key(settings, 'theme_action_key', 'ui_accept')
	
	# Buttons
	nodes['button_background'].color = Color('#' + str(DialogicUtil.load_key(settings, 'button_background', 'ff000000')))
	nodes['button_background_visible'].pressed = DialogicUtil.load_key(settings, 'button_background_visible', false)
	nodes['button_image'].text = DialogicUtil.get_filename_from_path(DialogicUtil.load_key(settings, 'button_image', 'res://addons/dialogic/Images/background/background-2.png'))
	nodes['button_image_visible'].pressed = DialogicUtil.load_key(settings, 'button_image_visible', false)
	
	nodes['button_offset_x'].value = DialogicUtil.load_key(settings, 'button_offset_x', 0)
	nodes['button_offset_y'].value = DialogicUtil.load_key(settings, 'button_offset_y', 0)
	nodes['button_separation'].value = DialogicUtil.load_key(settings, 'button_separation', 0)

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


func _on_button_background_visible_toggled(button_pressed):
	DialogicUtil.update_setting('button_background_visible', button_pressed)


func _on_button_background_color_color_changed(color):
	DialogicUtil.update_setting('button_background', color.to_html())


func _on_ButtonOffset_value_changed(value):
	DialogicUtil.update_setting('button_offset_x', nodes['button_offset_x'].value)
	DialogicUtil.update_setting('button_offset_y', nodes['button_offset_y'].value)


func _on_VerticalSeparation_value_changed(value):
	DialogicUtil.update_setting('button_separation', nodes['button_separation'].value)


func _on_button_texture_toggled(button_pressed):
	DialogicUtil.update_setting('button_image_visible', button_pressed)


func _on_ButtonTextureButton_pressed():
	editor_reference.godot_dialog("*.png")
	editor_reference.godot_dialog_connect(self, "_on_button_texture_selected")


func _on_button_texture_selected(path, target):
	DialogicUtil.update_setting('button_image', path)
	nodes['button_image'].text = DialogicUtil.get_filename_from_path(path)
