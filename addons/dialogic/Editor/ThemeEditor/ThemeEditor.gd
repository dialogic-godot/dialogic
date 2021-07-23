tool
extends Control

var editor_reference
onready var master_tree = get_node('../MasterTreeContainer/MasterTree')
onready var settings_editor = get_node('../SettingsEditor')
var current_theme : String = ''
var use_advanced_themes : bool = false
var preview_character_selected : String = 'random'
var current_choice_modifier_selected = 'hover'

# When loading the variables to the input fields in the 
# load_theme function, every element thinks the value was updated
# so it has to perform a "saving" of that property. 
# The loading variable is a way to check if the values should be saved
# or not.
var loading : bool = true 


# If the first time you open a theme it is a "full_width" one, the editor
# doesn't trigger the Panel resized() signal before the dialog resize_main()
# So what I do here, is doing a check for the first time and force a double
# refresh that will make sure that the full_width background will display 
# as expected.

# The stuff used for this hack are:
# Variable:        first_time_loading_theme_full_size_bug
# Node:            $FirstTimeLoadingFullSizeBug
# This function:   _on_FirstTimeLoadingFullSizeBug_timeout()

# If you know how to fix this, please let me know or send a pull request :)
var first_time_loading_theme_full_size_bug := 0


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
	'theme_text_shadow': $"VBoxContainer/TabContainer/Dialog Text/Column2/GridContainer/HBoxContainer2/CheckBoxShadow",
	'theme_text_shadow_color': $"VBoxContainer/TabContainer/Dialog Text/Column2/GridContainer/HBoxContainer2/ColorPickerButtonShadow",
	'theme_text_color': $"VBoxContainer/TabContainer/Dialog Text/Column2/GridContainer/ColorPickerButton",
	'theme_font': $"VBoxContainer/TabContainer/Dialog Text/Column/GridContainer/RegularFont/RegularFontButton",
	'theme_font_bold':$"VBoxContainer/TabContainer/Dialog Text/Column/GridContainer/BoldFont/BoldFontButton",
	'theme_font_italic':$"VBoxContainer/TabContainer/Dialog Text/Column/GridContainer/ItalicFont/ItalicFontButton",
	'theme_shadow_offset_x': $"VBoxContainer/TabContainer/Dialog Text/Column2/GridContainer/HBoxContainer/ShadowOffsetX",
	'theme_shadow_offset_y': $"VBoxContainer/TabContainer/Dialog Text/Column2/GridContainer/HBoxContainer/ShadowOffsetY",
	'theme_text_speed': $"VBoxContainer/TabContainer/Dialog Text/Column3/GridContainer/TextSpeed",
	'alignment': $"VBoxContainer/TabContainer/Dialog Text/Column3/GridContainer/HBoxContainer3/Alignment",
	'single_portrait_mode': $"VBoxContainer/TabContainer/Dialog Text/Column3/GridContainer/SinglePortraitModeCheckBox",
	
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
	'background_full_width': $"VBoxContainer/TabContainer/Dialog Box/Column/GridContainer/HBoxContainer7/CheckBox",
	'animation_show_time': $"VBoxContainer/TabContainer/Dialog Box/Column3/GridContainer/ShowTime/SpinBox",
	
	# Character Names
	'name_font': $"VBoxContainer/TabContainer/Name Label/Column/GridContainer/RegularFont/NameFontButton",
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
	'name_horizontal_offset': $"VBoxContainer/TabContainer/Name Label/Column3/GridContainer/HBoxContainer5/HorizontalOffset",
	'name_background_modulation': $"VBoxContainer/TabContainer/Name Label/Column2/GridContainer/HBoxContainer6/CheckBox",
	'name_background_modulation_color': $"VBoxContainer/TabContainer/Name Label/Column2/GridContainer/HBoxContainer6/ColorPickerButton",
	'name_padding_x': $"VBoxContainer/TabContainer/Name Label/Column2/GridContainer/HBoxContainer/NamePaddingX",
	'name_padding_y': $"VBoxContainer/TabContainer/Name Label/Column2/GridContainer/HBoxContainer/NamePaddingY",
	'name_position': $"VBoxContainer/TabContainer/Name Label/Column3/GridContainer/HBoxContainer/Positions",
	
	
	# Choice Buttons
	
	'button_fixed': $"VBoxContainer/TabContainer/Choice Buttons/Column2/GridContainer/HBoxContainer2/FixedSize",
	'button_fixed_x': $"VBoxContainer/TabContainer/Choice Buttons/Column2/GridContainer/HBoxContainer2/ButtonSizeX",
	'button_fixed_y': $"VBoxContainer/TabContainer/Choice Buttons/Column2/GridContainer/HBoxContainer2/ButtonSizeY",

	'button_use_native': $"VBoxContainer/TabContainer/Choice Buttons/Column3/GridContainer/CheckBox",
	'button_use_custom': $"VBoxContainer/TabContainer/Choice Buttons/Column3/GridContainer/HBoxContainer5/CustomButtonsCheckBox",
	'button_custom_path': $"VBoxContainer/TabContainer/Choice Buttons/Column3/GridContainer/HBoxContainer5/CustomButtonsButton",
	'button_offset_x': $"VBoxContainer/TabContainer/Choice Buttons/Column2/GridContainer/HBoxContainer/TextOffsetH",
	'button_offset_y': $"VBoxContainer/TabContainer/Choice Buttons/Column2/GridContainer/HBoxContainer/TextOffsetV",
	'button_separation': $"VBoxContainer/TabContainer/Choice Buttons/Column2/GridContainer/VerticalSeparation",
	
	# Button modifiers (Inherited scenes)
	'button_normal': $"VBoxContainer/TabContainer/Choice Buttons/Column/TabContainer/Normal",
	'button_hover': $"VBoxContainer/TabContainer/Choice Buttons/Column/TabContainer/Hover",
	'button_pressed': $"VBoxContainer/TabContainer/Choice Buttons/Column/TabContainer/Pressed",
	'button_disabled': $"VBoxContainer/TabContainer/Choice Buttons/Column/TabContainer/Disabled",
	
	# Glossary
	'glossary_title_font': $VBoxContainer/TabContainer/Glossary/Column3/GridContainer/TitleFont/TitleFontButton,
	'glossary_text_font': $VBoxContainer/TabContainer/Glossary/Column3/GridContainer/TextFont/TextFontButton,
	'glossary_extra_font': $VBoxContainer/TabContainer/Glossary/Column3/GridContainer/ExtraFont/ExtraFontButton,
	'glossary_highlight_color': $VBoxContainer/TabContainer/Glossary/Column/GridContainer/HighlightColorPicker,
	'glossary_title_color': $VBoxContainer/TabContainer/Glossary/Column3/GridContainer/TitleColorPicker,
	'glossary_text_color': $VBoxContainer/TabContainer/Glossary/Column3/GridContainer/TextColorPicker,
	'glossary_extra_color': $VBoxContainer/TabContainer/Glossary/Column3/GridContainer/ExtraColorPicker,
	
	'glossary_background_panel': $VBoxContainer/TabContainer/Glossary/Column/GridContainer/BackgroundPanel/BgPanelButton,
	
	'glossary_enabled': $VBoxContainer/TabContainer/Glossary/Column2/GridContainer/ShowGlossaryCheckBox,
	
	# Audio
	'typing_sfx_enabled': $"VBoxContainer/TabContainer/Audio/Column/GridContainer/TypingCheckBox",
	'typing_sfx_path': $"VBoxContainer/TabContainer/Audio/Column/GridContainer/TypingPathButton",
	'typing_sfx_volume': $"VBoxContainer/TabContainer/Audio/Column/GridContainer/HBoxContainer/TypingVolume",
	'typing_sfx_volume_range': $"VBoxContainer/TabContainer/Audio/Column/GridContainer/HBoxContainer2/TypingVolumeRandRange",
	'typing_sfx_pitch_range': $"VBoxContainer/TabContainer/Audio/Column/GridContainer/HBoxContainer3/TypingPitchRandRange",
	'typing_sfx_allow_interrupt': $"VBoxContainer/TabContainer/Audio/Column/GridContainer/TypingInterruptCheckBox",
	'typing_sfx_audio_bus': $"VBoxContainer/TabContainer/Audio/Column/GridContainer/AudioBusButton",
	
	# Text preview
	'text_preview': $VBoxContainer/HBoxContainer3/TextEdit,
	'character_picker': $VBoxContainer/HBoxContainer3/CharacterPicker,
	
}


## ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## 						GENERAL EDITOR STUFF
## ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

func _ready() -> void:
	AudioServer.connect("bus_layout_changed", self, "_on_bus_layout_changed")
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
	
	$"VBoxContainer/TabContainer/Name Label/Column/GridContainer/RegularFont/NameFontOpen".icon = get_icon("Edit", "EditorIcons")
	$"VBoxContainer/TabContainer/Dialog Text/Column/GridContainer/BoldFont/BoldFontOpen".icon = get_icon("Edit", "EditorIcons")
	$"VBoxContainer/TabContainer/Dialog Text/Column/GridContainer/ItalicFont/ItalicFontOpen".icon = get_icon("Edit", "EditorIcons")
	$"VBoxContainer/TabContainer/Dialog Text/Column/GridContainer/RegularFont/RegularFontOpen".icon = get_icon("Edit", "EditorIcons")
	$"VBoxContainer/TabContainer/Glossary/Column3/GridContainer/TitleFont/TitleFontOpen".icon = get_icon("Edit", "EditorIcons")
	$"VBoxContainer/TabContainer/Glossary/Column3/GridContainer/TextFont/TextFontOpen".icon = get_icon("Edit", "EditorIcons")
	$"VBoxContainer/TabContainer/Glossary/Column3/GridContainer/ExtraFont/ExtraFontOpen".icon = get_icon("Edit", "EditorIcons")
	$"VBoxContainer/TabContainer/Glossary/Column/GridContainer/BackgroundPanel/BGPanelOpen".icon = get_icon("Edit", "EditorIcons")
	
	n['text_preview'].syntax_highlighting = true
	n['text_preview'].add_color_region('[', ']', get_color("axis_z_color", "Editor"))
	
	# Dialog Text tab
	n['theme_text_shadow'].connect('toggled', self, '_on_generic_checkbox', ['text', 'shadow'])
	n['single_portrait_mode'].connect('toggled', self, '_on_generic_checkbox', ['settings', 'single_portrait_mode'])
	n['theme_text_speed'].connect('value_changed', self, '_on_generic_value_change', ['text','speed'])
	
	# Dialog Box tab
	n['theme_background_color_visible'].connect('toggled', self, '_on_generic_checkbox', ['background', 'use_color'])
	n['background_texture_button_visible'].connect('toggled', self, '_on_generic_checkbox', ['background', 'use_image'])
	n['background_modulation'].connect('toggled', self, '_on_generic_checkbox', ['background', 'modulation'])
	n['background_full_width'].connect('toggled', self, '_on_generic_checkbox', ['background', 'full_width'])
	n['animation_show_time'].connect('value_changed', self, '_on_generic_value_change', ['animation', 'show_time'])
	n['bottom_gap'].connect('value_changed', self, '_on_generic_value_change', ['box', 'bottom_gap'])
	n['next_indicator_scale'].connect('value_changed', self, '_on_generic_value_change', ['next_indicator', 'scale'])

	# Name tab
	n['name_shadow_visible'].connect('toggled', self, '_on_generic_checkbox', ['name', 'shadow_visible'])
	n['name_background_visible'].connect('toggled', self, '_on_generic_checkbox', ['name', 'background_visible'])
	n['name_image_visible'].connect('toggled', self, '_on_generic_checkbox', ['name', 'image_visible'])
	n['name_background_modulation'].connect('toggled', self, '_on_generic_checkbox', ['name', 'modulation'])

	# Buttons tab
	n['button_fixed'].connect('toggled', self, '_on_generic_checkbox', ['buttons', 'fixed'])
	
	# Choice button style modifiers
	n['button_normal'].connect('picking_background', self, '_on_ButtonTextureButton_pressed')
	n['button_hover'].connect('picking_background', self, '_on_ButtonTextureButton_pressed')
	n['button_pressed'].connect('picking_background', self, '_on_ButtonTextureButton_pressed')
	n['button_disabled'].connect('picking_background', self, '_on_ButtonTextureButton_pressed')
	
	n['button_normal'].connect('style_modified', self, '_on_choice_style_modified')
	n['button_hover'].connect('style_modified', self, '_on_choice_style_modified')
	n['button_pressed'].connect('style_modified', self, '_on_choice_style_modified')
	n['button_disabled'].connect('style_modified', self, '_on_choice_style_modified')
	
	n['name_position'].text = 'Left'
	n['name_position'].connect('item_selected', self, '_on_name_position_selected')
	var name_positions_popup = n['name_position'].get_popup()
	name_positions_popup.clear()
	name_positions_popup.add_radio_check_item('Left')
	name_positions_popup.add_radio_check_item('Center')
	name_positions_popup.add_radio_check_item('Right')
	n['name_position'].select(0)
	
	# Glossary tab
	n['glossary_enabled'].connect('toggled', self, '_on_generic_checkbox', ['definitions','show_glossary'])

	# Audio tab
	n['typing_sfx_enabled'].connect('toggled', self, '_on_generic_checkbox', ['typing_sfx','enable'])
	n['typing_sfx_volume'].connect('value_changed', self, '_on_generic_value_change', ['typing_sfx', 'volume'])
	n['typing_sfx_volume_range'].connect('value_changed', self, '_on_generic_value_change', ['typing_sfx', 'random_volume_range'])
	n['typing_sfx_pitch_range'].connect('value_changed', self, '_on_generic_value_change', ['typing_sfx', 'random_pitch_range'])

	# Character Picker
	n['character_picker'].connect('about_to_show', self, 'character_picker_about_to_show')
	n['character_picker'].get_popup().connect('index_pressed', self, 'character_picker_selected')
	
	# Force preview update
	_on_visibility_changed()



