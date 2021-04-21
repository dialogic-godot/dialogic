tool
extends Control

var editor_reference
onready var master_tree = get_node('../MasterTreeContainer/MasterTree')
onready var settings_editor = get_node('../SettingsEditor')
var current_theme : String = ''

var use_advanced_themes := false

# When loading the variables to the input fields in the 
# load_theme function, every element thinks the value was updated
# so it has to perform a "saving" of that property. 
# The loading variable is a way to check if the values should be saved
# or not.
var loading : bool = true 

# The amazing and revolutionary path system that magically works and you can't
# complain because "that is not how you are supposed to work". If there was only
# a way to set an id and then access that node via id...
# Here you have paths in all its glory. Praise the paths (っ´ω`c)♡

onready var advanced_containers := {
	'buttons' : {
		'container': $"VBoxContainer/TabContainer/Choice Buttons/Column3/GridContainer",
		'disabled_text': $"VBoxContainer/TabContainer/Choice Buttons/Column3/Label"
	}
}

onready var n : Dictionary = {
	# Dialog Text
	'theme_text_shadow': $"VBoxContainer/TabContainer/Dialog Text/Column/GridContainer/HBoxContainer2/CheckBoxShadow",
	'theme_text_shadow_color': $"VBoxContainer/TabContainer/Dialog Text/Column/GridContainer/HBoxContainer2/ColorPickerButtonShadow",
	'theme_text_color': $"VBoxContainer/TabContainer/Dialog Text/Column/GridContainer/ColorPickerButton",
	'theme_font': $"VBoxContainer/TabContainer/Dialog Text/Column/GridContainer/FontButton",
	'theme_shadow_offset_x': $"VBoxContainer/TabContainer/Dialog Text/Column/GridContainer/HBoxContainer/ShadowOffsetX",
	'theme_shadow_offset_y': $"VBoxContainer/TabContainer/Dialog Text/Column/GridContainer/HBoxContainer/ShadowOffsetY",
	'theme_text_speed': $"VBoxContainer/TabContainer/Dialog Text/Column2/GridContainer/TextSpeed",
	'alignment': $"VBoxContainer/TabContainer/Dialog Text/Column/GridContainer/HBoxContainer3/Alignment",
	
	# Dialog box
	'background_texture_button_visible': $"VBoxContainer/TabContainer/Dialog Box/Column/GridContainer/HBoxContainer3/CheckBox",
	'theme_background_image': $"VBoxContainer/TabContainer/Dialog Box/Column/GridContainer/HBoxContainer3/BackgroundTextureButton",
	'theme_next_image': $"VBoxContainer/TabContainer/Dialog Box/Column2/GridContainer/NextIndicatorButton",
	'next_indicator_scale': $"VBoxContainer/TabContainer/Dialog Box/Column2/GridContainer/HBoxContainer7/IndicatorScale",
	'next_indicator_offset_x': $"VBoxContainer/TabContainer/Dialog Box/Column2/GridContainer/HBoxContainer2/NextOffsetX",
	'next_indicator_offset_y': $"VBoxContainer/TabContainer/Dialog Box/Column2/GridContainer/HBoxContainer2/NextOffsetY",
	'next_animation': $"VBoxContainer/TabContainer/Dialog Box/Column2/GridContainer/NextAnimation",
	'theme_action_key': $"VBoxContainer/TabContainer/Dialog Box/Column3/GridContainer/BoxContainer/ActionOptionButton",
	'theme_background_color_visible': $"VBoxContainer/TabContainer/Dialog Box/Column/GridContainer/HBoxContainer2/CheckBox",
	'theme_background_color': $"VBoxContainer/TabContainer/Dialog Box/Column/GridContainer/HBoxContainer2/ColorPickerButton",
	'theme_text_margin': $"VBoxContainer/TabContainer/Dialog Box/Column/GridContainer/HBoxContainer/TextOffsetV",
	'theme_text_margin_h': $"VBoxContainer/TabContainer/Dialog Box/Column/GridContainer/HBoxContainer/TextOffsetH",
	'size_w': $"VBoxContainer/TabContainer/Dialog Box/Column/GridContainer/HBoxContainer4/BoxSizeW",
	'size_h': $"VBoxContainer/TabContainer/Dialog Box/Column/GridContainer/HBoxContainer4/BoxSizeH", 
	'bottom_gap': $"VBoxContainer/TabContainer/Dialog Box/Column/GridContainer/HBoxContainer5/BottomGap",
	'background_modulation': $"VBoxContainer/TabContainer/Dialog Box/Column/GridContainer/HBoxContainer6/CheckBox",
	'background_modulation_color': $"VBoxContainer/TabContainer/Dialog Box/Column/GridContainer/HBoxContainer6/ColorPickerButton",
	
	# Character Names
	'name_auto_color': $"VBoxContainer/TabContainer/Name Label/Column/GridContainer/CharacterColor",
	'name_background_visible': $"VBoxContainer/TabContainer/Name Label/Column2/GridContainer/HBoxContainer2/CheckBox",
	'name_background': $"VBoxContainer/TabContainer/Name Label/Column2/GridContainer/HBoxContainer2/ColorPickerButton",
	'name_image': $"VBoxContainer/TabContainer/Name Label/Column2/GridContainer/HBoxContainer3/BackgroundTextureButton",
	'name_image_visible': $"VBoxContainer/TabContainer/Name Label/Column2/GridContainer/HBoxContainer3/CheckBox",
	'name_shadow': $"VBoxContainer/TabContainer/Name Label/Column/GridContainer/HBoxContainer4/ColorPickerButtonShadow",
	'name_shadow_visible': $"VBoxContainer/TabContainer/Name Label/Column/GridContainer/HBoxContainer4/CheckBoxShadow",
	'name_shadow_offset_x': $"VBoxContainer/TabContainer/Name Label/Column/GridContainer/HBoxContainer/ShadowOffsetX",
	'name_shadow_offset_y': $"VBoxContainer/TabContainer/Name Label/Column/GridContainer/HBoxContainer/ShadowOffsetY",
	'name_bottom_gap': $"VBoxContainer/TabContainer/Name Label/Column3/GridContainer/HBoxContainer5/BottomGap",
	'name_background_modulation': $"VBoxContainer/TabContainer/Name Label/Column2/GridContainer/HBoxContainer6/CheckBox",
	'name_background_modulation_color': $"VBoxContainer/TabContainer/Name Label/Column2/GridContainer/HBoxContainer6/ColorPickerButton",
	
	# Choice Buttons
	'button_text_color_enabled': $"VBoxContainer/TabContainer/Choice Buttons/Column/GridContainer/HBoxContainer4/CheckBox2",
	'button_text_color': $"VBoxContainer/TabContainer/Choice Buttons/Column/GridContainer/HBoxContainer4/ButtonTextColor",
	'button_background': $"VBoxContainer/TabContainer/Choice Buttons/Column/GridContainer/HBoxContainer2/ColorPickerButton",
	'button_background_visible': $"VBoxContainer/TabContainer/Choice Buttons/Column/GridContainer/HBoxContainer2/CheckBox",
	'button_image': $"VBoxContainer/TabContainer/Choice Buttons/Column/GridContainer/HBoxContainer3/BackgroundTextureButton",
	'button_image_visible': $"VBoxContainer/TabContainer/Choice Buttons/Column/GridContainer/HBoxContainer3/CheckBox",
	'button_modulation': $"VBoxContainer/TabContainer/Choice Buttons/Column/GridContainer/HBoxContainer6/CheckBox",
	'button_modulation_color': $"VBoxContainer/TabContainer/Choice Buttons/Column/GridContainer/HBoxContainer6/ColorPickerButton",
	'button_use_native': $"VBoxContainer/TabContainer/Choice Buttons/Column/GridContainer/CheckBox",
	'button_use_custom': $"VBoxContainer/TabContainer/Choice Buttons/Column3/GridContainer/HBoxContainer5/CustomButtonsCheckBox",
	'button_custom_path': $"VBoxContainer/TabContainer/Choice Buttons/Column3/GridContainer/HBoxContainer5/CustomButtonsButton",
	'button_offset_x': $"VBoxContainer/TabContainer/Choice Buttons/Column2/GridContainer/HBoxContainer/TextOffsetH",
	'button_offset_y': $"VBoxContainer/TabContainer/Choice Buttons/Column2/GridContainer/HBoxContainer/TextOffsetV",
	'button_separation': $"VBoxContainer/TabContainer/Choice Buttons/Column2/GridContainer/VerticalSeparation",
	
	'button_fixed': $"VBoxContainer/TabContainer/Choice Buttons/Column2/GridContainer/HBoxContainer2/FixedSize",
	'button_fixed_x': $"VBoxContainer/TabContainer/Choice Buttons/Column2/GridContainer/HBoxContainer2/ButtonSizeX",
	'button_fixed_y': $"VBoxContainer/TabContainer/Choice Buttons/Column2/GridContainer/HBoxContainer2/ButtonSizeY",
	
	# Glossary
	'glossary_font': $VBoxContainer/TabContainer/Glossary/Column/GridContainer/FontButton,
	'glossary_color': $VBoxContainer/TabContainer/Glossary/Column/GridContainer/ColorPickerButton,
	'glossary_enabled': $VBoxContainer/TabContainer/Glossary/Column/GridContainer/ShowGlossaryCheckBox,
	
	# Text preview
	'text_preview': $VBoxContainer/HBoxContainer3/TextEdit,
	
}

