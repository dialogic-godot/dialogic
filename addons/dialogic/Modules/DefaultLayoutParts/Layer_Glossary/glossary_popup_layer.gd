@tool
extends DialogicLayoutLayer

## Layer that provides a popup with glossary info,
## when hovering a glossary entry on a text node.


@export_group('Text')
enum Alignment {LEFT, CENTER, RIGHT}
@export var title_alignment: Alignment = Alignment.LEFT
@export var text_alignment: Alignment = Alignment.LEFT
@export var extra_alignment: Alignment = Alignment.RIGHT

@export_subgroup("Colors")
enum TextColorModes {GLOBAL, ENTRY, CUSTOM}
@export var title_color_mode: TextColorModes = TextColorModes.ENTRY
@export var title_custom_color: Color = Color.WHITE
@export var text_color_mode: TextColorModes = TextColorModes.ENTRY
@export var text_custom_color: Color = Color.WHITE
@export var extra_color_mode: TextColorModes = TextColorModes.ENTRY
@export var extra_custom_color: Color = Color.WHITE


@export_group("Font")
@export var font_use_global: bool = true
@export_file('*.ttf', '*.tres') var font_custom: String = ""

@export_subgroup('Sizes')
@export var font_title_size: int = 18
@export var font_text_size: int = 17
@export var font_extra_size: int = 15


@export_group("Box")
@export_subgroup("Color")
enum ModulateModes {BASE_COLOR_ONLY, ENTRY_COLOR_ON_BOX, GLOBAL_BG_COLOR}
@export var box_modulate_mode: ModulateModes = ModulateModes.ENTRY_COLOR_ON_BOX
@export var box_base_modulate: Color = Color.WHITE
@export_subgroup("Size")
@export var box_width: int = 200

const MISSING_INDEX := -1
func get_pointer() -> Control:
	return $Pointer


func get_title() -> Label:
	return %Title


func get_text() -> RichTextLabel:
	return %Text


func get_extra() -> RichTextLabel:
	return %Extra


func get_panel() -> PanelContainer:
	return %Panel


func get_panel_point() -> PanelContainer:
	return %PanelPoint


func _ready() -> void:
	if Engine.is_editor_hint():
		return

	get_pointer().hide()
	var text_system: Node = DialogicUtil.autoload().get(&'Text')
	var _error: int = 0
	_error = text_system.connect(&'animation_textbox_hide', get_pointer().hide)
	_error = text_system.connect(&'meta_hover_started', _on_dialogic_display_dialog_text_meta_hover_started)
	_error = text_system.connect(&'meta_hover_ended', _on_dialogic_display_dialog_text_meta_hover_ended)


## Method that shows the bubble and fills in the info
func _on_dialogic_display_dialog_text_meta_hover_started(meta: String) -> void:
	var entry_info := DialogicUtil.autoload().Glossary.get_entry(meta)

	if entry_info.is_empty():
		return

	get_pointer().show()
	get_title().text = entry_info.title
	get_text().text = entry_info.text
	get_text().text = ['', '[center]', '[right]'][text_alignment] + get_text().text
	get_extra().text = entry_info.extra
	get_extra().text = ['', '[center]', '[right]'][extra_alignment] + get_extra().text
	get_pointer().global_position = get_pointer().get_global_mouse_position()

	if title_color_mode == TextColorModes.ENTRY:
		get_title().add_theme_color_override(&"font_color", entry_info.color)
	if text_color_mode == TextColorModes.ENTRY:
		get_text().add_theme_color_override(&"default_color", entry_info.color)
	if extra_color_mode == TextColorModes.ENTRY:
		get_extra().add_theme_color_override(&"default_color", entry_info.color)

	match box_modulate_mode:
		ModulateModes.ENTRY_COLOR_ON_BOX:
			get_panel().self_modulate = entry_info.color
			get_panel_point().self_modulate = entry_info.color


## Method that keeps the bubble at mouse position when visible
func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return

	var pointer: Control = get_pointer()
	if pointer.visible:
		pointer.global_position = pointer.get_global_mouse_position()


## Method that hides the bubble
func _on_dialogic_display_dialog_text_meta_hover_ended(_meta:String) -> void:
	get_pointer().hide()



func _apply_export_overrides() -> void:
	var font_setting: String = get_global_setting("font", "")

	# Apply fonts
	var font: FontFile
	if font_use_global and ResourceLoader.exists(get_global_setting(&'font', '') as String):
		font = load(get_global_setting(&'font', '') as String)
	elif ResourceLoader.exists(font_custom):
		font = load(font_custom)

	var title: Label = get_title()
	if font:
		title.add_theme_font_override(&"font", font)
	title.horizontal_alignment = title_alignment as HorizontalAlignment

	# Apply font & sizes
	title.add_theme_font_size_override(&"font_size", font_title_size)
	var labels: Array[RichTextLabel] = [get_text(), get_extra()]
	var sizes: PackedInt32Array = [font_text_size, font_extra_size]
	for i : int in len(labels):
		if font:
			labels[i].add_theme_font_override(&'normal_font', font)

		labels[i].add_theme_font_size_override(&"normal_font_size", sizes[i])
		labels[i].add_theme_font_size_override(&"bold_font_size", sizes[i])
		labels[i].add_theme_font_size_override(&"italics_font_size", sizes[i])
		labels[i].add_theme_font_size_override(&"bold_italics_font_size", sizes[i])
		labels[i].add_theme_font_size_override(&"mono_font_size", sizes[i])


	# Apply text colors
	# this applies Global or Custom colors, entry colors are applied on hover
	var controls: Array[Control] = [get_title(), get_text(), get_extra()]
	var settings: Array[StringName] = [&'font_color', &'default_color', &'default_color']
	var color_modes: Array[TextColorModes] = [title_color_mode, text_color_mode, extra_color_mode]
	var custom_colors: PackedColorArray = [title_custom_color, text_custom_color, extra_custom_color]
	for i : int in len(controls):
		match color_modes[i]:
			TextColorModes.GLOBAL:
				controls[i].add_theme_color_override(settings[i], get_global_setting(&'font_color', custom_colors[i]) as Color)
			TextColorModes.CUSTOM:
				controls[i].add_theme_color_override(settings[i], custom_colors[i])

	# Apply box size
	var panel: PanelContainer = get_panel()
	panel.size.x = box_width
	panel.position.x = -box_width/2.0

	# Apply box coloring
	match box_modulate_mode:
		ModulateModes.BASE_COLOR_ONLY:
			panel.self_modulate = box_base_modulate
			get_panel_point().self_modulate = box_base_modulate
		ModulateModes.GLOBAL_BG_COLOR:
			panel.self_modulate = get_global_setting(&'bg_color', box_base_modulate)
			get_panel_point().self_modulate = get_global_setting(&'bg_color', box_base_modulate)
