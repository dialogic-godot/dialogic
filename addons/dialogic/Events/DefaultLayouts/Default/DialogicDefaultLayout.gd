@tool
extends CanvasLayer

enum Alignments {Left, Center, Right}

@export_group("Main")
@export_subgroup("Font")
@export var font_size := 15
@export var text_alignment :Alignments= Alignments.Left

## FOR TESTING PURPOSES
func _ready():
	add_to_group('dialogic_main_node')
	
	%DialogicNode_DialogText.add_theme_font_size_override("normal_font_size", font_size)
	%DialogicNode_DialogText.alignment = text_alignment