func _ready() -> void:
	# Signal connection to free up some memory
	connect("visibility_changed", self, "_on_visibility_changed")
	if get_constant("dark_theme", "Editor"):
		$VBoxContainer/HBoxContainer3/PreviewButton.icon = load("res://addons/dialogic/Images/Plugin/plugin-editor-icon-dark-theme.svg")
	else:
		$VBoxContainer/HBoxContainer3/PreviewButton.icon = load("res://addons/dialogic/Images/Plugin/plugin-editor-icon-light-theme.svg")
	
	$DelayPreviewTimer.one_shot = true
	$DelayPreviewTimer.connect("timeout", self, '_on_DelayPreview_timer_timeout')
	
	var title_style = $"VBoxContainer/TabContainer/Dialog Text/Column/SectionTitle".get('custom_styles/normal')
	title_style.set('bg_color', get_color("prop_category", "Editor"))
	# Force preview update
	_on_visibility_changed()


func setup_advanced_containers():
	use_advanced_themes = DialogicResources.get_settings_config().get_value('dialog', 'advanced_themes', false)
	
	for key in advanced_containers:
		var c = advanced_containers[key]
		if use_advanced_themes:
			c["container"].show()
			c["disabled_text"].hide()
		else:
			c["container"].hide()
			c["disabled_text"].show()


