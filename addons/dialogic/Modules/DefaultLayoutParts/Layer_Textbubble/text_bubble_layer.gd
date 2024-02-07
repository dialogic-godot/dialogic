@tool
extends DialogicLayoutLayer

## This layout won't do anything on it's own

@export_group("Main")
@export_subgroup("Text")
@export var text_size: int = 15
@export var text_color: Color = Color.BLACK
@export_file('*.ttf') var normal_font: String = ""
@export_file('*.ttf') var bold_font: String = ""
@export_file('*.ttf') var italic_font: String = ""
@export_file('*.ttf') var bold_italic_font: String = ""
@export var text_max_width: int = 300

@export_subgroup('Box')
@export var box_modulate: Color = Color.WHITE
@export var box_modulate_by_character_color: bool = false
@export var box_padding: Vector2 = Vector2(10,10)
@export_range(1, 999) var box_corner_radius: int = 25
@export_range(0.1, 5) var box_wobble_speed: float = 1
@export_range(0, 1) var box_wobbliness: float = 0.2

@export_subgroup('Behaviour')
@export var behaviour_distance: int = 50
@export var behaviour_direction: Vector2 = Vector2(1, -1)

@export_group('Name Label')
@export_subgroup("Name Label")
@export var name_label_enabled: bool = true
@export var name_label_font_size: int = 15
@export_file('*.ttf') var name_label_font: String = ""
@export var name_label_use_character_color: bool = true
@export var name_label_color: Color = Color.BLACK
@export_subgroup("Name Label Box")
@export var name_label_box_modulate: Color = Color.WHITE
@export var name_label_padding: Vector2 = Vector2(5,0)
@export var name_label_offset: Vector2 = Vector2(0,0)

@export_group('Choices')
@export_subgroup('Choices Text')
@export var choices_text_size: int = 15
@export_file('*.ttf') var choices_text_font: String = ""
@export var choices_text_color: Color = Color.DARK_SLATE_GRAY
@export var choices_text_color_hover: Color = Color.DARK_MAGENTA
@export var choices_text_color_focus: Color = Color.DARK_MAGENTA
@export var choices_text_color_disabled: Color = Color.DARK_GRAY

@export_subgroup('Choices Layout')
@export var choices_layout_alignment := FlowContainer.ALIGNMENT_END
@export var choices_layout_force_lines: bool = false
@export_file('*.tres', "*.res") var choices_base_theme: String = ""

const TextBubble := preload("res://addons/dialogic/Modules/DefaultLayoutParts/Layer_Textbubble/text_bubble.gd")

var bubbles: Array[TextBubble] = []
var fallback_bubble: TextBubble = null

const textbubble_scene: PackedScene = preload("res://addons/dialogic/Modules/DefaultLayoutParts/Layer_Textbubble/text_bubble.tscn")


func add_bubble() -> TextBubble:
	var new_bubble: TextBubble = textbubble_scene.instantiate()
	add_child(new_bubble)
	bubble_apply_overrides(new_bubble)
	bubbles.append(new_bubble)
	return new_bubble



## Called by dialogic whenever export overrides might change
func _apply_export_overrides() -> void:
	for bubble: TextBubble in bubbles:
		bubble_apply_overrides(bubble)

	if fallback_bubble:
		bubble_apply_overrides(fallback_bubble)


func bubble_apply_overrides(bubble:TextBubble) -> void:
	## TEXT FONT AND COLOR
	var rtl: RichTextLabel = bubble.get_dialog_text()
	rtl.add_theme_font_size_override(&'normal_font', text_size)
	rtl.add_theme_font_size_override(&"normal_font_size", text_size)
	rtl.add_theme_font_size_override(&"bold_font_size", text_size)
	rtl.add_theme_font_size_override(&"italics_font_size", text_size)
	rtl.add_theme_font_size_override(&"bold_italics_font_size", text_size)

	rtl.add_theme_color_override(&"default_color", text_color)

	if !normal_font.is_empty():
		rtl.add_theme_font_override(&"normal_font", load(normal_font) as Font)
	if !bold_font.is_empty():
		rtl.add_theme_font_override(&"bold_font", load(bold_font) as Font)
	if !italic_font.is_empty():
		rtl.add_theme_font_override(&"italitc_font", load(italic_font) as Font)
	if !bold_italic_font.is_empty():
		rtl.add_theme_font_override(&"bold_italics_font", load(bold_italic_font) as Font)
	bubble.set(&'max_width', text_max_width)


	## BOX & TAIL COLOR
	var tail: Line2D = bubble.get_tail()
	var background: Control = bubble.get_bubble()
	var bubble_material: ShaderMaterial = background.get(&'material')

	tail.default_color = box_modulate
	background.set(&'color', box_modulate)
	bubble_material.set_shader_parameter(&'radius', box_corner_radius)
	bubble_material.set_shader_parameter(&'crease', box_wobbliness*0.1)
	bubble_material.set_shader_parameter(&'speed', box_wobble_speed)
	if box_modulate_by_character_color and bubble.character != null:
		tail.modulate = bubble.character.color
		background.modulate = bubble.character.color
	bubble.padding = box_padding

	## NAME LABEL SETTINGS
	var nl: DialogicNode_NameLabel = bubble.get_name_label()
	nl.add_theme_font_size_override(&"font_size", name_label_font_size)

	if !name_label_font.is_empty():
		nl.add_theme_font_override(&'font', load(name_label_font) as Font)

	nl.use_character_color = name_label_use_character_color
	if !nl.use_character_color:
		nl.add_theme_color_override(&"font_color", name_label_color)

	var nlp: PanelContainer = bubble.get_name_label_panel()
	nlp.self_modulate = name_label_box_modulate
	nlp.get_theme_stylebox(&'panel').content_margin_left = name_label_padding.x
	nlp.get_theme_stylebox(&'panel').content_margin_right = name_label_padding.x
	nlp.get_theme_stylebox(&'panel').content_margin_top = name_label_padding.y
	nlp.get_theme_stylebox(&'panel').content_margin_bottom = name_label_padding.y
	nlp.position += name_label_offset

	if !name_label_enabled:
		nlp.queue_free()


	## CHOICE SETTINGS
	var choice_theme: Theme = Theme.new()
	choice_theme.set_font_size(&'font_size', &'Button', choices_text_size)
	choice_theme.set_color(&'font_color', &'Button', choices_text_color)
	choice_theme.set_color(&'font_pressed_color', &'Button', choices_text_color)
	choice_theme.set_color(&'font_hover_color', &'Button', choices_text_color_hover)
	choice_theme.set_color(&'font_focus_color', &'Button', choices_text_color_focus)

	bubble.get_choice_container().theme = choice_theme

	## BEHAVIOUR
	bubble.safe_zone = behaviour_distance
	bubble.base_direction = behaviour_direction


