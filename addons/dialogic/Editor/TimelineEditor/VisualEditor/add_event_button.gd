@tool
extends Button

@export var visible_name := ""
@export var event_id := ""
@export var event_icon: Texture:
	get:
		return event_icon
	set(texture):
		event_icon = texture
		icon = event_icon
@export var event_sorting_index: int = 0
@export var resource: DialogicEvent
@export var dialogic_color_name := ""


func _ready() -> void:
	if get_parent() is SubViewport:
		return

	custom_minimum_size = Vector2(get_theme_font("font", "Label").get_string_size(text).x+35,30) * DialogicUtil.get_editor_scale()

	add_theme_color_override("font_color", get_theme_color("font_color", "Editor"))
	add_theme_color_override("font_color_hover", get_theme_color("accent_color", "Editor"))


	var tooltip_box := StyleBoxFlat.new()
	tooltip_box.bg_color = get_theme_color("background", "Editor")
	tooltip_box.set_border_width_all(1)
	tooltip_box.border_width_left = 5 * int(DialogicUtil.get_editor_scale())
	theme.set_stylebox("panel", "TooltipPanel", tooltip_box)

	apply_base_button_style()


func apply_base_button_style() -> void:
	var nstyle: StyleBoxFlat = get_parent().get_theme_stylebox("normal", "Button").duplicate()
	nstyle.border_width_left = 5 * int(DialogicUtil.get_editor_scale())
	add_theme_stylebox_override("normal", nstyle)
	var hstyle: StyleBoxFlat = get_parent().get_theme_stylebox("hover", "Button").duplicate()
	hstyle.border_width_left = 5 * int(DialogicUtil.get_editor_scale())
	add_theme_stylebox_override("hover", hstyle)
	set_color(resource.event_color)


func set_color(color:Color) -> void:
	var style := get_theme_stylebox("normal", "Button")
	style.border_color = color
	add_theme_stylebox_override("normal", style)
	style = get_theme_stylebox("hover", "Button")
	style.border_color = color
	add_theme_stylebox_override("hover", style)

	var tooltip_box : StyleBoxFlat = theme.get_stylebox("panel", "TooltipPanel")
	tooltip_box.border_color = color
	theme.set_stylebox("panel", "TooltipPanel", tooltip_box)


func toggle_name(on:= false) -> void:
	if not on:
		text = ""
		custom_minimum_size = Vector2(40, 40) * DialogicUtil.get_editor_scale()
		var style := get_theme_stylebox("normal", "Button")
		style.bg_color = style.border_color.darkened(0.2)
		add_theme_stylebox_override("normal", style)
		style = get_theme_stylebox("hover", "Button")
		style.bg_color = style.border_color
		add_theme_stylebox_override("hover", style)
	else:
		text = visible_name
		custom_minimum_size = Vector2(get_theme_font("font", "Label").get_string_size(text).x+35,30) * DialogicUtil.get_editor_scale()
		apply_base_button_style()


func _on_button_down() -> void:
	find_parent("VisualEditor").get_node("%TimelineArea").start_dragging(1, resource)


func _make_custom_tooltip(for_text: String) -> Object:
	var rtl := RichTextLabel.new()
	rtl.bbcode_enabled = true
	rtl.text = "[b]{0}[/b]\n{1}".format(Array(for_text.split("\n", false, 2)))
	rtl.fit_content = true
	rtl.custom_minimum_size.x = 300*DialogicUtil.get_editor_scale()
	return rtl