func load_theme(filename):
	loading = true
	current_theme = filename
	var theme = DialogicResources.get_theme_config(filename)
	setup_advanced_containers()
	# Settings
	n['theme_action_key'].text = theme.get_value('settings', 'action_key', 'ui_accept')
	
	# Background
	n['theme_background_image'].text = DialogicResources.get_filename_from_path(theme.get_value('background', 'image', 'res://addons/dialogic/Example Assets/backgrounds/background-2.png'))
	n['background_texture_button_visible'].pressed = theme.get_value('background', 'use_image', true)
	n['theme_background_color'].color = Color(theme.get_value('background', 'color', '#ff000000'))
	n['theme_background_color_visible'].pressed = theme.get_value('background', 'use_color', false)
	n['theme_next_image'].text = DialogicResources.get_filename_from_path(theme.get_value('next_indicator', 'image', 'res://addons/dialogic/Example Assets/next-indicator/next-indicator.png'))
	n['next_indicator_scale'].value = theme.get_value('next_indicator', 'scale', 0.4)
	var next_indicator_offset = theme.get_value('next_indicator', 'offset', Vector2(13,10))
	n['next_indicator_offset_x'].value = next_indicator_offset.x
	n['next_indicator_offset_y'].value = next_indicator_offset.y

	n['background_modulation'].pressed = theme.get_value('background', 'modulation', false)
	n['background_modulation_color'].color = Color(theme.get_value('background', 'modulation_color', '#ffffffff'))
	
	
	var size_value = theme.get_value('box', 'size', Vector2(910, 167))
	n['size_w'].value = size_value.x
	n['size_h'].value = size_value.y
	
	n['bottom_gap'].value = theme.get_value('box', 'bottom_gap', 40)
	
	# Buttons
	n['button_text_color_enabled'].pressed = theme.get_value('buttons', 'text_color_enabled', true)
	n['button_text_color'].color = Color(theme.get_value('buttons', 'text_color', "#ffffffff"))
	n['button_background'].color = Color(theme.get_value('buttons', 'background_color', "#ff000000"))
	n['button_background_visible'].pressed = theme.get_value('buttons', 'use_background_color', false)
	n['button_image'].text = DialogicResources.get_filename_from_path(theme.get_value('buttons', 'image', 'res://addons/dialogic/Example Assets/backgrounds/background-2.png'))
	n['button_image_visible'].pressed = theme.get_value('buttons', 'use_image', true)
	n['button_use_native'].pressed = theme.get_value('buttons', 'use_native', false)
	n['button_use_custom'].pressed = theme.get_value('buttons', 'use_custom', false)
	n['button_custom_path'].text = DialogicResources.get_filename_from_path(theme.get_value('buttons', 'custom_path', ""))
	n['button_offset_x'].value = theme.get_value('buttons', 'padding', Vector2(5,5)).x
	n['button_offset_y'].value = theme.get_value('buttons', 'padding', Vector2(5,5)).y
	n['button_separation'].value = theme.get_value('buttons', 'gap', 5)
	n['button_modulation'].pressed = theme.get_value('buttons', 'modulation', false)
	n['button_modulation_color'].color = Color(theme.get_value('buttons', 'modulation_color', '#ffffffff'))
	n['button_fixed'].pressed = theme.get_value('buttons', 'fixed', false)
	n['button_fixed_x'].value = theme.get_value('buttons', 'fixed_size', Vector2(130,40)).x
	n['button_fixed_y'].value = theme.get_value('buttons', 'fixed_size', Vector2(130,40)).y
	
	toggle_button_customization_fields(theme.get_value('buttons', 'use_native', false), theme.get_value('buttons', 'use_custom', false))
	
	# Definitions
	n['glossary_color'].color = Color(theme.get_value('definitions', 'color', "#ffffffff"))
	n['glossary_font'].text = DialogicResources.get_filename_from_path(theme.get_value('definitions', 'font', "res://addons/dialogic/Example Assets/Fonts/GlossaryFont.tres"))
	n['glossary_enabled'].pressed = theme.get_value('definitions', 'show_glossary', true)
	
	# Text
	n['theme_text_speed'].value = theme.get_value('text','speed', 2)
	n['theme_font'].text = DialogicResources.get_filename_from_path(theme.get_value('text', 'font', 'res://addons/dialogic/Example Assets/Fonts/DefaultFont.tres'))
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
	
	
	# Name
	n['name_auto_color'].pressed = theme.get_value('name', 'auto_color', true)
	n['name_background_visible'].pressed = theme.get_value('name', 'background_visible', false)
	n['name_background'].color = Color(theme.get_value('name', 'background', "#ff000000"))
	n['name_image_visible'].pressed = theme.get_value('name', 'image_visible', false)

	n['name_image'].text = DialogicResources.get_filename_from_path(theme.get_value('name', 'image', 'res://addons/dialogic/Example Assets/backgrounds/background-2.png'))
	n['name_background_modulation'].pressed = theme.get_value('name', 'modulation', false)
	n['name_background_modulation_color'].color = Color(theme.get_value('name', 'modulation_color', '#ffffffff'))

	
	
	n['name_shadow'].color = Color(theme.get_value('name', 'shadow', "#9e000000"))
	n['name_shadow_visible'].pressed = theme.get_value('name', 'shadow_visible', true)
	n['name_shadow_offset_x'].value = theme.get_value('name', 'shadow_offset', Vector2(2,2)).x
	n['name_shadow_offset_y'].value = theme.get_value('name', 'shadow_offset', Vector2(2,2)).y
	n['name_bottom_gap'].value = theme.get_value('name', 'bottom_gap', 48)
	
	
	# Next indicator animations
	var animations = ['Up and down', 'Pulse', 'Static'] # TODO: dynamically get all the animations from the Dialog.tscn NextIndicator
	n['next_animation'].clear()
	var next_animation_selected = theme.get_value('next_indicator', 'animation', 'Up and down')
	var nix = 0
	for a in animations:
		n['next_animation'].add_item(a)
		if a == next_animation_selected:
			n['next_animation'].select(nix)
		nix += 1
	
	# Preview text
	n['text_preview'].text = theme.get_value('text', 'preview', 'This is preview text. You can use  [color=#A5EFAC]BBCode[/color] to style it.\n[wave amp=50 freq=2]You can even use effects![/wave]')
	
	# Finished loading
	loading = false
	# Updating the preview
	_on_PreviewButton_pressed()


