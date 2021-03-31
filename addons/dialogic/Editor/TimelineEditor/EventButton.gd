tool
extends Button

export (String) var EventName = ''

func get_drag_data(position):
	var cpb = Button.new()
	cpb.text = EventName
	set_drag_preview(cpb)
	
	return { "source": "EventButton", "event_name": EventName }
