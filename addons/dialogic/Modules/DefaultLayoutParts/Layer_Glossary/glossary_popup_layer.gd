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

const MISSING_INDEX := -1

func _ready() -> void:
	if Engine.is_editor_hint():
		return

	$Pointer.hide()
	DialogicUtil.autoload().Text.animation_textbox_hide.connect($Pointer.hide)
	DialogicUtil.autoload().Text.meta_hover_started.connect(_on_dialogic_display_dialog_text_meta_hover_started)
	DialogicUtil.autoload().Text.meta_hover_ended.connect(_on_dialogic_display_dialog_text_meta_hover_ended)
	DialogicUtil.autoload().Text.meta_clicked.connect(_on_dialogic_display_dialog_text_meta_clicked)


func _try_translate(tr_base: String, property: StringName, fallback_entry: Dictionary) -> String:
	var tr_key := tr_base.path_join(property)
	var tr_value := tr(tr_key)

	if tr_key == tr_value:
		tr_value = fallback_entry.get(property, "")

	return tr_value

## Method that shows the bubble and fills in the info
func _on_dialogic_display_dialog_text_meta_hover_started(meta: String) -> void:
	var glossary: DialogicGlossary = DialogicUtil.autoload().Glossary.find_glossary(meta)

	var entry_title := ""
	var entry_text := ""
	var entry_extra := ""
	var entry_color: Variant = null

	var title_color := title_custom_color
	var text_color := text_custom_color
	var extra_color := extra_custom_color

	if glossary == null:
		return

	var is_translation_enabled: bool = ProjectSettings.get_setting('dialogic/translation/enabled', false)

	if not is_translation_enabled or glossary._translation_id.is_empty():
		var entry := glossary.get_entry(meta)

		if entry.is_empty():
			return

		entry_title = entry.get("title", "")
		entry_text = entry.get("text", "")
		entry_extra = entry.get("extra", "")
		entry_color = entry.get("color")

	else:
		var translation_key: String = glossary._translation_keys.get(meta)
		var last_slash := translation_key.rfind('/')

		if last_slash == MISSING_INDEX:
			return

		var tr_base := translation_key.substr(0, last_slash)
		print(tr_base)

		var entry := glossary.get_entry(meta)
		entry_color = entry.get('color')

		entry_title = _try_translate(tr_base, "title", entry)
		entry_text = _try_translate(tr_base, "text", entry)
		entry_extra = _try_translate(tr_base, "extra", entry)

	if not entry_color == null:
		title_color = entry_color
		text_color = entry_color
		extra_color = entry_color

	$Pointer.show()
	%Title.text = entry_title
	%Text.text = entry_text
	%Text.text = ['', '[center]', '[right]'][text_alignment] + %Text.text
	%Extra.text = entry_extra
	%Extra.text = ['', '[center]', '[right]'][extra_alignment] + %Extra.text
	$Pointer.global_position = $Pointer.get_global_mouse_position()


	if title_color_mode == TextColorModes.ENTRY:
		%Title.add_theme_color_override("font_color", title_color)

	if text_color_mode == TextColorModes.ENTRY:
		%Text.add_theme_color_override("default_color", text_color)

	if extra_color_mode == TextColorModes.ENTRY:
		%Extra.add_theme_color_override("default_color", extra_color)

	match box_modulate_mode:
		ModulateModes.ENTRY_COLOR_ON_BOX:
			%Panel.self_modulate = title_color
			%PanelPoint.self_modulate = title_color

	DialogicUtil.autoload().Input.action_was_consumed = true


## Method that keeps the bubble at mouse position when visible
func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return

	if $Pointer.visible:
		$Pointer.global_position = $Pointer.get_global_mouse_position()


## Method that hides the bubble
func _on_dialogic_display_dialog_text_meta_hover_ended(_meta: String) -> void:
	$Pointer.hide()
	DialogicUtil.autoload().Input.action_was_consumed = false


func _on_dialogic_display_dialog_text_meta_clicked(_meta: String) -> void:
	DialogicUtil.autoload().Input.action_was_consumed = true


func _apply_export_overrides() -> void:
	var font_setting: String = get_global_setting("font", "")

	# Apply fonts
	var font: FontFile

	if font_use_global and ResourceLoader.exists(font_setting):
		font = load(font_setting)

	elif ResourceLoader.exists(font_custom):
		font = load(font_custom)

	if font:
		%Title.add_theme_font_override("font", font)
	%Title.horizontal_alignment = title_alignment

	# Apply font & sizes
	%Title.add_theme_font_size_override("font_size", font_title_size)

	for i: Array in [[%Text, font_text_size], [%Extra, font_extra_size]]:
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

	for i: Array in texts:
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
