@tool
extends DialogicLayoutLayer

## A layer that allows showing up to 10 choices.
## Choices are positioned in the center of the screen.

@export_group("Text")
@export_subgroup('Font')
@export var font_use_global: bool = true
@export_file('*.ttf', '*.tres') var font_custom: String = ""
@export_subgroup('Size')
@export var font_size_use_global: bool = true
@export var font_size_custom: int = 16
@export_subgroup('Color')
@export var text_color_use_global: bool = true
@export var text_color_custom: Color = Color.WHITE
@export var text_color_pressed: Color = Color.WHITE
@export var text_color_hovered: Color = Color.GRAY
@export var text_color_disabled: Color = Color.DARK_GRAY
@export var text_color_focused: Color = Color.WHITE

@export_group('Boxes')
@export_subgroup('Panels')
@export_file('*.tres') var boxes_stylebox_normal: String = "res://addons/dialogic/Modules/DefaultLayoutParts/Layer_VN_Choices/choice_panel_normal.tres"
@export_file('*.tres') var boxes_stylebox_hovered: String = "res://addons/dialogic/Modules/DefaultLayoutParts/Layer_VN_Choices/choice_panel_hover.tres"
@export_file('*.tres') var boxes_stylebox_pressed: String = ""
@export_file('*.tres') var boxes_stylebox_disabled: String = ""
@export_file('*.tres') var boxes_stylebox_focused: String = "res://addons/dialogic/Modules/DefaultLayoutParts/Layer_VN_Choices/choice_panel_focus.tres"
@export_subgroup('Modulate')
@export_subgroup('Size & Position')
@export var boxes_v_separation: int = 10
@export var boxes_fill_width: bool = true
@export var boxes_min_size: Vector2 = Vector2()

@export_group('Sounds')
@export_range(-80, 24, 0.01) var sounds_volume: float = -10
@export_file("*.wav", "*.ogg", "*.mp3") var sounds_pressed: String = "res://addons/dialogic/Example Assets/sound-effects/typing1.wav"
@export_file("*.wav", "*.ogg", "*.mp3") var sounds_hover: String = "res://addons/dialogic/Example Assets/sound-effects/typing2.wav"
@export_file("*.wav", "*.ogg", "*.mp3") var sounds_focus: String = "res://addons/dialogic/Example Assets/sound-effects/typing4.wav"

func get_choices() -> VBoxContainer:
	return $Choices


func get_button_sound() -> DialogicNode_ButtonSound:
	return %DialogicNode_ButtonSound


## Method that applies all exported settings
func _apply_export_overrides() -> void:
	# apply text settings
	var layer_theme: Theme = Theme.new()

	# font
	if font_use_global and get_global_setting(&'font', false):
		layer_theme.set_font(&'font', &'Button', load(get_global_setting(&'font', '') as String) as Font)
	elif ResourceLoader.exists(font_custom):
		layer_theme.set_font(&'font', &'Button', load(font_custom) as Font)

	# font size
	if font_size_use_global:
		layer_theme.set_font_size(&'font_size', &'Button', get_global_setting(&'font_size', font_size_custom) as int)
	else:
		layer_theme.set_font_size(&'font_size', &'Button', font_size_custom)

	# font color
	if text_color_use_global:
		layer_theme.set_color(&'font_color', &'Button', get_global_setting(&'font_color', text_color_custom) as Color)
	else:
		layer_theme.set_color(&'font_color', &'Button', text_color_custom)

	layer_theme.set_color(&'font_pressed_color', &'Button', text_color_pressed)
	layer_theme.set_color(&'font_hover_color', &'Button', text_color_hovered)
	layer_theme.set_color(&'font_disabled_color', &'Button', text_color_disabled)
	layer_theme.set_color(&'font_pressed_color', &'Button', text_color_pressed)
	layer_theme.set_color(&'font_focus_color', &'Button', text_color_focused)


	# apply box settings
	if ResourceLoader.exists(boxes_stylebox_normal):
		var style_box: StyleBox = load(boxes_stylebox_normal)
		layer_theme.set_stylebox(&'normal', &'Button', style_box)
		layer_theme.set_stylebox(&'hover', &'Button', style_box)
		layer_theme.set_stylebox(&'pressed', &'Button', style_box)
		layer_theme.set_stylebox(&'disabled', &'Button', style_box)
		layer_theme.set_stylebox(&'focus', &'Button', style_box)

	if ResourceLoader.exists(boxes_stylebox_hovered):
		layer_theme.set_stylebox(&'hover', &'Button', load(boxes_stylebox_hovered) as StyleBox)

	if ResourceLoader.exists(boxes_stylebox_pressed):
		layer_theme.set_stylebox(&'pressed', &'Button', load(boxes_stylebox_pressed) as StyleBox)
	if ResourceLoader.exists(boxes_stylebox_disabled):
		layer_theme.set_stylebox(&'disabled', &'Button', load(boxes_stylebox_disabled) as StyleBox)
	if ResourceLoader.exists(boxes_stylebox_focused):
		layer_theme.set_stylebox(&'focus', &'Button', load(boxes_stylebox_focused) as StyleBox)

	get_choices().add_theme_constant_override(&"separation", boxes_v_separation)

	for child: Node in get_choices().get_children():
		if not child is DialogicNode_ChoiceButton:
			continue
		var choice: DialogicNode_ChoiceButton = child as DialogicNode_ChoiceButton

		if boxes_fill_width:
			choice.size_flags_horizontal = Control.SIZE_FILL
		else:
			choice.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

		choice.custom_minimum_size = boxes_min_size

	set(&'theme', layer_theme)

	# apply sound settings
	var button_sound: DialogicNode_ButtonSound = get_button_sound()
	button_sound.volume_db = sounds_volume
	button_sound.sound_pressed = load(sounds_pressed)
	button_sound.sound_hover = load(sounds_hover)
	button_sound.sound_focus = load(sounds_focus)
