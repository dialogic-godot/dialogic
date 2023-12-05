@tool
extends DialogicLayoutLayer

enum Alignments {LEFT, CENTER, RIGHT}
enum LimitedAlignments {LEFT=0, RIGHT=1}

@export_group('Text')
@export_subgroup("Text")
@export var text_alignment :Alignments= Alignments.LEFT
@export_subgroup('Size')
@export var text_use_global_size := true
@export var text_custom_size := 15
@export_subgroup('Color')
@export var text_use_global_color := true
@export var text_custom_color : Color = Color.WHITE
@export_subgroup('Fonts')
@export var use_global_fonts := true
@export_file('*.ttf') var custom_normal_font:String = ""
@export_file('*.ttf') var custom_bold_font:String = ""
@export_file('*.ttf') var custom_italic_font:String = ""
@export_file('*.ttf') var custom_bold_italic_font:String = ""

@export_group('Name Label')
@export_subgroup("Color")
enum NameLabelColorModes {GLOBAL_COLOR, CHARACTER_COLOR, CUSTOM_COLOR}
@export var name_label_color_mode := NameLabelColorModes.GLOBAL_COLOR
@export var name_label_custom_color := Color.WHITE
@export_subgroup("Behaviour")
@export var name_label_alignment := Alignments.LEFT
@export var name_label_hide_when_no_character := false
@export_subgroup("Font & Size")
@export var name_label_use_global_size := true
@export var name_label_custom_size := 15
@export var name_label_use_global_font := true
@export_file('*.ttf') var name_label_customfont : String = ""

@export_group('Box')
@export_subgroup("Box")
@export_file('*.tres') var box_panel := this_folder.path_join("default_stylebox.tres")
@export var box_modulate_global_color := true
@export var box_modulate_custom_color : Color = Color(0.47247135639191, 0.31728461384773, 0.16592600941658)
@export var box_size : Vector2 = Vector2(600, 160)
@export var box_distance := 25

@export_group('Portrait')
@export_subgroup('Portrait')
@export var portrait_stretch_factor = 0.3
@export var portrait_position :LimitedAlignments = LimitedAlignments.LEFT
@export var portrait_bg_modulate := Color(0, 0, 0, 0.5137255191803)


## Called by dialogic whenever export overrides might change
func _apply_export_overrides():
	## FONT SETTINGS
	%DialogicNode_DialogText.alignment = text_alignment

	var text_size := text_custom_size
	if text_use_global_size:
		text_size = get_global_setting('font_size', text_custom_size)

	%DialogicNode_DialogText.add_theme_font_size_override("normal_font_size", text_size)
	%DialogicNode_DialogText.add_theme_font_size_override("bold_font_size", text_size)
	%DialogicNode_DialogText.add_theme_font_size_override("italics_font_size", text_size)
	%DialogicNode_DialogText.add_theme_font_size_override("bold_italics_font_size", text_size)


	var text_color := text_custom_color
	if text_use_global_color:
		text_color = get_global_setting('font_color', text_custom_color)
	%DialogicNode_DialogText.add_theme_color_override("default_color", text_color)

	var normal_font := custom_normal_font
	if use_global_fonts and ResourceLoader.exists(get_global_setting('font', '')):
		normal_font = get_global_setting('font', '')

	if !normal_font.is_empty():
		%DialogicNode_DialogText.add_theme_font_override("normal_font", load(normal_font))
	if !custom_bold_font.is_empty():
		%DialogicNode_DialogText.add_theme_font_override("bold_font", load(custom_bold_font))
	if !custom_italic_font.is_empty():
		%DialogicNode_DialogText.add_theme_font_override("italitc_font", load(custom_italic_font))
	if !custom_bold_italic_font.is_empty():
		%DialogicNode_DialogText.add_theme_font_override("bold_italics_font", load(custom_bold_italic_font))

	## BOX SETTINGS
	if box_modulate_global_color:
		%Panel.self_modulate = get_global_setting('bg_color', box_modulate_custom_color)
	else:
		%Panel.self_modulate = box_modulate_custom_color
	%Panel.size = box_size
	%Panel.position = Vector2(-box_size.x/2, -box_size.y-box_distance)
	%PortraitPanel.size_flags_stretch_ratio = portrait_stretch_factor

	var stylebox: StyleBoxFlat = load(box_panel)
	%Panel.add_theme_stylebox_override('panel', stylebox)

	## PORTRAIT SETTINGS
	%PortraitBackgroundColor.color = portrait_bg_modulate
	%PortraitPanel.get_parent().move_child(%PortraitPanel, portrait_position)

	## NAME LABEL SETTINGS
	if name_label_use_global_size:
		%DialogicNode_NameLabel.add_theme_font_size_override("font_size", get_global_setting('font_size', name_label_custom_size))
	else:
		%DialogicNode_NameLabel.add_theme_font_size_override("font_size", name_label_custom_size)

	var name_label_font := name_label_customfont
	if name_label_use_global_font and ResourceLoader.exists(get_global_setting('font', '')):
		name_label_font = get_global_setting('font', '')
	if !name_label_font.is_empty():
		%DialogicNode_NameLabel.add_theme_font_override('font', load(name_label_font))

	%DialogicNode_NameLabel.use_character_color = false
	match name_label_color_mode:
		NameLabelColorModes.GLOBAL_COLOR:
			%DialogicNode_NameLabel.add_theme_color_override("font_color", get_global_setting('font_color', name_label_custom_color))
		NameLabelColorModes.CUSTOM_COLOR:
			%DialogicNode_NameLabel.add_theme_color_override("font_color", name_label_custom_color)
		NameLabelColorModes.CHARACTER_COLOR:
			%DialogicNode_NameLabel.use_character_color = true

	%DialogicNode_NameLabel.horizontal_alignment = name_label_alignment
	%DialogicNode_NameLabel.hide_when_empty = name_label_hide_when_no_character