func character_picker_about_to_show():
	var characters : Array = DialogicUtil.get_character_list()
	n['character_picker'].get_popup().clear()
	n['character_picker'].get_popup().add_item('Random Character')
	n['character_picker'].get_popup().set_item_metadata(0, 'random')
	var index = 1
	for c in characters:
		n['character_picker'].get_popup().add_item(c['name'])
		n['character_picker'].get_popup().set_item_metadata(index, c['file'])
		index += 1


func character_picker_selected(index):
	preview_character_selected = n['character_picker'].get_popup().get_item_metadata(index)
	n['character_picker'].text = n['character_picker'].get_popup().get_item_text(index)
	_on_PreviewButton_pressed()


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
	var default_background = 'res://addons/dialogic/Example Assets/backgrounds/background-2.png'
	setup_advanced_containers()
	# Settings
	n['theme_action_key'].text = theme.get_value('settings', 'action_key', '[Default]')
	n['single_portrait_mode'].pressed = theme.get_value('settings', 'single_portrait_mode', false) # Currently in Dialog Text tab
	
	# Background
	n['theme_background_image'].text = DialogicResources.get_filename_from_path(theme.get_value('background', 'image', default_background))
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
	n['background_full_width'].pressed = theme.get_value('background', 'full_width', false)
	
	
	var size_value = theme.get_value('box', 'size', Vector2(910, 167))
	n['size_w'].value = size_value.x
	n['size_h'].value = size_value.y
	
	n['bottom_gap'].value = theme.get_value('box', 'bottom_gap', 40)
	
	# Buttons
	n['button_use_native'].pressed = theme.get_value('buttons', 'use_native', false)
	n['button_use_custom'].pressed = theme.get_value('buttons', 'use_custom', false)
	n['button_custom_path'].text = DialogicResources.get_filename_from_path(theme.get_value('buttons', 'custom_path', ""))
	n['button_offset_x'].value = theme.get_value('buttons', 'padding', Vector2(5,5)).x
	n['button_offset_y'].value = theme.get_value('buttons', 'padding', Vector2(5,5)).y
	n['button_separation'].value = theme.get_value('buttons', 'gap', 5)
	n['button_fixed'].pressed = theme.get_value('buttons', 'fixed', false)
	n['button_fixed_x'].value = theme.get_value('buttons', 'fixed_size', Vector2(130,40)).x
	n['button_fixed_y'].value = theme.get_value('buttons', 'fixed_size', Vector2(130,40)).y
	
	
	
	var default_style = [false, Color.white, false, Color.black, true, default_background, false, Color.white]
	n['button_normal'].load_style(theme.get_value('buttons', 'normal', default_style))
	n['button_hover'].load_style(theme.get_value('buttons', 'hover', default_style))
	n['button_pressed'].load_style(theme.get_value('buttons', 'pressed', default_style))
	n['button_disabled'].load_style(theme.get_value('buttons', 'disabled', default_style))
	
	toggle_button_customization_fields(theme.get_value('buttons', 'use_native', false), theme.get_value('buttons', 'use_custom', false))
	
	# Definitions
	n['glossary_highlight_color'].color = Color(theme.get_value('definitions', 'color', "#ffffffff"))
	
	n['glossary_title_font'].text = DialogicResources.get_filename_from_path(theme.get_value('definitions', 'font', "res://addons/dialogic/Example Assets/Fonts/GlossaryFont.tres"))
	n['glossary_title_color'].color = Color(theme.get_value('definitions', 'title_color', "#ffffffff"))
	
	n['glossary_text_font'].text = DialogicResources.get_filename_from_path(theme.get_value('definitions', 'text_font', "res://addons/dialogic/Example Assets/Fonts/GlossaryFont.tres"))
	n['glossary_text_color'].color = Color(theme.get_value('definitions', 'text_color', "#ffffffff"))
	
	n['glossary_extra_font'].text = DialogicResources.get_filename_from_path(theme.get_value('definitions', 'extra_font', "res://addons/dialogic/Example Assets/Fonts/GlossaryFont.tres"))
	n['glossary_extra_color'].color = Color(theme.get_value('definitions', 'extra_color', "#ffffffff"))
	
	n['glossary_background_panel'].text = DialogicResources.get_filename_from_path(theme.get_value('definitions', 'background_panel', "res://addons/dialogic/Example Assets/backgrounds/GlossaryBackground.tres"))
	
	n['glossary_enabled'].pressed = theme.get_value('definitions', 'show_glossary', true)
	
	# Text
	n['theme_text_speed'].value = theme.get_value('text','speed', 2)
	n['theme_font'].text = DialogicResources.get_filename_from_path(theme.get_value('text', 'font', 'res://addons/dialogic/Example Assets/Fonts/DefaultFont.tres'))
	n['theme_font_bold'].text = DialogicResources.get_filename_from_path(theme.get_value('text', 'bold_font', 'res://addons/dialogic/Example Assets/Fonts/DefaultBoldFont.tres'))
	n['theme_font_italic'].text = DialogicResources.get_filename_from_path(theme.get_value('text', 'italic_font', 'res://addons/dialogic/Example Assets/Fonts/DefaultItalicFont.tres'))
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
	n['name_font'].text = DialogicResources.get_filename_from_path(theme.get_value('name', 'font', 'res://addons/dialogic/Example Assets/Fonts/NameFont.tres'))
	n['name_auto_color'].pressed = theme.get_value('name', 'auto_color', true)
	n['name_background_visible'].pressed = theme.get_value('name', 'background_visible', false)
	n['name_background'].color = Color(theme.get_value('name', 'background', "#ff000000"))
	n['name_image_visible'].pressed = theme.get_value('name', 'image_visible', false)

	n['name_image'].text = DialogicResources.get_filename_from_path(theme.get_value('name', 'image', 'res://addons/dialogic/Example Assets/backgrounds/background-2.png'))
	n['name_background_modulation'].pressed = theme.get_value('name', 'modulation', false)
	n['name_background_modulation_color'].color = Color(theme.get_value('name', 'modulation_color', '#ffffffff'))

	n['name_padding_x'].value = theme.get_value('name', 'name_padding', Vector2(10,0)).x
	n['name_padding_y'].value = theme.get_value('name', 'name_padding', Vector2(10,0)).y
	
	n['name_shadow'].color = Color(theme.get_value('name', 'shadow', "#9e000000"))
	n['name_shadow_visible'].pressed = theme.get_value('name', 'shadow_visible', true)
	n['name_shadow_offset_x'].value = theme.get_value('name', 'shadow_offset', Vector2(2,2)).x
	n['name_shadow_offset_y'].value = theme.get_value('name', 'shadow_offset', Vector2(2,2)).y
	n['name_bottom_gap'].value = theme.get_value('name', 'bottom_gap', 48)
	n['name_horizontal_offset'].value = theme.get_value('name', 'horizontal_offset', 0)
	
	n['name_position'].select(theme.get_value('name', 'position', 0))
	
	# Audio
	n['typing_sfx_enabled'].pressed = theme.get_value('typing_sfx', 'enable', false)
	n['typing_sfx_path'].text = DialogicResources.get_filename_from_path(theme.get_value('typing_sfx', 'path', "res://addons/dialogic/Example Assets/Sound Effects/Keyboard Noises"))
	n['typing_sfx_volume'].value = theme.get_value('typing_sfx', 'volume', -10)
	n['typing_sfx_volume_range'].value = theme.get_value('typing_sfx', 'random_volume_range', 5)
	n['typing_sfx_pitch_range'].value = theme.get_value('typing_sfx', 'random_pitch_range', 0.2)
	n['typing_sfx_allow_interrupt'].pressed = theme.get_value('typing_sfx', 'allow_interrupt', true)
	
	update_audio_bus_option_buttons()
	
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


