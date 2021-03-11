tool
extends Control

var editor_reference
onready var master_tree = get_node('../MasterTree')
onready var settings_editor = get_node('../SettingsEditor')
var current_theme = ''

# The amazing and revolutionary path system that magically works and you can't
# complain because "that is not how you are supposed to work". If there was only
# a way to set an id and then access that node via id...
# Here you have paths in all its glory. Praise the paths (っ´ω`c)♡
onready var n = {
	# Text
	'theme_text_shadow': $VBoxContainer/HBoxContainer2/Text/GridContainer/HBoxContainer2/CheckBoxShadow,
	'theme_text_shadow_color': $VBoxContainer/HBoxContainer2/Text/GridContainer/HBoxContainer2/ColorPickerButtonShadow,
	'theme_text_color': $VBoxContainer/HBoxContainer2/Text/GridContainer/ColorPickerButton,
	'theme_font': $VBoxContainer/HBoxContainer2/Text/GridContainer/FontButton,
	'theme_shadow_offset_x': $VBoxContainer/HBoxContainer2/Text/GridContainer/HBoxContainer/ShadowOffsetX,
	'theme_shadow_offset_y': $VBoxContainer/HBoxContainer2/Text/GridContainer/HBoxContainer/ShadowOffsetY,
	'theme_text_speed': $VBoxContainer/HBoxContainer2/Text/GridContainer/TextSpeed,
	'alignment': $VBoxContainer/HBoxContainer2/Text/GridContainer/HBoxContainer3/Alignment,
	
	# Dialog box
	'background_texture_button_visible': $VBoxContainer/HBoxContainer2/DialogBox/GridContainer/HBoxContainer3/CheckBox,
	'theme_background_image': $VBoxContainer/HBoxContainer2/DialogBox/GridContainer/HBoxContainer3/BackgroundTextureButton,
	'theme_next_image': $VBoxContainer/HBoxContainer2/DialogBox/GridContainer/NextIndicatorButton,
	'theme_action_key': $VBoxContainer/HBoxContainer2/DialogBox/GridContainer/BoxContainer/ActionOptionButton,
	'theme_background_color_visible': $VBoxContainer/HBoxContainer2/DialogBox/GridContainer/HBoxContainer2/CheckBox,
	'theme_background_color': $VBoxContainer/HBoxContainer2/DialogBox/GridContainer/HBoxContainer2/ColorPickerButton,
	'theme_text_margin': $VBoxContainer/HBoxContainer2/DialogBox/GridContainer/HBoxContainer/TextOffsetV,
	'theme_text_margin_h': $VBoxContainer/HBoxContainer2/DialogBox/GridContainer/HBoxContainer/TextOffsetH,
	'size_w': $VBoxContainer/HBoxContainer2/DialogBox/GridContainer/HBoxContainer4/BoxSizeW,
	'size_h': $VBoxContainer/HBoxContainer2/DialogBox/GridContainer/HBoxContainer4/BoxSizeH, 
	
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
	
	# Glossary
	'glossary_font': $VBoxContainer/HBoxContainer2/Glossary/GridContainer/FontButton,
	'glossary_color': $VBoxContainer/HBoxContainer2/Glossary/GridContainer/ColorPickerButton,
	# Text preview
	'preview_panel': $VBoxContainer/Panel,
	'text_preview': $VBoxContainer/HBoxContainer3/TextEdit,
}

func _ready():
	# Signal connection to free up some memory
	connect("visibility_changed", self, "_on_visibility_changed")
	# Force preview update
	_on_visibility_changed()


