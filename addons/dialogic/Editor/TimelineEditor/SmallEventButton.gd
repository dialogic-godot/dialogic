@tool
extends Button

@export var visible_name:String = ""
@export var event_id:String = ''
@export var event_icon:Texture :
	get:
		return event_icon
	set(texture):
		event_icon = texture
		$TextureRect.texture = texture
@export var event_category:int = 0
@export var event_sorting_index:int = 0
@export var resource:Resource
@export var dialogic_color_name:String = ''

func _ready():
	self_modulate = Color(1,1,1)
	if visible_name != '':
		text = '  ' + visible_name
	hint_tooltip = DTS.translate(hint_tooltip)
	var _scale = DialogicUtil.get_editor_scale()
	custom_minimum_size = Vector2(30,30)
	custom_minimum_size = custom_minimum_size * _scale
	icon = null
	var t_rect = $TextureRect
	var c_border = $ColorBorder
	c_border.custom_minimum_size.x = 5 * _scale
	c_border.size.x = 5 * _scale
	t_rect.margin_left = 20 * _scale
	t_rect.rect_scale = Vector2(_scale, _scale) * Vector2(0.5, 0.5)
	
	add_theme_color_override("font_color", get_theme_color("font_color", "Editor"))
	add_theme_color_override("font_color_hover", get_theme_color("accent_color", "Editor"))
	t_rect.modulate = get_theme_color("font_color", "Editor")
	
	ProjectSettings.project_settings_changed.connect(_update_color)

func set_color(color):
	$ColorBorder.self_modulate = color

func _update_color():
	if dialogic_color_name != '':
		var new_color = DialogicUtil.get_color(dialogic_color_name)
		resource.event_color = new_color
		$ColorBorder.self_modulate = DialogicUtil.get_color(dialogic_color_name)

func get_drag_data(position):
	var preview_label = Label.new()
	
	preview_label.text = 'Add Event %s' % [ hint_tooltip ]
	if self.text != '':
		preview_label.text = text
		
	set_drag_preview(preview_label)
	
	return { "source": "EventButton", "resource": resource }
