tool
extends Button

export (String) var event_id = 'dialogic_099'
export(Texture) var event_icon = null setget set_icon


func _ready():
	hint_tooltip = DTS.translate(hint_tooltip)


func set_icon(texture):
	$TextureRect.texture = texture
	event_icon = texture


func get_drag_data(position):
	var preview_label = Label.new()
	
	if (self.text != ''):
		preview_label.text = text
	else:
		preview_label.text = 'Add Event %s' % [ hint_tooltip ]
		
	set_drag_preview(preview_label)
	
	return { "source": "EventButton", "event_id": event_id }
