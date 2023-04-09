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

@export_subgroup("Name Label")
#@export var name_label_alignment = Alignments.Left
@export var name_label_font_size := 15
@export_file('*.ttf') var name_label_font : String = ""
@export var name_label_use_character_color := true
@export var name_label_color := Color.WHITE
@export var name_label_box_modulate : Color = box_modulate

## FOR TESTING PURPOSES
func _ready():
	add_to_group('dialogic_main_node')
	
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
	%TextInputPanel.self_modulate = box_modulate
	
	## NAME LABEL SETTINGS
	%DialogicNode_NameLabel.add_theme_font_size_override("font_size", name_label_font_size)
	
	if !name_label_font.is_empty():
		%DialogicNode_NameLabel.add_theme_font_override('font', load(name_label_font))
	
	%DialogicNode_NameLabel.add_theme_color_override("font_color", name_label_color)
	
	%DialogicNode_NameLabel.use_character_color = name_label_use_character_color
	
	%NameLabelPanel.self_modulate = name_label_box_modulate
