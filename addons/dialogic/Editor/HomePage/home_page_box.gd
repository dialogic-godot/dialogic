@tool
extends PanelContainer

signal button_pressed

@export var title := "Title"
@export var content := "Somet text that is interesting."
@export var image := Texture.new()
@export var button := ""

func _ready():
	%Title.text = title
	%Content.text = content
	%Header.texture = image
	%Button.visible = !button.is_empty()
	%Button.text = button
	var editor_scale := DialogicUtil.get_editor_scale()
	get('theme_override_styles/panel').corner_radius_top_left = 10 * editor_scale
	get('theme_override_styles/panel').corner_radius_top_right = 10 * editor_scale
	get('theme_override_styles/panel').corner_radius_bottom_left = 20 * editor_scale
	get('theme_override_styles/panel').corner_radius_bottom_right = 20 * editor_scale
	get('theme_override_styles/panel').content_margin_top = 10 * editor_scale
	%Header.custom_minimum_size.y = 50 * editor_scale
	%Title.set('theme_override_font_sizes/font_size', 20 * editor_scale)
	$Vbox/Content.set('theme_override_constants/margin_left', 10*editor_scale)
	$Vbox/Content.set('theme_override_constants/margin_right', 10*editor_scale)
	$Vbox/Content.set('theme_override_constants/margin_down', 10*editor_scale)
	$Vbox/Content.set('theme_override_constants/margin_top', 10*editor_scale)


func _on_button_pressed():
	button_pressed.emit()
