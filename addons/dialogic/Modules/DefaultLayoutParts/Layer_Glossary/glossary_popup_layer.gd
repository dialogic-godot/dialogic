@tool
extends DialogicLayoutLayer

## Layer that provides a popup with glossary info,
## when hovering a glossary entry on a text node.


@export_group('Text')
enum Alignment {LEFT, CENTER, RIGHT}
@export var title_alignment := Alignment.LEFT
@export var text_alignment := Alignment.LEFT
@export var extra_alignment := Alignment.RIGHT

@export_subgroup("Colors")
enum TextColorModes {GLOBAL, ENTRY, CUSTOM}
@export var title_color_mode := TextColorModes.ENTRY
@export var title_custom_color := Color.WHITE
@export var text_color_mode := TextColorModes.ENTRY
@export var text_custom_color := Color.WHITE
@export var extra_color_mode := TextColorModes.ENTRY
@export var extra_custom_color := Color.WHITE


@export_group("Font")
@export var font_use_global := true
@export_file('*.ttf') var font_custom := ""

@export_subgroup('Sizes')
@export var font_title_size := 18
@export var font_text_size := 17
@export var font_extra_size := 15


@export_group("Box")
@export_subgroup("Color")
enum ModulateModes {BASE_COLOR_ONLY, ENTRY_COLOR_ON_BOX, GLOBAL_BG_COLOR}
@export var box_modulate_mode := ModulateModes.ENTRY_COLOR_ON_BOX
@export var box_base_modulate := Color.WHITE
@export_subgroup("Size")
@export var box_width := 200


func _ready() -> void:
	if Engine.is_editor_hint():
		return

	$Pointer.hide()
	DialogicUtil.autoload().Text.animation_textbox_hide.connect($Pointer.hide)
	DialogicUtil.autoload().Text.meta_hover_started.connect(_on_dialogic_display_dialog_text_meta_hover_started)
	DialogicUtil.autoload().Text.meta_hover_ended.connect(_on_dialogic_display_dialog_text_meta_hover_ended)
	DialogicUtil.autoload().Text.meta_clicked.connect(_on_dialogic_display_dialog_text_meta_clicked)


## Method that shows the bubble and fills in the info
func _on_dialogic_display_dialog_text_meta_hover_started(meta:String) -> void:
	var info: Dictionary = DialogicUtil.autoload().Glossary.get_entry(meta)

	if not info:
		return

	$Pointer.show()
	%Title.text = info.get('title', '')
	%Text.text = info.get('text', '')
	%Text.text = ['', '[center]', '[right]'][text_alignment] + %Text.text
	%Extra.text = info.get('extra', '')
	%Extra.text = ['', '[center]', '[right]'][extra_alignment] + %Extra.text
	$Pointer.global_position = $Pointer.get_global_mouse_position()

	if title_color_mode == TextColorModes.ENTRY:
		%Title.add_theme_color_override("font_color", info.get('color', title_custom_color))
	if text_color_mode == TextColorModes.ENTRY:
		%Text.add_theme_color_override("default_color", info.get('color', text_custom_color))
	if extra_color_mode == TextColorModes.ENTRY:
		%Extra.add_theme_color_override("default_color", info.get('color', extra_custom_color))

	match box_modulate_mode:
		ModulateModes.ENTRY_COLOR_ON_BOX:
			%Panel.self_modulate = info.get('color', Color.WHITE)
			%PanelPoint.self_modulate = info.get('color', Color.WHITE)

	DialogicUtil.autoload().Input.action_was_consumed = true


## Method that keeps the bubble at mouse position when visible
func _process(delta) -> void:
	if Engine.is_editor_hint():
		return

	if $Pointer.visible:
		$Pointer.global_position = $Pointer.get_global_mouse_position()


## Method that hides the bubble
func _on_dialogic_display_dialog_text_meta_hover_ended(meta:String) -> void:
	$Pointer.hide()
	DialogicUtil.autoload().Input.action_was_consumed = false


func _on_dialogic_display_dialog_text_meta_clicked(meta:String) -> void:
	DialogicUtil.autoload().Input.action_was_consumed = true


func _apply_export_overrides() -> void:
	# Apply fonts
	var font: FontFile
	if font_use_global and ResourceLoader.exists(get_global_setting('font', '')):
		font = load(get_global_setting('font', ''))
	elif ResourceLoader.exists(font_custom):
		font = load(font_custom)

	if font:
		%Title.add_theme_font_override("font", font)
	%Title.horizontal_alignment = title_alignment

	# Apply font & sizes
	%Title.add_theme_font_size_override("font_size", font_title_size)
	for i in [[%Text, font_text_size], [%Extra, font_extra_size]]:
		if font:
			i[0].add_theme_font_override('normal_font', font)

		i[0].add_theme_font_size_override("normal_font_size", i[1])
		i[0].add_theme_font_size_override("bold_font_size", i[1])
		i[0].add_theme_font_size_override("italics_font_size", i[1])
		i[0].add_theme_font_size_override("bold_italics_font_size", i[1])
		i[0].add_theme_font_size_override("mono_font_size", i[1])


	# Apply text colors
	var texts := [
		[%Title, 'font_color', title_color_mode, title_custom_color],
		[%Text, 'default_color', text_color_mode, text_custom_color],
		[%Extra, 'default_color', extra_color_mode, extra_custom_color],
		]
	for i in texts:
		match i[2]:
			TextColorModes.GLOBAL:
				i[0].add_theme_color_override(i[1], get_global_setting('font_color', i[3]))
			TextColorModes.CUSTOM:
				i[0].add_theme_color_override(i[1], i[3])

	# Apply box size
	%Panel.size.x = box_width
	%Panel.position.x = -box_width/2.0

	# Apply box coloring
	match box_modulate_mode:
		ModulateModes.BASE_COLOR_ONLY:
			%Panel.self_modulate = box_base_modulate
			%PanelPoint.self_modulate = box_base_modulate
		ModulateModes.GLOBAL_BG_COLOR:
			%Panel.self_modulate = get_global_setting('bg_color', box_base_modulate)
			%PanelPoint.self_modulate = get_global_setting('bg_color', box_base_modulate)