func new_theme() -> void:
	var theme_file : String = 'theme-' + str(OS.get_unix_time()) + '.cfg'
	DialogicResources.add_theme(theme_file)
	master_tree.build_themes(theme_file)
	load_theme(theme_file)
	# Check if it is the only theme to set as default
	if DialogicUtil.get_theme_list().size() == 1:
		#print('only theme, setting as default')
		settings_editor.set_value('theme', 'default', theme_file)


func duplicate_theme(from_filename) -> void:
	var duplicate_theme : String = 'theme-' + str(OS.get_unix_time()) + '.cfg'
	DialogicResources.duplicate_theme(from_filename, duplicate_theme)
	DialogicResources.set_theme_value(duplicate_theme, 'settings', 'name', duplicate_theme)
	master_tree.build_themes(duplicate_theme)
	load_theme(duplicate_theme)
	

func _on_BackgroundTextureButton_pressed() -> void:
	editor_reference.godot_dialog("*.png")
	editor_reference.godot_dialog_connect(self, "_on_background_selected")


func _on_background_selected(path, target) -> void:
	if loading:
		return
	DialogicResources.set_theme_value(current_theme, 'background','image', path)
	n['theme_background_image'].text = DialogicResources.get_filename_from_path(path)
	_on_PreviewButton_pressed() # Refreshing the preview


