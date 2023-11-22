@tool
extends DialogicLayoutLayer

## A layer that allows showing up to 10 choices.
## Choices are positioned in the center of the screen.

@export_group("Text")
@export_subgroup('Font')
@export var font_use_global := true
@export_file('*.ttf') var font_custom : String = ""
@export_subgroup('Size')
@export var font_size_use_global := true
@export var font_size_custom := 16
@export_subgroup('Color')
@export var text_color_use_global := true
@export var text_color_custom := Color.WHITE
@export var text_color_pressed := Color.WHITE
@export var text_color_hovered := Color.GRAY
@export var text_color_disabled := Color.DARK_GRAY
@export var text_color_focused := Color.WHITE

@export_group('Boxes')
@export_subgroup('Panels')
@export_file('*.tres') var boxes_stylebox_normal := "res://addons/dialogic/Modules/DefaultLayoutParts/Layer_VN_Choices/choice_panel_normal.tres"
@export_file('*.tres') var boxes_stylebox_hovered := "res://addons/dialogic/Modules/DefaultLayoutParts/Layer_VN_Choices/choice_panel_hover.tres"
@export_file('*.tres') var boxes_stylebox_pressed := ""
@export_file('*.tres') var boxes_stylebox_disabled := ""
@export_file('*.tres') var boxes_stylebox_focused := "res://addons/dialogic/Modules/DefaultLayoutParts/Layer_VN_Choices/choice_panel_focus.tres"
@export_subgroup('Modulate')
@export_subgroup('Size & Position')
@export var boxes_v_separation := 10
@export var boxes_fill_width := true
@export var boxes_min_size := Vector2()

@export_group('Sounds')
@export_range(-80, 24, 0.01) var sounds_volume := -10
@export_file("*.wav", "*.ogg", "*.mp3") var sounds_pressed := "res://addons/dialogic/Example Assets/sound-effects/typing1.wav"
@export_file("*.wav", "*.ogg", "*.mp3") var sounds_hover := "res://addons/dialogic/Example Assets/sound-effects/typing2.wav"
@export_file("*.wav", "*.ogg", "*.mp3") var sounds_focus := "res://addons/dialogic/Example Assets/sound-effects/typing4.wav"


## Method that applies all exported settings
func _apply_export_overrides():
	# apply text settings
	var theme: Theme = Theme.new()

	# font
	if font_use_global and get_global_setting('font', false):
		theme.set_font('font', 'Button', load(get_global_setting('font', '')))
	elif ResourceLoader.exists(font_custom):
		theme.set_font('font', 'Button', load(font_custom))

	# font size
	if font_size_use_global:
		theme.set_font_size('font_size', 'Button', get_global_setting('font_size', font_size_custom))
	else:
		theme.set_font_size('font_size', 'Button', font_size_custom)

	# font color
	if text_color_use_global:
		theme.set_color('font_color', 'Button', get_global_setting('font_color', text_color_custom))
	else:
		theme.set_color('font_color', 'Button', text_color_custom)

	theme.set_color('font_pressed_color', 'Button', text_color_pressed)
	theme.set_color('font_hover_color', 'Button', text_color_hovered)
	theme.set_color('font_disabled_color', 'Button', text_color_disabled)
	theme.set_color('font_pressed_color', 'Button', text_color_pressed)
	theme.set_color('font_focus_color', 'Button', text_color_focused)


	# apply box settings
	if ResourceLoader.exists(boxes_stylebox_normal):
		var style_box: StyleBox = load(boxes_stylebox_normal)
		theme.set_stylebox('normal', 'Button', style_box)
		theme.set_stylebox('hover', 'Button', style_box)
		theme.set_stylebox('pressed', 'Button', style_box)
		theme.set_stylebox('disabled', 'Button', style_box)
		theme.set_stylebox('focus', 'Button', style_box)

	if ResourceLoader.exists(boxes_stylebox_hovered):
		theme.set_stylebox('hover', 'Button', load(boxes_stylebox_hovered))

	if ResourceLoader.exists(boxes_stylebox_pressed):
		theme.set_stylebox('pressed', 'Button', load(boxes_stylebox_pressed))
	if ResourceLoader.exists(boxes_stylebox_disabled):
		theme.set_stylebox('disabled', 'Button', load(boxes_stylebox_disabled))
	if ResourceLoader.exists(boxes_stylebox_focused):
		theme.set_stylebox('focus', 'Button', load(boxes_stylebox_focused))

	$Choices.add_theme_constant_override("separation", boxes_v_separation)

	for choice in $Choices.get_children():
		if not choice is DialogicNode_ChoiceButton:
			continue

		if boxes_fill_width:
			choice.size_flags_horizontal = Control.SIZE_FILL
		else:
			choice.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

		choice.custom_minimum_size = boxes_min_size

	self.theme = theme

	# apply sound settings
	%DialogicNode_ButtonSound.volume_db = sounds_volume
	%DialogicNode_ButtonSound.sound_pressed = load(sounds_pressed)
	%DialogicNode_ButtonSound.sound_hover = load(sounds_hover)
	%DialogicNode_ButtonSound.sound_focus = load(sounds_focus)