func create_theme() -> String:
	var theme_file : String = 'theme-' + str(OS.get_unix_time()) + '.cfg'
	DialogicResources.add_theme(theme_file)
	load_theme(theme_file)
	# Check if it is the only theme to set as default
	if DialogicUtil.get_theme_list().size() == 1:
		#print('only theme, setting as default')
		settings_editor.set_value('theme', 'default', theme_file)
	return theme_file


func duplicate_theme(from_filename) -> void:
	var duplicate_theme : String = 'theme-' + str(OS.get_unix_time()) + '.cfg'
	DialogicResources.duplicate_theme(from_filename, duplicate_theme)
	DialogicResources.set_theme_value(duplicate_theme, 'settings', 'name', duplicate_theme)
	master_tree.build_themes(duplicate_theme)
	load_theme(duplicate_theme)


func _on_visibility_changed() -> void:
	if visible:
		# Refreshing the dialog 
		_on_PreviewButton_pressed()
		if first_time_loading_theme_full_size_bug == 0:
			yield(get_tree().create_timer(0.01), "timeout")
			for i in $VBoxContainer/Panel.get_children():
				i.resize_main()
			first_time_loading_theme_full_size_bug += 1
	else:
		# Erasing all previews since them keeps working on background
		for i in $VBoxContainer/Panel.get_children():
			i.queue_free()

