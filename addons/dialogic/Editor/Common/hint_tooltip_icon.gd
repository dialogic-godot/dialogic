@tool
extends TextureRect

@export_multiline var hint_text := ""

func _ready() -> void:
	if owner and owner.get_parent() is SubViewport or get_parent() is SubViewport:
		texture = null
		return
	texture = get_theme_icon("NodeInfo", "EditorIcons")
	modulate = get_theme_color("contrast_color_1", "Editor")
	tooltip_text = hint_text


func _make_custom_tooltip(for_text: String) -> Object:
	var rtl := RichTextLabel.new()
	rtl.fit_content = true
	rtl.bbcode_enabled = true
	rtl.text = for_text
	rtl.custom_minimum_size.x = 500 * DialogicUtil.get_editor_scale()
	return rtl
