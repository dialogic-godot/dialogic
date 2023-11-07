@tool
extends CanvasLayer

enum Alignments {LEFT, CENTER, RIGHT}

# Careful: Sync these with the ones in the %Animation script!
enum AnimationsIn {NONE, POP_IN, FADE_UP}
enum AnimationsOut {NONE, POP_OUT, FADE_DOWN}
enum AnimationsNewText {NONE, WIGGLE}


@export_group("Main")
@export_subgroup("Text")
@export var text_alignment :Alignments= Alignments.LEFT
@export var text_size := 15
@export var text_color : Color = Color.WHITE
@export_file('*.ttf') var normal_font:String = ""
@export_file('*.ttf') var bold_font:String = ""
@export_file('*.ttf') var italic_font:String = ""
@export_file('*.ttf') var bold_italic_font:String = ""

@export_subgroup("Box")
@export var box_modulate : Color = Color(0.00784313771874, 0.00784313771874, 0.00784313771874, 0.84313726425171)
@export var box_size : Vector2 = Vector2(550, 110)
@export var box_animation_in := AnimationsIn.FADE_UP
@export var box_animation_out := AnimationsOut.FADE_DOWN
@export var box_animation_new_text := AnimationsNewText.NONE

@export_subgroup("Name Label")
@export var name_label_alignment := Alignments.LEFT
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
@export var portrait_size_mode := DialogicNode_PortraitContainer.SizeModes.FIT_SCALE_HEIGHT

@export_subgroup("Indicators")
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

@export_subgroup('Choice Button Sounds')
@export_range(-80, 24, 0.01) var choice_button_sounds_volume := -10
@export_file("*.wav", "*.ogg", "*.mp3") var choice_button_sounds_pressed := "res://addons/dialogic/Example Assets/sound-effects/typing1.wav"
@export_file("*.wav", "*.ogg", "*.mp3") var choice_button_sounds_hover := "res://addons/dialogic/Example Assets/sound-effects/typing2.wav"
@export_file("*.wav", "*.ogg", "*.mp3") var choice_button_sounds_focus := "res://addons/dialogic/Example Assets/sound-effects/typing4.wav"


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

	## BOX ANIMATIONS
	%Animations.animation_in = box_animation_in
	%Animations.animation_out = box_animation_out
	%Animations.animation_new_text = box_animation_new_text


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

	## CHOICE SOUNDS
	%DialogicNode_ButtonSound.volume_db = choice_button_sounds_volume
	%DialogicNode_ButtonSound.sound_pressed = load(choice_button_sounds_pressed)
	%DialogicNode_ButtonSound.sound_hover = load(choice_button_sounds_hover)
	%DialogicNode_ButtonSound.sound_focus = load(choice_button_sounds_focus)