func _on_NextIndicatorButton_pressed() -> void:
	editor_reference.godot_dialog("*.png")
	editor_reference.godot_dialog_connect(self, "_on_indicator_selected")


func _on_indicator_selected(path, target) -> void:
	if loading:
		return
	DialogicResources.set_theme_value(current_theme, 'next_indicator','image', path)
	n['theme_next_image'].text = DialogicResources.get_filename_from_path(path)
	# Since people will probably want the sprite on fresh values and the default
	# ones are for the custom dialogic theme, I reset the next indicator properties
	# here so they can set the scale and offset they want.
	DialogicResources.set_theme_value(current_theme, 'next_indicator', 'scale', 1)
	DialogicResources.set_theme_value(current_theme, 'offset', 'scale', Vector2(10,10))
	n['next_indicator_scale'].value = 1
	n['next_indicator_offset_x'].value = 10
	n['next_indicator_offset_y'].value = 10
	_on_PreviewButton_pressed() # Refreshing the preview


func _on_NextAnimation_item_selected(index) -> void:
	DialogicResources.set_theme_value(current_theme, 'next_indicator', 'animation', n['next_animation'].get_item_text(index))
	_on_PreviewButton_pressed() # Refreshing the preview


func _on_ColorPickerButton_color_changed(color) -> void:
	if loading:
		return
	DialogicResources.set_theme_value(current_theme, 'text','color', '#' + color.to_html())
	$DelayPreviewTimer.start(0.5) # Calling a timer so the update doesn't get triggered many times


func _on_ColorPickerButtonShadow_color_changed(color) -> void:
	if loading:
		return
	DialogicResources.set_theme_value(current_theme, 'text','shadow_color', '#' + color.to_html())
	$DelayPreviewTimer.start(0.5) # Calling a timer so the update doesn't get triggered many times


func _on_CheckBoxShadow_toggled(button_pressed) -> void:
	if loading:
		return
	DialogicResources.set_theme_value(current_theme, 'text','shadow', button_pressed)
	_on_PreviewButton_pressed() # Refreshing the preview


func _on_ShadowOffset_value_changed(_value) -> void:
	if loading:
		return
	DialogicResources.set_theme_value(current_theme, 'text','shadow_offset', Vector2(n['theme_shadow_offset_x'].value,n['theme_shadow_offset_y'].value))
	_on_PreviewButton_pressed() # Refreshing the preview


func _on_PreviewButton_pressed() -> void:
	for i in $VBoxContainer/Panel.get_children():
		i.free()
	var characters : Array = DialogicUtil.get_character_list()
	var character_file : String = ''
	var preview_dialog = Dialogic.start('')
	preview_dialog.preview = true
	if characters.size():
		characters.shuffle()
		character_file = characters[0]['file']
	preview_dialog.dialog_script = {
			"events":[
				{ "set_theme": current_theme },
				{ "character": character_file, "portrait":"", "text":n['text_preview'].text }
			]
		}
	preview_dialog.parse_characters(preview_dialog.dialog_script)
	$VBoxContainer/Panel.add_child(preview_dialog)
	
	# maintaining the preview panel big enough for the dialog box
	var box_size = preview_dialog.current_theme.get_value('box', 'size', Vector2(910, 167)).y
	var bottom_gap = preview_dialog.current_theme.get_value('box', 'bottom_gap', 40)
	var extra = 90
	$VBoxContainer/Panel.rect_min_size.y = box_size + extra + bottom_gap
	$VBoxContainer/Panel.rect_size.y = 0
	preview_dialog.call_deferred('resize_main')


func _on_ActionOptionButton_item_selected(index) -> void:
	if loading:
		return
	DialogicResources.set_theme_value(current_theme, 'settings','action_key', n['theme_action_key'].text)


func _on_ActionOptionButton_pressed() -> void:
	n['theme_action_key'].clear()
	n['theme_action_key'].add_item('[Select Action]')
	InputMap.load_from_globals()
	for a in InputMap.get_actions():
		n['theme_action_key'].add_item(a)


