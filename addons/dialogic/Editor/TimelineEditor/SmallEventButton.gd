tool
extends Button

export(String) var visible_name = ""
export (String) var event_id = 'dialogic_099'
export (Color) var event_color = Color('#48a2a2a2')
export(Texture) var event_icon = null setget set_icon
export (int) var event_category := 0


func _ready():
	$Panel.self_modulate = event_color
	self_modulate = Color(1,1,1)
	if visible_name != '':
		text = visible_name
	hint_tooltip = DTS.translate(hint_tooltip)
	var _scale = DialogicUtil.get_editor_scale(self)
	rect_min_size = Vector2(30,30)
	rect_min_size = rect_min_size * _scale
	icon = null
	# Another programming crime was commited
	# a switch statement is missing
	# what a horrible sight
	# elif I have you on my mind
	if _scale == 2 or _scale == 1.75:
		$TextureRect.rect_scale = Vector2(1, 1)
	elif _scale == 1.5:
		$TextureRect.rect_scale = Vector2(0.8, 0.8)
	elif _scale == 0.75:
		$TextureRect.rect_scale = Vector2(0.4, 0.4)
	else:
		$TextureRect.rect_scale = Vector2(0.6, 0.6)
	
	add_color_override("font_color", get_color("font_color", "Editor"))
	add_color_override("font_color_hover", get_color("accent_color", "Editor"))
	$TextureRect.modulate = get_color("font_color", "Editor")


func set_icon(texture):
	#icon = texture
	event_icon = texture
	var _scale = DialogicUtil.get_editor_scale(self)
	$TextureRect.texture = texture


func get_drag_data(position):
	var preview_label = Label.new()
	
	if (self.text != ''):
		preview_label.text = text
	else:
		preview_label.text = 'Add Event %s' % [ hint_tooltip ]
		
	set_drag_preview(preview_label)
	
	return { "source": "EventButton", "event_id": event_id }
