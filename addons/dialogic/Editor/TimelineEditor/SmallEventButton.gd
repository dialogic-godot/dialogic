@tool
extends Button

export (String) var visible_name = ""
export (String) var event_id = ''
export (Texture) var event_icon = null setget set_icon
export (int) var event_category := 0
export (int) var event_sorting_index := 0
export (Resource) var resource
export (String) var dialogic_color_name = ''

func _ready():
	self_modulate = Color(1,1,1)
	if visible_name != '':
		text = '  ' + visible_name
	hint_tooltip = DTS.translate(hint_tooltip)
	var _scale = DialogicUtil.get_editor_scale()
	rect_min_size = Vector2(30,30)
	rect_min_size = rect_min_size * _scale
	icon = null
	var t_rect = $TextureRect
	var c_border = $ColorBorder
	c_border.custom_minimum_size.x = 5 * _scale
	c_border.size.x = 5 * _scale
	t_rect.margin_left = 20 * _scale
	t_rect.rect_scale = Vector2(_scale, _scale) * Vector2(0.5, 0.5)
	
	add_color_override("font_color", get_theme_color("font_color", "Editor"))
	add_color_override("font_color_hover", get_theme_color("accent_color", "Editor"))
	t_rect.modulate = get_theme_color("font_color", "Editor")
	
	ProjectSettings.connect('project_settings_changed', self, '_update_color')

func set_color(color):
	$ColorBorder.self_modulate = color

func _update_color():
	if dialogic_color_name != '':
		var new_color = DialogicUtil.get_color(dialogic_color_name)
		resource.event_color = new_color
		$ColorBorder.self_modulate = DialogicUtil.get_color(dialogic_color_name)

func set_icon(texture):
	event_icon = texture
	$TextureRect.texture = texture

func get_drag_data(position):
	var preview_label = Label.new()
	
	preview_label.text = 'Add Event %s' % [ hint_tooltip ]
	if self.text != '':
		preview_label.text = text
		
	set_drag_preview(preview_label)
	
	return { "source": "EventButton", "resource": resource }
