@tool
extends DialogicLayoutLayer

## A layer that contains
## - a dialog_text node
## - a name_label node
## - a next_indicator node
## - a type_sound node
##
## as well as custom
## - animations
## - auto-advance progress indicator


enum Alignments {LEFT, CENTER, RIGHT}

enum AnimationsIn {NONE, POP_IN, FADE_UP}
enum AnimationsOut {NONE, POP_OUT, FADE_DOWN}
enum AnimationsNewText {NONE, WIGGLE}

@export_group("Text")
@export_subgroup("Alignment & Size")
@export var text_alignment :Alignments= Alignments.LEFT
@export var text_use_global_size := true
@export var text_size := 15

@export_subgroup("Color")
@export var text_use_global_color := true
@export var text_custom_color : Color = Color.WHITE

@export_subgroup('Font')
@export var text_use_global_font := true
@export_file('*.ttf') var normal_font:String = ""
@export_file('*.ttf') var bold_font:String = ""
@export_file('*.ttf') var italic_font:String = ""
@export_file('*.ttf') var bold_italic_font:String = ""

@export_group("Box")
@export_subgroup("Panel")
@export_file("*.tres") var box_panel := this_folder.path_join("vn_textbox_default_panel.tres")
@export_subgroup("Color")
@export var box_color_use_global := true
@export var box_color_custom : Color = Color.BLACK
@export_subgroup("Size & Position")
@export var box_size : Vector2 = Vector2(550, 110)
@export var box_margin_bottom := 15
@export_subgroup("Animation")
@export var box_animation_in := AnimationsIn.FADE_UP
@export var box_animation_out := AnimationsOut.FADE_DOWN
@export var box_animation_new_text := AnimationsNewText.NONE

@export_group("Name Label")
@export_subgroup('Color')
@export var name_label_use_global_color := true
@export var name_label_use_character_color := true
@export var name_label_custom_color := Color.WHITE
@export_subgroup('Font')
@export var name_label_use_global_font := true
@export_file('*.ttf') var name_label_font : String = ""
@export var name_label_use_global_font_size := true
@export var name_label_custom_font_size := 15
@export_subgroup('Box')
@export_file("*.tres") var name_label_box_panel := this_folder.path_join("vn_textbox_name_label_panel.tres")
@export var name_label_box_use_global_color := true
@export var name_label_box_modulate : Color = box_color_custom
@export_subgroup('Alignment')
@export var name_label_alignment := Alignments.LEFT
@export var name_label_box_offset := Vector2.ZERO

@export_group("Indicators")
@export_subgroup("Next Indicator")
@export var next_indicator_enabled := true
@export var next_indicator_show_on_questions := true
@export var next_indicator_show_on_autoadvance := false
@export_enum('bounce', 'blink', 'none') var next_indicator_animation := 0
@export_file("*.png","*.svg") var next_indicator_texture := ''
@export var next_indicator_size := Vector2(25,25)

@export_subgroup("Autoadvance")
@export var autoadvance_progressbar := true

@export_group('Sounds')
@export_subgroup('Typing Sounds')
@export var typing_sounds_enabled := true
@export var typing_sounds_mode := DialogicNode_TypeSounds.Modes.INTERRUPT
@export_dir var typing_sounds_sounds_folder := "res://addons/dialogic/Example Assets/sound-effects/"
@export_file("*.wav", "*.ogg", "*.mp3") var typing_sounds_end_sound := ""
@export_range(1, 999, 1) var typing_sounds_every_nths_character := 1
@export_range(0.01, 4, 0.01) var typing_sounds_pitch := 1.0
@export_range(0.0, 3.0) var typing_sounds_pitch_variance := 0.0
@export_range(-80, 24, 0.01) var typing_sounds_volume := -10
@export_range(0.0, 10) var typing_sounds_volume_variance := 0.0
@export var typing_sounds_ignore_characters := " .,!?"


