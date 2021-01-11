tool
extends Control

var editor_reference

# The amazing and revolutionary path system that magically works and you can't
# complain because "that is not how you are supposed to work". If there was only
# a way to set an id and then access that node via id...
# Here you have paths in all its glory. Praise the paths (っ´ω`c)♡
onready var n = {
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
	'button_text_color_enabled': $VBoxContainer/HBoxContainer2/ButtonStyle/GridContainer/HBoxContainer4/CheckBox2,
	'button_text_color': $VBoxContainer/HBoxContainer2/ButtonStyle/GridContainer/HBoxContainer4/ButtonTextColor,
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
	n['font_button'].text = DialogicUtil.get_filename_from_path(settings['theme_font'])
	
	# Text and shadows
	n['color_picker'].color = Color(settings['theme_text_color'])
	n['shadow_bool'].pressed = settings['theme_text_shadow']
	n['shadow_picker'].color = Color(settings['theme_text_shadow_color'])
	n['shadow_offset_x'].value = settings['theme_shadow_offset_x']
	n['shadow_offset_y'].value = settings['theme_shadow_offset_y']
	
	# Text speed
	n['text_speed'].value = settings['theme_text_speed']
		
	# Margin	
	n['text_offset_v'].value = settings['theme_text_margin']
	n['text_offset_h'].value = settings['theme_text_margin_h']
	
	# Backgrounds
	n['background_texture_button'].text = DialogicUtil.get_filename_from_path(settings['theme_background_image'])
	n['background_texture_button_visible'].pressed = settings['background_texture_button_visible']
	n['theme_background_color'].color = Color(settings['theme_background_color'])
	n['theme_background_color_visible'].pressed = settings['theme_background_color_visible']
	
	# Next image
	n['next_indicator_button'].text = DialogicUtil.get_filename_from_path(settings['theme_next_image'])

	# Action
	n['next_action_button'].text = settings['theme_action_key']
	
	# Buttons
	n['button_text_color_enabled'].pressed = settings['button_text_color_enabled']
	n['button_text_color'].color = Color(settings['button_text_color'])
	
	n['button_background'].color = Color(settings['button_background'])
	n['button_background_visible'].pressed = settings['button_background_visible']
	n['button_image'].text = DialogicUtil.get_filename_from_path(settings['button_image'])
	n['button_image_visible'].pressed = settings['button_image_visible']
	
	n['button_offset_x'].value = settings['button_offset_x']
	n['button_offset_y'].value = settings['button_offset_y']
	n['button_separation'].value = settings['button_separation']

	#Refreshing the dialog 
	_on_PreviewButton_pressed()

func _on_BackgroundTextureButton_pressed():
	editor_reference.godot_dialog("*.png")
	editor_reference.godot_dialog_connect(self, "_on_background_selected")


func _on_background_selected(path, target):
	DialogicUtil.update_setting('theme_background_image', path)
	n['background_texture_button'].text = DialogicUtil.get_filename_from_path(path)


func _on_NextIndicatorButton_pressed():
	editor_reference.godot_dialog("*.png")
	editor_reference.godot_dialog_connect(self, "_on_indicator_selected")


func _on_indicator_selected(path, target):
	DialogicUtil.update_setting('theme_next_image', path)
	n['next_indicator_button'].text = DialogicUtil.get_filename_from_path(path)


func _on_ColorPickerButton_color_changed(color):
	DialogicUtil.update_setting('theme_text_color', '#' + color.to_html())


func _on_ColorPickerButtonShadow_color_changed(color):
	DialogicUtil.update_setting('theme_text_shadow_color', '#' + color.to_html())


func _on_CheckBoxShadow_toggled(button_pressed):
	DialogicUtil.update_setting('theme_text_shadow', button_pressed)


func _on_ShadowOffset_value_changed(_value):
	DialogicUtil.update_setting('theme_shadow_offset_x', n['shadow_offset_x'].value)
	DialogicUtil.update_setting('theme_shadow_offset_y', n['shadow_offset_y'].value)


func _on_PreviewButton_pressed():
	for i in n['preview_panel'].get_children():
		i.free()
	var dialogic_node = load("res://addons/dialogic/Nodes/Dialog.tscn")
	var preview_dialog = dialogic_node.instance()
	preview_dialog.get_node('TextBubble/NextIndicator/AnimationPlayer').play('IDLE')
	preview_dialog.dialog_script['events'] = [{
		"character":"",
		"portrait":"",
		"text": n['text_preview'].text
	}]
	n['preview_panel'].add_child(preview_dialog)


func _on_ActionOptionButton_item_selected(index):
	DialogicUtil.update_setting('theme_action_key', n['next_action_button'].text)


func _on_ActionOptionButton_pressed():
	n['next_action_button'].clear()
	n['next_action_button'].add_item('[Select Action]')
	InputMap.load_from_globals()
	for a in InputMap.get_actions():
		n['next_action_button'].add_item(a)


func _on_FontButton_pressed():
	editor_reference.godot_dialog("*.tres")
	editor_reference.godot_dialog_connect(self, "_on_Font_selected")


func _on_Font_selected(path, target):
	DialogicUtil.update_setting('theme_font', path)
	n['font_button'].text = DialogicUtil.get_filename_from_path(path)


func _on_textSpeed_value_changed(value):
	DialogicUtil.update_setting('theme_text_speed', value)


func _on_TextMargin_value_changed(value):
	DialogicUtil.update_setting('theme_text_margin', value)


func _on_TextMarginH_value_changed(value):
	DialogicUtil.update_setting('theme_text_margin_h', value)


func _on_BackgroundColor_CheckBox_toggled(button_pressed):
	DialogicUtil.update_setting('theme_background_color_visible', button_pressed)


func _on_BackgroundColor_ColorPickerButton_color_changed(color):
	DialogicUtil.update_setting('theme_background_color', '#' + color.to_html())


func _on_BackgroundTexture_CheckBox_toggled(button_pressed):
	DialogicUtil.update_setting('background_texture_button_visible', button_pressed)


func _on_button_background_visible_toggled(button_pressed):
	DialogicUtil.update_setting('button_background_visible', button_pressed)


func _on_button_background_color_color_changed(color):
	DialogicUtil.update_setting('button_background', '#' + color.to_html())


func _on_ButtonOffset_value_changed(value):
	DialogicUtil.update_setting('button_offset_x', n['button_offset_x'].value)
	DialogicUtil.update_setting('button_offset_y', n['button_offset_y'].value)


func _on_VerticalSeparation_value_changed(value):
	DialogicUtil.update_setting('button_separation', n['button_separation'].value)


func _on_button_texture_toggled(button_pressed):
	DialogicUtil.update_setting('button_image_visible', button_pressed)


func _on_ButtonTextureButton_pressed():
	editor_reference.godot_dialog("*.png")
	editor_reference.godot_dialog_connect(self, "_on_button_texture_selected")


func _on_button_texture_selected(path, target):
	DialogicUtil.update_setting('button_image', path)
	n['button_image'].text = DialogicUtil.get_filename_from_path(path)


func _on_ButtonTextColor_color_changed(color):
	DialogicUtil.update_setting('button_text_color', '#' + color.to_html())


func _on_Custom_Button_Color_toggled(button_pressed):
	DialogicUtil.update_setting('button_text_color_enabled', button_pressed)
