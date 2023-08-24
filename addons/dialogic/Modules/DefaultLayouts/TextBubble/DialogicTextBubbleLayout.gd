extends CanvasLayer

## This layout won't do anything on it's own

@export_group("Main")
@export_subgroup("Text")
@export var text_size := 15
@export var text_color : Color = Color.BLACK
@export_file('*.ttf') var normal_font:String = ""
@export_file('*.ttf') var bold_font:String = ""
@export_file('*.ttf') var italic_font:String = ""
@export_file('*.ttf') var bold_italic_font:String = ""
@export var text_max_width := 300

@export_subgroup('Box')
@export var box_modulate := Color.WHITE
@export var box_modulate_by_character_color := false
@export var box_padding := Vector2(10,10)
@export_range(0.1, 2) var box_corner_radius := 0.3
@export_range(0.1, 5) var box_wobble_speed := 1
@export_range(0, 1) var box_wobbliness := 0.2

@export_subgroup('Behaviour')
@export var behaviour_distance := 50
@export var behaviour_direction := Vector2(1, -1)

@export_group('Name Label & Choices')
@export_subgroup("Name Label")
@export var name_label_enabled := true
@export var name_label_font_size := 15
@export_file('*.ttf') var name_label_font : String = ""
@export var name_label_use_character_color := true
@export var name_label_color := Color.BLACK
@export var name_label_box_modulate : Color = Color.WHITE
@export var name_label_padding := Vector2(5,0)
@export var name_label_offset := Vector2(0,0)

@export_subgroup('Choices Text')
@export var choices_text_size := 15
@export var choices_text_color := Color.LIGHT_SLATE_GRAY
@export var choices_text_color_hover := Color.DARK_GRAY
@export var choices_text_color_focus := Color.BLACK


var bubbles :Array = []
var fallback_bubble :Control = null

func _ready():
	Dialogic.Text.about_to_show_text.connect(_on_dialogic_text_event)
	
	$Example/ExamplePoint.position = $Example.get_viewport_rect().size/2
	
	fallback_bubble = preload("res://addons/dialogic/Modules/DefaultLayouts/TextBubble/TextBubble.tscn").instantiate()
	fallback_bubble.speaker_node = $Example/ExamplePoint
	fallback_bubble.name = "Fallback Bubble"
	bubble_apply_overrides(fallback_bubble)
	add_child(fallback_bubble)


func register_character(character:DialogicCharacter, node:Node2D):
	var new_bubble := preload("res://addons/dialogic/Modules/DefaultLayouts/TextBubble/TextBubble.tscn").instantiate()
	new_bubble.speaker_node = node
	new_bubble.character = character
	new_bubble.name = character.resource_path.get_file().trim_suffix("."+character.resource_path.get_extension()) + "Bubble"
	add_child(new_bubble)
	bubble_apply_overrides(new_bubble)
	bubbles.append(new_bubble)


## Called by dialogic whenever export overrides might change
func _apply_export_overrides():
	for bubble in bubbles:
		bubble_apply_overrides(bubble)
	
	if fallback_bubble:
		bubble_apply_overrides(fallback_bubble)


func bubble_apply_overrides(bubble:Control) -> void:
	## TEXT FONT AND COLOR
	var rtl : RichTextLabel = bubble.get_node('DialogText')
	rtl.add_theme_font_size_override('normal_font', text_size)
	rtl.add_theme_font_size_override("normal_font_size", text_size)
	rtl.add_theme_font_size_override("bold_font_size", text_size)
	rtl.add_theme_font_size_override("italics_font_size", text_size)
	rtl.add_theme_font_size_override("bold_italics_font_size", text_size)
	
	rtl.add_theme_color_override("default_color", text_color)
	
	if !normal_font.is_empty():
		rtl.add_theme_font_override("normal_font", load(normal_font))
	if !bold_font.is_empty():
		rtl.add_theme_font_override("bold_font", load(bold_font))
	if !italic_font.is_empty():
		rtl.add_theme_font_override("italitc_font", load(italic_font))
	if !bold_italic_font.is_empty():
		rtl.add_theme_font_override("bold_italics_font", load(bold_italic_font))
	bubble.max_width = text_max_width
	
	
	## BOX & TAIL COLOR
	bubble.get_node('Tail').default_color = box_modulate
	bubble.get_node('Background').color = box_modulate
	bubble.get_node('Background').material.set_shader_parameter('radius', box_corner_radius)
	bubble.get_node('Background').material.set_shader_parameter('crease', box_wobbliness*0.1)
	bubble.get_node('Background').material.set_shader_parameter('speed', box_wobble_speed)
	if box_modulate_by_character_color and bubble.character != null:
		bubble.get_node('Tail').modulate = bubble.character.color
		bubble.get_node('Background').modulate = bubble.character.color
	bubble.padding = box_padding
	
	## NAME LABEL SETTINGS
	var nl : Label = bubble.get_node('%NameLabel') 
	nl.add_theme_font_size_override("font_size", name_label_font_size)
	
	if !name_label_font.is_empty():
		nl.add_theme_font_override('font', load(name_label_font))
	
	nl.use_character_color = name_label_use_character_color
	if !nl.use_character_color:
		nl.add_theme_color_override("font_color", name_label_color)
	
	var nlp : Container = bubble.get_node('DialogText/NameLabel')
	nlp.self_modulate = name_label_box_modulate
	nlp.get_theme_stylebox('panel').content_margin_left = name_label_padding.x
	nlp.get_theme_stylebox('panel').content_margin_right = name_label_padding.x
	nlp.get_theme_stylebox('panel').content_margin_top = name_label_padding.y
	nlp.get_theme_stylebox('panel').content_margin_bottom = name_label_padding.y
	nlp.position += name_label_offset
	
	if !name_label_enabled:
		nlp.queue_free()
	
	
	## CHOICE SETTINGS
	var choice_theme := Theme.new()
	choice_theme.set_font_size('font_size', 'Button', choices_text_size)
	choice_theme.set_color('font_color', 'Button', choices_text_color)
	choice_theme.set_color('font_pressed_color', 'Button', choices_text_color)
	choice_theme.set_color('font_hover_color', 'Button', choices_text_color_hover)
	choice_theme.set_color('font_focus_color', 'Button', choices_text_color_focus)
	
	bubble.get_node('DialogText/ChoiceContainer').theme = choice_theme
	
	## BEHAVIOUR
	bubble.safe_zone = behaviour_distance
	bubble.base_direction = behaviour_direction


func _on_dialogic_text_event(info:Dictionary):
	var no_bubble_open := true
	for b in bubbles:
		if b.character == info.character:
			no_bubble_open = false
			b.open()
		else:
			b.close()
	if no_bubble_open:
		if box_modulate_by_character_color and info.character != null:
			fallback_bubble.get_node('Tail').modulate = info.character.color
			fallback_bubble.get_node('Background').modulate = info.character.color
		$Example.show()
		fallback_bubble.open()
	else:
		$Example.hide()
		fallback_bubble.close()
