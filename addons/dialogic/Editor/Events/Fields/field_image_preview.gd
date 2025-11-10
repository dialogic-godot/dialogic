@tool
extends DialogicVisualEditorField


var body: Control
var image_path: String

func _ready() -> void:
	body = find_parent('Body') as Control
	body.visibility_changed.connect(_on_body_visibility_toggled)


func _enter_tree() -> void:
	%HiddenLabel.add_theme_color_override(
		'font_color',
		event_resource.event_color.lerp(get_theme_color("font_color", "Editor"), 0.8))


#region OVERWRITES
################################################################################

## To be overwritten
func _set_value(value:Variant) -> void:
	if ResourceLoader.exists(value):
		image_path = value

		if is_preview_enabled():
			self.texture = load(value)
			custom_minimum_size.y = get_preview_size()
	else:
		self.texture = null

	minimum_size_changed.emit()

#endregion


#region SIGNAL METHODS
################################################################################


func _on_body_visibility_toggled() -> void:
	custom_minimum_size.y = 0

	if body.is_visible:
		%HiddenLabel.visible = not is_preview_enabled()

		if is_preview_enabled() and ResourceLoader.exists(image_path):
			self.texture = load(image_path)
			custom_minimum_size.y = get_preview_size()
		else:
			self.texture = null

	minimum_size_changed.emit()

#endregion

func is_preview_enabled() -> bool:
	return get_preview_size() != 0


func get_preview_size() -> int:
	return DialogicUtil.get_editor_setting(
		"image_preview_height", 50)   * DialogicUtil.get_editor_scale()
