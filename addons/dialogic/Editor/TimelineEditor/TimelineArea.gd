@tool
extends ScrollContainer

# store last attempts since godot sometimes misses drop events
var _is_drag_receiving = false
var _last_event_button_drop_attempt = '' 
var _mouse_exited = false

@onready var timeline_editor = find_parent('TimelineEditor')


func _ready():
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	gui_input.connect(_on_gui_input)


func can_drop_data(position, data):
	if data != null and data is Dictionary and data.has("source"):
		if data["source"] == "EventButton":
			if _last_event_button_drop_attempt is Resource == false:
				timeline_editor.create_drag_and_drop_event(data["resource"])
			_is_drag_receiving = true
			_last_event_button_drop_attempt = data["resource"]
			return true
	return false


func cancel_drop():
	_is_drag_receiving = false
	_last_event_button_drop_attempt = ''
	timeline_editor.cancel_drop_event()

	
func drop_data(position, data):
	# add event
	if (data["source"] == "EventButton"):
		timeline_editor.drop_event()
	_is_drag_receiving = false
	_last_event_button_drop_attempt = ''


func _on_mouse_exited():
	if _is_drag_receiving and not _mouse_exited:
		var preview_label = Label.new()
		preview_label.text = "Cancel"
		set_drag_preview(preview_label)	
	_mouse_exited = true
	
  
func _on_mouse_entered():
	if _is_drag_receiving and _mouse_exited:
		var preview_label = Label.new()
		preview_label.text = "Insert Event"
		set_drag_preview(preview_label)	
	_mouse_exited = false	
	
  
func _input(event):
	if (event is InputEventMouseButton and is_visible_in_tree() and event.button_index == MOUSE_BUTTON_LEFT):
		if (_mouse_exited and _is_drag_receiving):
			cancel_drop()


func _on_gui_input(event):
	# godot sometimes misses drop events
	if (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT):
		if (_is_drag_receiving):
			if (_last_event_button_drop_attempt != ''):
				drop_data(Vector2.ZERO, { "source": "EventButton", "event_id": _last_event_button_drop_attempt} )
			_is_drag_receiving = false
