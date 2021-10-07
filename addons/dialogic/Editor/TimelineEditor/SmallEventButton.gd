tool
extends Button

export(String) var visible_name = ""
export (String) var event_id = 'dialogic_099'
export (Color) var event_color = Color('#48a2a2a2')
export(Texture) var event_icon = null setget set_icon


func _ready():
	$Panel.self_modulate = event_color
	self_modulate = Color(1,1,1)
	if visible_name != '':
		text = '  ' + visible_name
	hint_tooltip = DTS.translate(hint_tooltip)
	var _scale = get_constant("inspector_margin", "Editor")
	_scale = _scale * 0.125
	rect_min_size = Vector2(30,30)
	rect_min_size = rect_min_size * _scale


func set_icon(texture):
	icon = texture
	event_icon = texture


func get_drag_data(position):
	var preview_label = Label.new()
	
	if (self.text != ''):
		preview_label.text = text
	else:
		preview_label.text = 'Add Event %s' % [ hint_tooltip ]
		
	set_drag_preview(preview_label)
	
	return { "source": "EventButton", "event_id": event_id }