func load_theme(filename):
	current_theme = filename
	var theme = DialogicUtil.get_theme(filename) 
	# Settings
	n['theme_action_key'].text = theme.get_value('settings', 'action_key', 'ui_accept')
	
	# Background
	n['theme_background_image'].text = DialogicUtil.get_filename_from_path(theme.get_value('background', 'image', 'res://addons/dialogic/Images/background/background-2.png'))
	n['background_texture_button_visible'].pressed = theme.get_value('background', 'use_image', true)
	n['theme_background_color'].color = Color(theme.get_value('background', 'color', '#ff000000'))
	n['theme_background_color_visible'].pressed = theme.get_value('background', 'use_color', false)
	n['theme_next_image'].text = DialogicUtil.get_filename_from_path(theme.get_value('next_indicator', 'image', 'res://addons/dialogic/Images/next-indicator.png'))
	
	var size_value = theme.get_value('box', 'size', Vector2(910, 167))
	n['size_w'].value = size_value.x
	n['size_h'].value = size_value.y
	
	# Buttons
	n['button_text_color_enabled'].pressed = theme.get_value('buttons', 'text_color_enabled', true)
	n['button_text_color'].color = Color(theme.get_value('buttons', 'text_color', "#ffffffff"))
	n['button_background'].color = Color(theme.get_value('buttons', 'background_color', "#ff000000"))
	n['button_background_visible'].pressed = theme.get_value('buttons', 'use_background_color', false)
	n['button_image'].text = DialogicUtil.get_filename_from_path(theme.get_value('buttons', 'image', 'res://addons/dialogic/Images/background/background-2.png'))
	n['button_image_visible'].pressed = theme.get_value('buttons', 'use_image', true)
	n['button_offset_x'].value = theme.get_value('buttons', 'padding', Vector2(5,5)).x
	n['button_offset_y'].value = theme.get_value('buttons', 'padding', Vector2(5,5)).y
	n['button_separation'].value = theme.get_value('buttons', 'gap', 5)
	
	# Definitions
	n['glossary_color'].color = Color(theme.get_value('definitions', 'color', "#ffffffff"))
	n['glossary_font'].text = DialogicUtil.get_filename_from_path(theme.get_value('definitions', 'font', "res://addons/dialogic/Fonts/GlossaryFont.tres"))
	
	# Text
	n['theme_text_speed'].value = theme.get_value('text','speed', 2)
	n['theme_font'].text = DialogicUtil.get_filename_from_path(theme.get_value('text', 'font', 'res://addons/dialogic/Fonts/DefaultFont.tres'))
	n['theme_text_color'].color = Color(theme.get_value('text', 'color', '#ffffffff'))
	n['theme_text_shadow'].pressed = theme.get_value('text', 'shadow', false)
	n['theme_text_shadow_color'].color = Color(theme.get_value('text', 'shadow_color', '#9e000000'))
	n['theme_shadow_offset_x'].value = theme.get_value('text', 'shadow_offset', Vector2(2,2)).x
	n['theme_shadow_offset_y'].value = theme.get_value('text', 'shadow_offset', Vector2(2,2)).y
	n['theme_text_margin'].value = theme.get_value('text', 'margin', Vector2(20, 10)).x
	n['theme_text_margin_h'].value = theme.get_value('text', 'margin', Vector2(20, 10)).y
	n['alignment'].text = theme.get_value('text', 'alignment', 'Left')
	match n['alignment'].text:
		'Left':
			n['alignment'].select(0)
		'Center':
			n['alignment'].select(1)
		'Right':
			n['alignment'].select(2)


func new_theme():
	var theme_file = 'theme-' + str(OS.get_unix_time()) + '.cfg'
	DialogicUtil.create_empty_file(DialogicUtil.get_path('THEME_DIR', theme_file))
	master_tree.add_theme({'file': theme_file, 'name': theme_file})
	load_theme(theme_file)
	# Check if it is the only theme to set as default
	if DialogicUtil.get_theme_list().size() == 1:
		print('only theme, setting as default')
		settings_editor.set_value('theme', 'default', theme_file)


func _on_BackgroundTextureButton_pressed():
	editor_reference.godot_dialog("*.png")
	editor_reference.godot_dialog_connect(self, "_on_background_selected")


func _on_background_selected(path, target):
	DialogicUtil.set_theme_value(current_theme, 'background','image', path)
	n['theme_background_image'].text = DialogicUtil.get_filename_from_path(path)


func _on_NextIndicatorButton_pressed():
	editor_reference.godot_dialog("*.png")
	editor_reference.godot_dialog_connect(self, "_on_indicator_selected")


func _on_indicator_selected(path, target):
	DialogicUtil.set_theme_value(current_theme, 'next_indicator','image', path)
	n['theme_next_image'].text = DialogicUtil.get_filename_from_path(path)


func _on_ColorPickerButton_color_changed(color):
	DialogicUtil.set_theme_value(current_theme, 'text','color', '#' + color.to_html())


func _on_ColorPickerButtonShadow_color_changed(color):
	DialogicUtil.set_theme_value(current_theme, 'text','shadow_color', '#' + color.to_html())


func _on_CheckBoxShadow_toggled(button_pressed):
	DialogicUtil.set_theme_value(current_theme, 'text','shadow', button_pressed)


func _on_ShadowOffset_value_changed(_value):
	DialogicUtil.set_theme_value(current_theme, 'text','shadow_offset', Vector2(n['theme_shadow_offset_x'].value,n['theme_shadow_offset_y'].value))


func _on_PreviewButton_pressed():
	for i in n['preview_panel'].get_children():
		i.free()
	var dialogic_node = load("res://addons/dialogic/Dialog.tscn")
	var preview_dialog = dialogic_node.instance()
	var glossary = DialogicUtil.load_glossary()
	#preview_dialog.glossary = glossary
	preview_dialog.preview = true
	preview_dialog.get_node('GlossaryInfo').in_theme_editor = true
	preview_dialog.get_node('TextBubble/NextIndicator/AnimationPlayer').play('IDLE')
	preview_dialog.dialog_script['events'] = [{
		"character":"",
		"portrait":"",
		"text": n['text_preview'].text
	}]
	# Settings
	preview_dialog.settings = DialogicUtil.get_settings()
	# Alignment
	preview_dialog.current_theme = preview_dialog.load_theme(current_theme)
	preview_dialog.dialog_script = preview_dialog.parse_glossary(preview_dialog.dialog_script)
	preview_dialog.dialog_script = preview_dialog.parse_text_lines(preview_dialog.dialog_script)
	n['preview_panel'].add_child(preview_dialog)
	# Not sure why but I need to reload the theme again for it to work properly
	preview_dialog.current_theme = preview_dialog.load_theme(current_theme)
	
	# maintaining the preview panel big enough for the dialog box
	n['preview_panel'].rect_min_size.y = preview_dialog.current_theme.get_value('box', 'size', Vector2(910, 167)).y + 90