func _on_FontButton_pressed() -> void:
	editor_reference.godot_dialog("*.tres")
	editor_reference.godot_dialog_connect(self, "_on_Font_selected")


func _on_Font_selected(path, target) -> void:
	if loading:
		return
	DialogicResources.set_theme_value(current_theme, 'text','font', path)
	n['theme_font'].text = DialogicResources.get_filename_from_path(path)
	_on_PreviewButton_pressed() # Refreshing the preview


func _on_textSpeed_value_changed(value) -> void:
	if loading:
		return
	DialogicResources.set_theme_value(current_theme, 'text','speed', value)
	_on_PreviewButton_pressed() # Refreshing the preview


func _on_TextMargin_value_changed(value) -> void:
	if loading:
		return
	var final_vector = Vector2(
		n['theme_text_margin'].value,
		n['theme_text_margin_h'].value
	)
	DialogicResources.set_theme_value(current_theme, 'text', 'margin', final_vector)
	_on_PreviewButton_pressed() # Refreshing the preview


func _on_BackgroundColor_CheckBox_toggled(button_pressed) -> void:
	if loading:
		return
	DialogicResources.set_theme_value(current_theme, 'background', 'use_color', button_pressed)
	_on_PreviewButton_pressed() # Refreshing the preview


func _on_BackgroundColor_ColorPickerButton_color_changed(color) -> void:
	if loading:
		return
	DialogicResources.set_theme_value(current_theme, 'background', 'color', '#' + color.to_html())
	$DelayPreviewTimer.start(0.5) # Calling a timer so the update doesn't get triggered many times


func _on_BackgroundTexture_CheckBox_toggled(button_pressed) -> void:
	if loading:
		return
	DialogicResources.set_theme_value(current_theme, 'background', 'use_image', button_pressed)
	_on_PreviewButton_pressed() # Refreshing the preview
	

func _on_button_background_visible_toggled(button_pressed) -> void:
	if loading:
		return
	DialogicResources.set_theme_value(current_theme, 'buttons', 'use_background_color', button_pressed)


func _on_button_background_color_color_changed(color) -> void:
	if loading:
		return
	DialogicResources.set_theme_value(current_theme, 'buttons', 'background_color', '#' + color.to_html())
	$DelayPreviewTimer.start(0.5) # Calling a timer so the update doesn't get triggered many times


func _on_ButtonOffset_value_changed(value) -> void:
	if loading:
		return
	var final_vector = Vector2(
		n['button_offset_x'].value,
		n['button_offset_y'].value
	)
	DialogicResources.set_theme_value(current_theme, 'buttons', 'padding', final_vector)


func _on_VerticalSeparation_value_changed(value) -> void:
	if loading:
		return
	DialogicResources.set_theme_value(current_theme, 'buttons', 'gap', n['button_separation'].value)


func _on_button_texture_toggled(button_pressed) -> void:
	if loading:
		return
	DialogicResources.set_theme_value(current_theme, 'buttons', 'use_image', button_pressed)


func _on_ButtonTextureButton_pressed() -> void:
	editor_reference.godot_dialog("*.png")
	editor_reference.godot_dialog_connect(self, "_on_button_texture_selected")


func _on_button_texture_selected(path, target) -> void:
	if loading:
		return
	DialogicResources.set_theme_value(current_theme, 'buttons', 'image', path)
	n['button_image'].text = DialogicResources.get_filename_from_path(path)


func _on_ButtonTextColor_color_changed(color) -> void:
	if loading:
		return
	DialogicResources.set_theme_value(current_theme, 'buttons', 'text_color', '#' + color.to_html())
	$DelayPreviewTimer.start(0.5) # Calling a timer so the update doesn't get triggered many times


func _on_Custom_Button_Color_toggled(button_pressed) -> void:
	if loading:
		return
	DialogicResources.set_theme_value(current_theme, 'buttons', 'text_color_enabled', button_pressed)


func _on_native_button_toggled(button_pressed) -> void:
	if loading:
		return
	DialogicResources.set_theme_value(current_theme, 'buttons', 'use_native', button_pressed)
	toggle_button_customization_fields(button_pressed, false)


func toggle_button_customization_fields(native_enabled: bool, custom_enabled: bool) -> void:
	var customization_disabled = native_enabled or custom_enabled
	n['button_text_color_enabled'].disabled = customization_disabled
	n['button_text_color'].disabled = customization_disabled
	n['button_background'].disabled = customization_disabled
	n['button_background_visible'].disabled = customization_disabled
	n['button_image'].disabled = customization_disabled
	n['button_image_visible'].disabled = customization_disabled
	n['button_modulation'].disabled = customization_disabled
	n['button_modulation_color'].disabled = customization_disabled
	n['button_use_native'].disabled = custom_enabled
	n['button_use_custom'].disabled = native_enabled
	n['button_custom_path'].disabled = native_enabled
	n['button_offset_x'].editable = not customization_disabled
	n['button_offset_y'].editable = not customization_disabled