func _apply_export_overrides():
	if !is_inside_tree():
		await ready

	## FONT SETTINGS
	%DialogicNode_DialogText.alignment = text_alignment

	if text_use_global_size:
		text_size = get_global_setting('font_size', text_size)
	%DialogicNode_DialogText.add_theme_font_size_override("normal_font_size", text_size)
	%DialogicNode_DialogText.add_theme_font_size_override("bold_font_size", text_size)
	%DialogicNode_DialogText.add_theme_font_size_override("italics_font_size", text_size)
	%DialogicNode_DialogText.add_theme_font_size_override("bold_italics_font_size", text_size)

	if text_use_global_color:
		%DialogicNode_DialogText.add_theme_color_override("default_color", get_global_setting('font_color', text_custom_color))
	else:
		%DialogicNode_DialogText.add_theme_color_override("default_color", text_custom_color)

	if text_use_global_font and get_global_setting('font', false):
		%DialogicNode_DialogText.add_theme_font_override("normal_font", load(get_global_setting('font', '')))
	elif !normal_font.is_empty():
		%DialogicNode_DialogText.add_theme_font_override("normal_font", load(normal_font))
	if !bold_font.is_empty():
		%DialogicNode_DialogText.add_theme_font_override("bold_font", load(bold_font))
	if !italic_font.is_empty():
		%DialogicNode_DialogText.add_theme_font_override("italitc_font", load(italic_font))
	if !bold_italic_font.is_empty():
		%DialogicNode_DialogText.add_theme_font_override("bold_italics_font", load(bold_italic_font))

	## BOX SETTINGS
	if ResourceLoader.exists(box_panel):
		%DialogTextPanel.add_theme_stylebox_override('panel', load(box_panel))

	if box_color_use_global:
		%DialogTextPanel.self_modulate = get_global_setting('bg_color', box_color_custom)
	else:
		%DialogTextPanel.self_modulate = box_color_custom

	#%DialogTextPanel.hide()
	#%Minimizer.size = Vector2.ZERO
	#%Minimizer.position = Vector2(0, -box_margin_bottom)
	#%Minimizer.grow_vertical = Container.GROW_DIRECTION_BEGIN
	#%DialogTextPanel.custom_minimum_size = box_size
	#%DialogTextPanel.show()
	%Sizer.size = box_size
	%Sizer.position = box_size * Vector2(-0.5, -1)+Vector2(0, -box_margin_bottom)


	## BOX ANIMATIONS
	%Animations.animation_in = box_animation_in
	%Animations.animation_out = box_animation_out
	%Animations.animation_new_text = box_animation_new_text

	## NAME LABEL SETTINGS
	if name_label_use_global_font_size:
		%DialogicNode_NameLabel.add_theme_font_size_override("font_size", get_global_setting('font_size', name_label_custom_font_size))
	else:
		%DialogicNode_NameLabel.add_theme_font_size_override("font_size", name_label_custom_font_size)

	if name_label_use_global_font and get_global_setting('font', false):
		%DialogicNode_NameLabel.add_theme_font_override('font', load(get_global_setting('font', '')))
	elif not name_label_font.is_empty():
		%DialogicNode_NameLabel.add_theme_font_override('font', load(name_label_font))

	if name_label_use_global_color:
		%DialogicNode_NameLabel.add_theme_color_override("font_color", get_global_setting('font_color', name_label_custom_color))
	else:
		%DialogicNode_NameLabel.add_theme_color_override("font_color", name_label_custom_color)

	%DialogicNode_NameLabel.use_character_color = name_label_use_character_color

	if ResourceLoader.exists(name_label_box_panel):
		%NameLabelPanel.add_theme_stylebox_override('panel', load(name_label_box_panel))
	else:
		%NameLabelPanel.add_theme_stylebox_override('panel', load(this_folder.path_join("vn_textbox_name_label_panel.tres")))

	if name_label_box_use_global_color:
		%NameLabelPanel.self_modulate = get_global_setting('bg_color', name_label_box_modulate)
	else:
		%NameLabelPanel.self_modulate = name_label_box_modulate

	%NameLabelPanel.position = name_label_box_offset+Vector2(0, -40)
	%NameLabelPanel.position -= Vector2(
		%DialogTextPanel.get_theme_stylebox('panel', 'PanelContainer').content_margin_left,
		%DialogTextPanel.get_theme_stylebox('panel', 'PanelContainer').content_margin_top)
	%NameLabelPanel.anchor_left = name_label_alignment/2.0
	%NameLabelPanel.anchor_right = name_label_alignment/2.0
	%NameLabelPanel.grow_horizontal = [1, 2, 0][name_label_alignment]

	## NEXT INDICATOR SETTINGS
	%NextIndicator.enabled = next_indicator_enabled

	if next_indicator_enabled:
		%NextIndicator.animation = next_indicator_animation
		if FileAccess.file_exists(next_indicator_texture):
			%NextIndicator.texture = load(next_indicator_texture)
		%NextIndicator.show_on_questions = next_indicator_show_on_questions
		%NextIndicator.show_on_autoadvance = next_indicator_show_on_autoadvance
		%NextIndicator.texture_size = next_indicator_size

	## OTHER
	%AutoAdvanceProgressbar.enabled = autoadvance_progressbar

	#### SOUNDS

	## TYPING SOUNDS
	%DialogicNode_TypeSounds.enabled = typing_sounds_enabled
	%DialogicNode_TypeSounds.mode = typing_sounds_mode
	if not typing_sounds_sounds_folder.is_empty():
		%DialogicNode_TypeSounds.sounds = %DialogicNode_TypeSounds.load_sounds_from_path(typing_sounds_sounds_folder)
	else:
		%DialogicNode_TypeSounds.sounds.clear()
	if not typing_sounds_end_sound.is_empty():
		%DialogicNode_TypeSounds.end_sound = load(typing_sounds_end_sound)
	else:
		%DialogicNode_TypeSounds.end_sound = null

	%DialogicNode_TypeSounds.play_every_character = typing_sounds_every_nths_character
	%DialogicNode_TypeSounds.base_pitch = typing_sounds_pitch
	%DialogicNode_TypeSounds.base_volume = typing_sounds_volume
	%DialogicNode_TypeSounds.pitch_variance = typing_sounds_pitch_variance
	%DialogicNode_TypeSounds.volume_variance = typing_sounds_volume_variance
	%DialogicNode_TypeSounds.ignore_characters = typing_sounds_ignore_characters

