tool
extends Button

export(String) var visible_name = ""
export (String) var event_id = 'dialogic_099'
export(Texture) var event_icon = null setget set_icon


func _ready():
	$HBox/Label.text = visible_name
	hint_tooltip = DTS.translate(hint_tooltip)
	var _scale = get_constant("inspector_margin", "Editor")
	_scale = _scale * 0.125
	rect_min_size = Vector2(30,30)
	if _scale == 1.25:
		rect_min_size = Vector2(30,30)
	if _scale == 1.5:
		rect_min_size = Vector2(30,30)
	if _scale == 1.75:
		rect_min_size = Vector2(60,60)
	if _scale == 2:
		rect_min_size = Vector2(60,60)


func set_icon(texture):
	$HBox/TextureRect.texture = texture
	event_icon = texture


func get_drag_data(position):
	var preview_label = Label.new()
	
	if (self.text != ''):
		preview_label.text = text
	else:
		preview_label.text = 'Add Event %s' % [ hint_tooltip ]
		
	set_drag_preview(preview_label)
	
	return { "source": "EventButton", "event_id": event_id }