func _on_CustomButtonsCheckBox_toggled(button_pressed):
	if loading:
		return
	DialogicResources.set_theme_value(current_theme, 'buttons', 'use_custom', button_pressed)
	toggle_button_customization_fields(false, button_pressed)


func _on_CustomButtonsButton_pressed():
	editor_reference.godot_dialog("*.tscn")
	editor_reference.godot_dialog_connect(self, "_on_custom_button_selected")

func _on_custom_button_selected(path, target) -> void:
	if loading:
		return
	DialogicResources.set_theme_value(current_theme, 'buttons', 'custom_path', path)
	n['button_custom_path'].text = DialogicResources.get_filename_from_path(path)


func _on_GlossaryColorPicker_color_changed(color) -> void:
	if loading:
		return
	DialogicResources.set_theme_value(current_theme, 'definitions', 'color', '#' + color.to_html())
	$DelayPreviewTimer.start(0.5) # Calling a timer so the update doesn't get triggered many times


func _on_GlossaryFontButton_pressed() -> void:
	editor_reference.godot_dialog("*.tres")
	editor_reference.godot_dialog_connect(self, "_on_Glossary_Font_selected")


func _on_Glossary_Font_selected(path, target) -> void:
	if loading:
		return
	DialogicResources.set_theme_value(current_theme, 'definitions', 'font', path)
	n['glossary_font'].text = DialogicResources.get_filename_from_path(path)
	_on_PreviewButton_pressed() # Refreshing the preview


func _on_ShowGlossaryCheckBox_toggled(button_pressed):
	if loading:
		return
	DialogicResources.set_theme_value(current_theme, 'definitions','show_glossary', button_pressed)
	_on_PreviewButton_pressed() # Refreshing the preview



func _on_visibility_changed() -> void:
	if visible:
		# Refreshing the dialog 
		_on_PreviewButton_pressed()
	else:
		# Erasing all previews since them keeps working
		# on background
		for i in $VBoxContainer/Panel.get_children():
			i.queue_free()


func _on_BoxSize_value_changed(value) -> void:
	if loading:
		return
	var size_value = Vector2(n['size_w'].value, n['size_h'].value)
	DialogicResources.set_theme_value(current_theme, 'box', 'size', size_value)
	_on_PreviewButton_pressed() # Refreshing the preview


func _on_BottomGap_value_changed(value) -> void:
	if loading:
		return
	DialogicResources.set_theme_value(current_theme, 'box', 'bottom_gap', value)
	_on_PreviewButton_pressed() # Refreshing the preview


func _on_Alignment_item_selected(index) -> void:
	if loading:
		return
	if index == 0:
		DialogicResources.set_theme_value(current_theme, 'text', 'alignment', 'Left')
	elif index == 1:
		DialogicResources.set_theme_value(current_theme, 'text', 'alignment', 'Center')
	elif index == 2:
		DialogicResources.set_theme_value(current_theme, 'text', 'alignment', 'Right')
	_on_PreviewButton_pressed() # Refreshing the preview


func _on_Preview_text_changed() -> void:
	if loading:
		return
	DialogicResources.set_theme_value(current_theme, 'text', 'preview', n['text_preview'].text)


func _on_name_auto_color_toggled(button_pressed) -> void:
	if loading:
		return
	DialogicResources.set_theme_value(current_theme, 'name', 'auto_color', button_pressed)
	_on_PreviewButton_pressed() # Refreshing the preview


func _on_name_background_visible_toggled(button_pressed) -> void:
	if loading:
		return
	DialogicResources.set_theme_value(current_theme, 'name', 'background_visible', button_pressed)
	_on_PreviewButton_pressed() # Refreshing the preview


func _on_name_background_color_changed(color) -> void:
	if loading:
		return
	DialogicResources.set_theme_value(current_theme, 'name', 'background', '#' + color.to_html())
	$DelayPreviewTimer.start(0.5) # Calling a timer so the update doesn't get triggered many times


func _on_name_image_visible_toggled(button_pressed) -> void:
	if loading:
		return
	DialogicResources.set_theme_value(current_theme, 'name', 'image_visible', button_pressed)
	_on_PreviewButton_pressed() # Refreshing the preview


