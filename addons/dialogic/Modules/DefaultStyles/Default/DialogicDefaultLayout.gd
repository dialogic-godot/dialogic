@tool
extends CanvasLayer

enum Alignments {Left, Center, Right}

@export_group("Main")
@export_subgroup("Text")
@export var text_alignment :Alignments= Alignments.Left
@export var text_size := 15
@export var text_color : Color = Color.WHITE
@export_file('*.ttf') var normal_font:String = ""
@export_file('*.ttf') var bold_font:String = ""
@export_file('*.ttf') var italic_font:String = ""
@export_file('*.ttf') var bold_italic_font:String = ""

@export_subgroup("Box")
@export var box_modulate : Color = Color(0.00784313771874, 0.00784313771874, 0.00784313771874, 0.84313726425171)
@export var box_size : Vector2 = Vector2(550, 110)

@export_subgroup("Name Label")
@export var name_label_alignment := Alignments.Left
@export var name_label_font_size := 15
@export var name_label_color := Color.WHITE
@export var name_label_use_character_color := true
@export_file('*.ttf') var name_label_font : String = ""
@export var name_label_box_modulate : Color = box_modulate
@export var name_label_box_offset := Vector2.ZERO


@export_group("Other")
@export_subgroup("Next Indicator")
@export var next_indicator_enabled := true
@export_enum('bounce', 'blink', 'none') var next_indicator_animation := 0
@export_file("*.png","*.svg") var next_indicator_texture := ''
@export var next_indicator_show_on_questions := true
@export var next_indicator_show_on_autoadvance := false


@export_subgroup('Portraits')
@export var portrait_size_mode := DialogicNode_PortraitContainer.SizeModes.FitScaleHeight


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
	%DialogTextPanel.self_modulate = box_modulate
	%DialogTextPanel.custom_minimum_size = box_size
	%TextInputPanel.self_modulate = box_modulate
	
	## NAME LABEL SETTINGS
	%DialogicNode_NameLabel.add_theme_font_size_override("font_size", name_label_font_size)
	
	if !name_label_font.is_empty():
		%DialogicNode_NameLabel.add_theme_font_override('font', load(name_label_font))
	
	%DialogicNode_NameLabel.add_theme_color_override("font_color", name_label_color)
	
	%DialogicNode_NameLabel.use_character_color = name_label_use_character_color
	
	%NameLabelPanel.self_modulate = name_label_box_modulate
	
	%NameLabelPanel.position = name_label_box_offset+Vector2(0, -50)
	%NameLabelPanel.anchor_left = name_label_alignment/2.0
	%NameLabelPanel.anchor_right = name_label_alignment/2.0
	%NameLabelPanel.grow_horizontal = [1, 2, 0][name_label_alignment]
	
	## NEXT INDICATOR SETTINGS
	if !next_indicator_enabled:
		%NextIndicator.queue_free()
	else:
		%NextIndicator.animation = next_indicator_animation
		if FileAccess.file_exists(next_indicator_texture):
			%NextIndicator.texture = load(next_indicator_texture)
		%NextIndicator.show_on_questions = next_indicator_show_on_questions
		%NextIndicator.show_on_autoadvance = next_indicator_show_on_autoadvance
	
	## PORTRAIT SETTINGS
	for child in %Portraits.get_children():
		child.size_mode = portrait_size_mode