## ------------ 			Preview 		------------------------------------

func _on_DelayPreview_timer_timeout() -> void:
	_on_PreviewButton_pressed() # Refreshing the preview


func _on_PreviewButton_pressed() -> void:
	for i in $VBoxContainer/Panel.get_children():
		i.free()
	var preview_dialog = Dialogic.start('', true, "res://addons/dialogic/Dialog.tscn", false, false)
	preview_dialog.preview = true
	
	if n['character_picker']: # Sometimes it can't find the node
		if n['character_picker'].text == 'Random Character':
			var characters : Array = DialogicUtil.get_character_list()
			if characters.size():
				characters.shuffle()
				preview_character_selected = characters[0]['file']

	preview_dialog.dialog_script = {
			"events":[
				{ 'event_id':'dialogic_024', "set_theme": current_theme },
				{ 'event_id':'dialogic_001', "character": preview_character_selected, "portrait":"", "text":n['text_preview'].text }
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


func _on_Preview_text_changed() -> void:
	if loading:
		return
	DialogicResources.set_theme_value(current_theme, 'text', 'preview', n['text_preview'].text)

## ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## 							THEME OPTIONS
## ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

## ------------ 		GENERICS

func _on_generic_checkbox(button_pressed, section, key, update_preview = true) -> void:
	# Many methods here are the same, so I want to replace all those instances
	# with this generic checkbox logic. TODO
	if loading:
		return
	DialogicResources.set_theme_value(current_theme, section, key, button_pressed)
	if update_preview:
		_on_PreviewButton_pressed() # Refreshing the preview


func _on_generic_value_change(value, section, key, update_preview = true) -> void:
	if loading:
		return
	DialogicResources.set_theme_value(current_theme, section, key, value)
	if update_preview:
		_on_PreviewButton_pressed() # Refreshing the preview


## ------------ 		DIALOG TEXT TAB 	------------------------------------

# Fonts
func _on_FontButton_pressed() -> void:
	editor_reference.godot_dialog("*.tres")
	editor_reference.godot_dialog_connect(self, "_on_Font_selected")


func _on_Font_selected(path, target) -> void:
	if loading:
		return
	DialogicResources.set_theme_value(current_theme, 'text','font', path)
	n['theme_font'].text = DialogicResources.get_filename_from_path(path)
	_on_PreviewButton_pressed() # Refreshing the preview


func _on_FontOpen_pressed():
	var theme = DialogicResources.get_theme_config(current_theme)
	editor_reference.editor_interface.inspect_object(load(theme.get_value('text', 'font', 'res://addons/dialogic/Example Assets/Fonts/DefaultFont.tres')))


func _on_BoldFontButton_pressed():
	editor_reference.godot_dialog("*.tres")
	editor_reference.godot_dialog_connect(self, "_on_BoldFont_selected")


func _on_BoldFont_selected(path, target) -> void:
	if loading:
		return
	DialogicResources.set_theme_value(current_theme, 'text','bold_font', path)
	n['theme_font_bold'].text = DialogicResources.get_filename_from_path(path)
	_on_PreviewButton_pressed() # Refreshing the preview


func _on_BoldFontOpen_pressed():
	var theme = DialogicResources.get_theme_config(current_theme)
	editor_reference.editor_interface.inspect_object(load(theme.get_value('text', 'bold_font', 'res://addons/dialogic/Example Assets/Fonts/DefaultBoldFont.tres')))


func _on_ItalicFontButton_pressed():
	editor_reference.godot_dialog("*.tres")
	editor_reference.godot_dialog_connect(self, "_on_ItalicFont_selected")


func _on_ItalicFont_selected(path, target) -> void:
	if loading:
		return
	DialogicResources.set_theme_value(current_theme, 'text', 'italic_font', path)
	n['theme_font_italic'].text = DialogicResources.get_filename_from_path(path)
	_on_PreviewButton_pressed() # Refreshing the preview


func _on_ItalicFontOpen_pressed():
	var theme = DialogicResources.get_theme_config(current_theme)
	editor_reference.editor_interface.inspect_object(load(theme.get_value('text', 'italic_font', 'res://addons/dialogic/Example Assets/Fonts/DefaultItalicFont.tres')))


func _on_NameFont_pressed():
	editor_reference.godot_dialog("*.tres")
	editor_reference.godot_dialog_connect(self, "_on_NameFont_selected")


func _on_NameFont_selected(path, target) -> void:
	if loading:
		return
	DialogicResources.set_theme_value(current_theme, 'name', 'font', path)
	n['name_font'].text = DialogicResources.get_filename_from_path(path)
	_on_PreviewButton_pressed() # Refreshing the preview


func _on_NameFontOpen_pressed():
	var theme = DialogicResources.get_theme_config(current_theme)
	editor_reference.editor_interface.inspect_object(load(theme.get_value('name', 'font', 'res://addons/dialogic/Example Assets/Fonts/NameFont.tres')))


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


func _on_ShadowOffset_value_changed(_value) -> void:
	if loading:
		return
	DialogicResources.set_theme_value(current_theme, 'text','shadow_offset', Vector2(n['theme_shadow_offset_x'].value,n['theme_shadow_offset_y'].value))
	_on_PreviewButton_pressed() # Refreshing the preview


## ------------ 		DIALOG BOX TAB	 	------------------------------------

func _on_TextMargin_value_changed(value) -> void:
	if loading:
		return
	var final_vector = Vector2(
		n['theme_text_margin'].value,
		n['theme_text_margin_h'].value
	)
	DialogicResources.set_theme_value(current_theme, 'text', 'margin', final_vector)
	_on_PreviewButton_pressed() # Refreshing the preview


func _on_BoxSize_value_changed(value) -> void:
	if loading:
		return
	var size_value = Vector2(n['size_w'].value, n['size_h'].value)
	DialogicResources.set_theme_value(current_theme, 'box', 'size', size_value)
	_on_PreviewButton_pressed() # Refreshing the preview


# Background Texture
func _on_BackgroundTextureButton_pressed() -> void:
	editor_reference.godot_dialog("*.png")
	editor_reference.godot_dialog_connect(self, "_on_background_selected")


func _on_background_selected(path, target) -> void:
	if loading:
		return
	DialogicResources.set_theme_value(current_theme, 'background','image', path)
	n['theme_background_image'].text = DialogicResources.get_filename_from_path(path)
	_on_PreviewButton_pressed() # Refreshing the preview


func _on_ColorPicker_Background_texture_modulation_color_changed(color) -> void:
	if loading:
		return
	DialogicResources.set_theme_value(current_theme, 'background', 'modulation_color', '#' + color.to_html())
	$DelayPreviewTimer.start(0.5) # Calling a timer so the update doesn't get triggered many times

# Background Color
func _on_BackgroundColor_ColorPickerButton_color_changed(color) -> void:
	if loading:
		return
	DialogicResources.set_theme_value(current_theme, 'background', 'color', '#' + color.to_html())
	$DelayPreviewTimer.start(0.5) # Calling a timer so the update doesn't get triggered many times

# Next indicator
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


func _on_NextOffset_value_changed(value):
	if loading:
		return
	var offset_value = Vector2(n['next_indicator_offset_x'].value, n['next_indicator_offset_y'].value)
	DialogicResources.set_theme_value(current_theme, 'next_indicator', 'offset', offset_value)
	_on_PreviewButton_pressed() # Refreshing the preview


func _on_ActionOptionButton_item_selected(index) -> void:
	if loading:
		return
	DialogicResources.set_theme_value(current_theme, 'settings','action_key', n['theme_action_key'].text)


func _on_ActionOptionButton_pressed() -> void:
	var theme = DialogicResources.get_theme_config(current_theme)
	n['theme_action_key'].clear()
	n['theme_action_key'].add_item(theme.get_value('settings', 'action_key', '[Default]'))
	n['theme_action_key'].add_item('[Default]')
	InputMap.load_from_globals()
	for a in InputMap.get_actions():
		n['theme_action_key'].add_item(a)


## ------------ 		NAME LABEL TAB	 	------------------------------------

# Text Color
func _on_name_auto_color_toggled(button_pressed) -> void:
	if loading:
		return
	DialogicResources.set_theme_value(current_theme, 'name', 'auto_color', button_pressed)
	_on_PreviewButton_pressed() # Refreshing the preview


# Background Color
func _on_name_background_color_changed(color) -> void:
	if loading:
		return
	DialogicResources.set_theme_value(current_theme, 'name', 'background', '#' + color.to_html())
	$DelayPreviewTimer.start(0.5) # Calling a timer so the update doesn't get triggered many times


# Background Texture
func _on_name_image_pressed() -> void:
	editor_reference.godot_dialog("*.png")
	editor_reference.godot_dialog_connect(self, "_on_name_texture_selected")


func _on_name_texture_selected(path, target) -> void:
	if loading:
		return
	DialogicResources.set_theme_value(current_theme, 'name', 'image', path)
	n['name_image'].text = DialogicResources.get_filename_from_path(path)
	_on_PreviewButton_pressed() # Refreshing the preview


func _on_ColorPicker_NameLabel_modulation_color_changed(color) -> void:
	if loading:
		return
	DialogicResources.set_theme_value(current_theme, 'name', 'modulation_color', '#' + color.to_html())
	$DelayPreviewTimer.start(0.5) # Calling a timer so the update doesn't get triggered many times


func _on_name_shadow_color_changed(color) -> void:
	if loading:
		return
	DialogicResources.set_theme_value(current_theme, 'name', 'shadow', '#' + color.to_html())
	$DelayPreviewTimer.start(0.5) # Calling a timer so the update doesn't get triggered many times


func _on_name_ShadowOffset_value_changed(_value) -> void:
	if loading:
		return
	DialogicResources.set_theme_value(current_theme, 'name','shadow_offset', 
			Vector2(n['name_shadow_offset_x'].value, n['name_shadow_offset_y'].value))
	_on_PreviewButton_pressed() # Refreshing the preview


func _on_name_padding_value_changed(_value) -> void:
	if loading:
		return
	DialogicResources.set_theme_value(current_theme, 'name','name_padding', 
			Vector2(n['name_padding_x'].value, n['name_padding_y'].value))
	_on_PreviewButton_pressed() # Refreshing the preview


func _on_name_BottomGap_value_changed(value) -> void:
	if loading:
		return
	# Todo in 2.0: Replace for a single Vector2 instead of two variables
	DialogicResources.set_theme_value(current_theme, 'name', 'bottom_gap', n['name_bottom_gap'].value)
	DialogicResources.set_theme_value(current_theme, 'name', 'horizontal_offset', n['name_horizontal_offset'].value)
	_on_PreviewButton_pressed() # Refreshing the preview


func _on_name_position_selected(index):
	if loading:
		return
	DialogicResources.set_theme_value(current_theme, 'name', 'position', index)
	_on_PreviewButton_pressed() # Refreshing the preview

## ------------ 		CHOICE BUTTON TAB	 	--------------------------------
func _on_ButtonSize_value_changed(value):
	if loading:
		return
	DialogicResources.set_theme_value(current_theme, 'buttons','fixed_size', Vector2(n['button_fixed_x'].value,n['button_fixed_y'].value))
	_on_PreviewButton_pressed() # Refreshing the preview


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


# Background Texture
func _on_button_texture_toggled(button_pressed) -> void:
	if loading:
		return
	DialogicResources.set_theme_value(current_theme, 'buttons', 'use_image', button_pressed)


func _on_ButtonTextureButton_pressed(section = '') -> void:
	editor_reference.godot_dialog("*.png")
	if section != '':
		# Special modifier
		current_choice_modifier_selected = section
		editor_reference.godot_dialog_connect(self, "_on_modifier_button_image_selected")


func _on_modifier_button_image_selected(path, _target):
	if loading:
		return
	n['button_' + current_choice_modifier_selected].set_path(path)
	n['button_' + current_choice_modifier_selected].real_file_path = path
	n['button_' + current_choice_modifier_selected].get_node('BackgroundTexture/Button').text = DialogicResources.get_filename_from_path(path)
	_on_choice_style_modified(current_choice_modifier_selected)
	

func _on_choice_style_modified(section):
	DialogicResources.set_theme_value(current_theme, 'buttons', section, n['button_' + section].get_style_array())

func _on_native_button_toggled(button_pressed) -> void:
	if loading:
		return
	DialogicResources.set_theme_value(current_theme, 'buttons', 'use_native', button_pressed)
	toggle_button_customization_fields(button_pressed, false)


func toggle_button_customization_fields(native_enabled: bool, custom_enabled: bool) -> void:
	var customization_disabled = native_enabled or custom_enabled
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


## ------------ 		GLOSSARY  TAB	 	------------------------------------

## TITLE FONT
func _on_Glossary_TitleFontButton_pressed():
	editor_reference.godot_dialog("*.tres")
	editor_reference.godot_dialog_connect(self, "_on_Glossary_TitleFont_selected")


func _on_Glossary_TitleFontOpen_pressed():
	var theme = DialogicResources.get_theme_config(current_theme)
	editor_reference.editor_interface.inspect_object(load(theme.get_value('definitions', 'font', 'res://addons/dialogic/Example Assets/Fonts/GlossaryFont.tres')))


func _on_Glossary_TitleFont_selected(path, target) -> void:
	if loading:
		return
	DialogicResources.set_theme_value(current_theme, 'definitions', 'font', path)
	n['glossary_title_font'].text = DialogicResources.get_filename_from_path(path)
	_on_PreviewButton_pressed() # Refreshing the preview


func _on_Glossary_TitleColorPicker_color_changed(color):
	if loading:
		return
	DialogicResources.set_theme_value(current_theme, 'definitions', 'title_color', '#' + color.to_html())
	$DelayPreviewTimer.start(0.5) # Calling a timer so the update doesn't get triggered many times


## TEXT
func _on_Glossary_TextFontButton_pressed():
	editor_reference.godot_dialog("*.tres")
	editor_reference.godot_dialog_connect(self, "_on_Glossary_TextFont_selected")


func _on_Glossary_TextFont_selected(path, target):
	if loading:
		return
	DialogicResources.set_theme_value(current_theme, 'definitions', 'text_font', path)
	n['glossary_text_font'].text = DialogicResources.get_filename_from_path(path)
	_on_PreviewButton_pressed() # Refreshing the preview


func _on_Glossary_TextFontOpen_pressed():
	var theme = DialogicResources.get_theme_config(current_theme)
	editor_reference.editor_interface.inspect_object(load(theme.get_value('definitions', 'text_font', 'res://addons/dialogic/Example Assets/Fonts/GlossaryFont.tres')))


func _on_Glossary_TextColorPicker_color_changed(color):
	if loading:
		return
	DialogicResources.set_theme_value(current_theme, 'definitions', 'text_color', '#' + color.to_html())
	$DelayPreviewTimer.start(0.5) # Calling a timer so the update doesn't get triggered many times


## EXTRA FONT
func _on_Glossary_ExtraFontButton_pressed():
	editor_reference.godot_dialog("*.tres")
	editor_reference.godot_dialog_connect(self, "_on_Glossary_ExtraFont_selected")


func _on_Glossary_ExtraFont_selected(path, target):
	if loading:
		return
	DialogicResources.set_theme_value(current_theme, 'definitions', 'extra_font', path)
	n['glossary_extra_font'].text = DialogicResources.get_filename_from_path(path)
	_on_PreviewButton_pressed() # Refreshing the preview


func _on_Glossary_ExtraFontOpen_pressed():
	var theme = DialogicResources.get_theme_config(current_theme)
	editor_reference.editor_interface.inspect_object(load(theme.get_value('definitions', 'extra_font', 'res://addons/dialogic/Example Assets/Fonts/GlossaryFont.tres')))


func _on_Glossary_ExtraColorPicker_color_changed(color):
	if loading:
		return
	DialogicResources.set_theme_value(current_theme, 'definitions', 'extra_color', '#' + color.to_html())
	$DelayPreviewTimer.start(0.5) # Calling a timer so the update doesn't get triggered many times


## HIGHLIGHT COLOR
func _on_Glossary_HighlightColorPicker_color_changed(color):
	if loading:
		return
	DialogicResources.set_theme_value(current_theme, 'definitions', 'color', '#' + color.to_html())
	$DelayPreviewTimer.start(0.5) # Calling a timer so the update doesn't get triggered many times

## BACKGROUNDPANEL


func _on_BgPanelSelection_pressed():
	editor_reference.godot_dialog("*.tres")
	editor_reference.godot_dialog_connect(self, "_on_Glossary_BackgroundPanel_selected")


func _on_BGPanelOpen_pressed():
	var theme = DialogicResources.get_theme_config(current_theme)
	editor_reference.editor_interface.inspect_object(load(theme.get_value('definitions', 'background_panel', 'res://addons/dialogic/Example Assets/backgrounds/GlossaryBackground.tres')))


func _on_Glossary_BackgroundPanel_selected(path, target):
	if loading:
		return
	DialogicResources.set_theme_value(current_theme, 'definitions', 'background_panel', path)
	n['glossary_background_panel'].text = DialogicResources.get_filename_from_path(path)
	_on_PreviewButton_pressed() # Refreshing the preview

## ------------ 		AUDIO  TAB	 	------------------------------------
func _on_TypingPathButton_pressed() -> void:
	editor_reference.godot_dialog("*.ogg, *.wav", EditorFileDialog.MODE_OPEN_ANY)
	editor_reference.godot_dialog_connect(self, "_on_typingPath_selected", ["dir_selected", "file_selected"])

func _on_typingPath_selected(path, target) -> void:
	if loading:
		return
	DialogicResources.set_theme_value(current_theme, 'typing_sfx', 'path', path)
	n['typing_sfx_path'].text = DialogicResources.get_filename_from_path(path)
	_on_PreviewButton_pressed() # Refreshing the preview


func _on_TypingInterruptCheckBox_toggled(button_pressed):
	if loading:
		return
	DialogicResources.set_theme_value(current_theme, 'typing_sfx', 'allow_interrupt', button_pressed)
	_on_PreviewButton_pressed() # Refreshing the preview


func _on_TypingAudioBusButton_item_selected(index):
	if loading:
		return
	DialogicResources.set_theme_value(current_theme, 'typing_sfx', 'audio_bus', AudioServer.get_bus_name(index))

func _on_bus_layout_changed():
	update_audio_bus_option_buttons()

func update_audio_bus_option_buttons():
	var theme = DialogicResources.get_theme_config(current_theme)
	if theme != null:
		n['typing_sfx_audio_bus'].clear()
		for i in range(AudioServer.bus_count):
			var bus_name = AudioServer.get_bus_name(i)
			n['typing_sfx_audio_bus'].add_item(bus_name)
			if bus_name == theme.get_value('typing_sfx', 'audio_bus', "Master"):
				n['typing_sfx_audio_bus'].select(i)