func _on_name_image_pressed() -> void:
	editor_reference.godot_dialog("*.png")
	editor_reference.godot_dialog_connect(self, "_on_name_texture_selected")


func _on_name_texture_selected(path, target) -> void:
	if loading:
		return
	DialogicResources.set_theme_value(current_theme, 'name', 'image', path)
	n['name_image'].text = DialogicResources.get_filename_from_path(path)
	_on_PreviewButton_pressed() # Refreshing the preview


func _on_shadow_visible_toggled(button_pressed) -> void:
	if loading:
		return
	DialogicResources.set_theme_value(current_theme, 'name', 'shadow_visible', button_pressed)
	_on_PreviewButton_pressed() # Refreshing the preview


func _on_name_shadow_color_changed(color) -> void:
	if loading:
		return
	DialogicResources.set_theme_value(current_theme, 'name', 'shadow', '#' + color.to_html())
	$DelayPreviewTimer.start(0.5) # Calling a timer so the update doesn't get triggered many times


func _on_name_ShadowOffset_value_changed(_value) -> void:
	if loading:
		return
	DialogicResources.set_theme_value(current_theme, 'name','shadow_offset', 
			Vector2(n['name_shadow_offset_x'].value,n['name_shadow_offset_y'].value))
	_on_PreviewButton_pressed() # Refreshing the preview


func _on_name_BottomGap_value_changed(value) -> void:
	if loading:
		return
	DialogicResources.set_theme_value(current_theme, 'name', 'bottom_gap', value)
	_on_PreviewButton_pressed() # Refreshing the preview


func _on_DelayPreview_timer_timeout() -> void:
	_on_PreviewButton_pressed() # Refreshing the preview


func _on_BackgroundTexture_Modulation_toggled(button_pressed) -> void:
	if loading:
		return
	DialogicResources.set_theme_value(current_theme, 'background', 'modulation', button_pressed)
	_on_PreviewButton_pressed() # Refreshing the preview


func _on_ColorPicker_Background_texture_modulation_color_changed(color) -> void:
	if loading:
		return
	DialogicResources.set_theme_value(current_theme, 'background', 'modulation_color', '#' + color.to_html())
	$DelayPreviewTimer.start(0.5) # Calling a timer so the update doesn't get triggered many times


func _on_ColorPicker_NameLabel_modulation_color_changed(color) -> void:
	if loading:
		return
	DialogicResources.set_theme_value(current_theme, 'name', 'modulation_color', '#' + color.to_html())
	$DelayPreviewTimer.start(0.5) # Calling a timer so the update doesn't get triggered many times


func _on_NameLabel_texture_modulation_toggled(button_pressed) -> void:
	if loading:
		return
	DialogicResources.set_theme_value(current_theme, 'name', 'modulation', button_pressed)
	_on_PreviewButton_pressed() # Refreshing the preview


func _on_ChoiceButtons_texture_modulate_toggled(button_pressed) -> void:
	if loading:
		return
	DialogicResources.set_theme_value(current_theme, 'buttons', 'modulation', button_pressed)
	_on_PreviewButton_pressed() # Refreshing the preview


func _on_ColorPicker_ChoiceButtons_modulation_color_changed(color) -> void:
	if loading:
		return
	DialogicResources.set_theme_value(current_theme, 'buttons', 'modulation_color', '#' + color.to_html())
	$DelayPreviewTimer.start(0.5) # Calling a timer so the update doesn't get triggered many times



func _on_IndicatorScale_value_changed(value) -> void:
	if loading:
		return
	DialogicResources.set_theme_value(current_theme, 'next_indicator', 'scale', value)
	_on_PreviewButton_pressed() # Refreshing the preview


func _on_NextOffset_value_changed(value):
	if loading:
		return
	var offset_value = Vector2(n['next_indicator_offset_x'].value, n['next_indicator_offset_y'].value)
	DialogicResources.set_theme_value(current_theme, 'next_indicator', 'offset', offset_value)
	_on_PreviewButton_pressed() # Refreshing the preview


func _on_FixedSize_toggled(button_pressed):
	if loading:
		return
	DialogicResources.set_theme_value(current_theme, 'buttons', 'fixed', button_pressed)
	_on_PreviewButton_pressed() # Refreshing the preview


func _on_ButtonSize_value_changed(value):
	if loading:
		return
	DialogicResources.set_theme_value(current_theme, 'buttons','fixed_size', Vector2(n['button_fixed_x'].value,n['button_fixed_y'].value))
	_on_PreviewButton_pressed() # Refreshing the preview

