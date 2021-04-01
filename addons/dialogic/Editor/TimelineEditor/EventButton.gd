tool
extends Button

export (String) var EventName = ''

func get_drag_data(position):
	var preview_label = Label.new()
	
	if (self.text != ''):
		preview_label.text = text
	else:
		preview_label.text = 'Add Event %s' % [ EventName ]
		
	set_drag_preview(preview_label)
	
	return { "source": "EventButton", "event_name": EventName }
