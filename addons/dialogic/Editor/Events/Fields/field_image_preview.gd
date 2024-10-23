@tool
extends DialogicVisualEditorField


var body: Control
var image_path: String

func _ready() -> void:
	if _is_preview_enabled():
		%HiddenLabel.hide()
	
	body = find_parent('Body') as Control
	body.visibility_changed.connect(_on_body_visibility_toggled)
	custom_minimum_size.y = ProjectSettings.get_setting(
		'dialogic/accessibility/image_preview_height', 50) * DialogicUtil.get_editor_scale()


func _enter_tree() -> void:
	%HiddenLabel.add_theme_color_override(
		'font_color',
		event_resource.event_color.lerp(get_theme_color("font_color", "Editor"), 0.8))


#region OVERWRITES
################################################################################


## To be overwritten
func _set_value(value:Variant) -> void:
	if not _is_preview_enabled():
		if ResourceLoader.exists(value):
			image_path = value
			return
	
	if ResourceLoader.exists(value):
		self.texture = load(value)
		custom_minimum_size.y = ProjectSettings.get_setting(
			'dialogic/accessibility/image_preview_height', 50)  * DialogicUtil.get_editor_scale()
		image_path = value
		minimum_size_changed.emit()
	else:
		self.texture = null
		minimum_size_changed.emit()

#endregion


#region SIGNAL METHODS
################################################################################


func _on_body_visibility_toggled() -> void:
	custom_minimum_size.y = 0
	
	if not _is_preview_enabled():
		self.texture = null
		%HiddenLabel.show()
		minimum_size_changed.emit()
		return
	
	if body.visible and ResourceLoader.exists(image_path):
		%HiddenLabel.hide()
		self.texture = load(image_path)
		custom_minimum_size.y = ProjectSettings.get_setting(
			'dialogic/accessibility/image_preview_height', 50)  * DialogicUtil.get_editor_scale()
		minimum_size_changed.emit()
	elif not body.visible:
		self.texture = null
		minimum_size_changed.emit()

#endregion

func _is_preview_enabled() -> bool:
	return ProjectSettings.get_setting('dialogic/accessibility/image_preview_height', 50) != 0