func _on_ActionOptionButton_item_selected(index):
	DialogicUtil.set_theme_value(current_theme, 'settings','action_key', n['theme_action_key'].text)


func _on_ActionOptionButton_pressed():
	n['theme_action_key'].clear()
	n['theme_action_key'].add_item('[Select Action]')
	InputMap.load_from_globals()
	for a in InputMap.get_actions():
		n['theme_action_key'].add_item(a)


func _on_FontButton_pressed():
	editor_reference.godot_dialog("*.tres")
	editor_reference.godot_dialog_connect(self, "_on_Font_selected")


func _on_Font_selected(path, target):
	DialogicUtil.set_theme_value(current_theme, 'text','font', path)
	n['theme_font'].text = DialogicUtil.get_filename_from_path(path)


func _on_textSpeed_value_changed(value):
	DialogicUtil.set_theme_value(current_theme, 'text','speed', value)


func _on_TextMargin_value_changed(value):
	var final_vector = Vector2(
		n['theme_text_margin'].value,
		n['theme_text_margin_h'].value
	)
	DialogicUtil.set_theme_value(current_theme, 'text', 'margin', final_vector)


func _on_BackgroundColor_CheckBox_toggled(button_pressed):
	DialogicUtil.set_theme_value(current_theme, 'background', 'use_color', button_pressed)


func _on_BackgroundColor_ColorPickerButton_color_changed(color):
	DialogicUtil.set_theme_value(current_theme, 'background', 'color', '#' + color.to_html())


func _on_BackgroundTexture_CheckBox_toggled(button_pressed):
	DialogicUtil.set_theme_value(current_theme, 'background', 'use_image', button_pressed)


func _on_button_background_visible_toggled(button_pressed):
	DialogicUtil.set_theme_value(current_theme, 'buttons', 'use_background_color', button_pressed)


func _on_button_background_color_color_changed(color):
	DialogicUtil.set_theme_value(current_theme, 'buttons', 'background_color', '#' + color.to_html())


func _on_ButtonOffset_value_changed(value):
	var final_vector = Vector2(
		n['button_offset_x'].value,
		n['button_offset_y'].value
	)
	DialogicUtil.set_theme_value(current_theme, 'buttons', 'padding', final_vector)


func _on_VerticalSeparation_value_changed(value):
	DialogicUtil.set_theme_value(current_theme, 'buttons', 'gap', n['button_separation'].value)


func _on_button_texture_toggled(button_pressed):
	DialogicUtil.set_theme_value(current_theme, 'buttons', 'use_image', button_pressed)


func _on_ButtonTextureButton_pressed():
	editor_reference.godot_dialog("*.png")
	editor_reference.godot_dialog_connect(self, "_on_button_texture_selected")


func _on_button_texture_selected(path, target):
	DialogicUtil.set_theme_value(current_theme, 'buttons', 'image', path)
	n['button_image'].text = DialogicUtil.get_filename_from_path(path)


func _on_ButtonTextColor_color_changed(color):
	DialogicUtil.set_theme_value(current_theme, 'buttons', 'text_color', '#' + color.to_html())


func _on_Custom_Button_Color_toggled(button_pressed):
	DialogicUtil.set_theme_value(current_theme, 'buttons', 'text_color_enabled', button_pressed)


func _on_GlossaryColorPicker_color_changed(color):
	DialogicUtil.set_theme_value(current_theme, 'definitions', 'color', '#' + color.to_html())


func _on_GlossaryFontButton_pressed():
	editor_reference.godot_dialog("*.tres")
	editor_reference.godot_dialog_connect(self, "_on_Glossary_Font_selected")

func _on_Glossary_Font_selected(path, target):
	DialogicUtil.set_theme_value(current_theme, 'definitions', 'font', path)
	n['glossary_font'].text = DialogicUtil.get_filename_from_path(path)


func _on_visibility_changed():
	if visible:
		# Refreshing the dialog 
		_on_PreviewButton_pressed()
	else:
		# Erasing all previews since them keeps working
		# on background
		for i in n['preview_panel'].get_children():
			i.queue_free()


func _on_BoxSize_value_changed(value):
	var size_value = Vector2(n['size_w'].value, n['size_h'].value)
	DialogicUtil.set_theme_value(current_theme, 'box', 'size', size_value)


func _on_Alignment_item_selected(index):
	if index == 0:
		DialogicUtil.set_theme_value(current_theme, 'text', 'alignment', 'Left')
	elif index == 1:
		DialogicUtil.set_theme_value(current_theme, 'text', 'alignment', 'Center')
	elif index == 2:
		DialogicUtil.set_theme_value(current_theme, 'text', 'alignment', 'Right')
