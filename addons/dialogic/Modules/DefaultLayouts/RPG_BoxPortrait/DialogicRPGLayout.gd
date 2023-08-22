extends CanvasLayer

enum Alignments {LEFT, CENTER, RIGHT}
enum LimitedAlignments {LEFT=0, RIGHT=1}

@export_group('Main')
@export_subgroup("Text")
@export var text_alignment :Alignments= Alignments.LEFT
@export var text_size := 15
@export var text_color : Color = Color.WHITE
@export_file('*.ttf') var normal_font:String = ""
@export_file('*.ttf') var bold_font:String = ""
@export_file('*.ttf') var italic_font:String = ""
@export_file('*.ttf') var bold_italic_font:String = ""

@export_subgroup("Name Label")
@export var name_label_alignment := Alignments.LEFT
@export var name_label_font_size := 15
@export var name_label_color := Color.WHITE
@export var name_label_use_character_color := true
@export_file('*.ttf') var name_label_font : String = ""
@export var name_label_hide_when_no_character := false

@export_group('Box & Portrait')
@export_subgroup("Box")
@export var box_modulate : Color = Color(0.47247135639191, 0.31728461384773, 0.16592600941658)
@export var box_size : Vector2 = Vector2(600, 160)
@export var box_distance := 25
@export var box_corner_radius := 5
@export var box_padding := 10
@export_range(-0.3, 0.3) var box_tilt := 0.079

@export_subgroup('Portrait')
@export var portrait_stretch_factor = 0.3
@export var portrait_position :LimitedAlignments = LimitedAlignments.LEFT
@export var portrait_bg_modulate := Color(0, 0, 0, 0.5137255191803)


## Called by dialogic whenever export overrides might change
func _apply_export_overrides():
	if !is_inside_tree():
		await ready
	
	## FONT SETTINGS
	%DialogicNode_DialogText.alignment = text_alignment
	
	%DialogicNode_DialogText.add_theme_font_size_override("normal_font_size", text_size)
	%DialogicNode_DialogText.add_theme_font_size_override("bold_font_size", text_size)
	%DialogicNode_DialogText.add_theme_font_size_override("italics_font_size", text_size)
	%DialogicNode_DialogText.add_theme_font_size_override("bold_italics_font_size", text_size)
	
	%DialogicNode_DialogText.add_theme_color_override("default_color", text_color)
	
	if !normal_font.is_empty():
		%DialogicNode_DialogText.add_theme_font_override("normal_font", load(normal_font))
	if !bold_font.is_empty():
		%DialogicNode_DialogText.add_theme_font_override("bold_font", load(bold_font))
	if !italic_font.is_empty():
		%DialogicNode_DialogText.add_theme_font_override("italitc_font", load(italic_font))
	if !bold_italic_font.is_empty():
		%DialogicNode_DialogText.add_theme_font_override("bold_italics_font", load(bold_italic_font))
	
	## BOX SETTINGS
	%Panel.self_modulate = box_modulate
	%Panel.size = box_size
	%Panel.position = Vector2(-box_size.x/2, -box_size.y-box_distance)
	%PortraitPanel.size_flags_stretch_ratio = portrait_stretch_factor
	
	var stylebox :StyleBoxFlat = %Panel.get_theme_stylebox('panel', 'PanelContainer')
	stylebox.set_corner_radius_all(box_corner_radius)
	stylebox.set_content_margin_all(box_padding)
	stylebox.skew.x = box_tilt
	
	## PORTRAIT SETTINGS
	%PortraitBackgroundColor.color = portrait_bg_modulate
	%PortraitPanel.get_parent().move_child(%PortraitPanel, portrait_position)
	stylebox = %PortraitPanel.get_theme_stylebox('panel', 'Panel')
	stylebox.set_corner_radius_all(box_corner_radius)
	stylebox.skew.x = box_tilt
	
	## NAME LABEL SETTINGS
	%DialogicNode_NameLabel.add_theme_font_size_override("font_size", name_label_font_size)
	
	if !name_label_font.is_empty():
		%DialogicNode_NameLabel.add_theme_font_override('font', load(name_label_font))
	
	%DialogicNode_NameLabel.add_theme_color_override("font_color", name_label_color)
	%DialogicNode_NameLabel.use_character_color = name_label_use_character_color
	%DialogicNode_NameLabel.horizontal_alignment = name_label_alignment
	
	%DialogicNode_NameLabel.hide_when_empty = name_label_hide_when_no_character
