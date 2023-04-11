@tool
extends ScrollContainer

# store last attempts since godot sometimes misses drop events
var _is_drag_receiving := false
var _last_event_button_drop_attempt :Variant = '' 
var _mouse_exited := false

@onready var timeline_editor := find_parent('VisualEditor')


func _ready():
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	gui_input.connect(_on_gui_input)


func _can_drop_data(position, data):
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


func _drop_data(position, data):
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
				_drop_data(Vector2.ZERO, { "source": "EventButton", "event_id": _last_event_button_drop_attempt} )
			_is_drag_receiving = false

func _draw():
	var _scale := DialogicUtil.get_editor_scale()
	var line_width := 5 * _scale
	var horizontal_line_length := 100*_scale
	var color_multiplier := Color(1,1,1,0.5)
	var selected_color_multiplier := Color(1,1,1,1)
	for idx in range($Timeline.get_child_count()):
		var event : Control = $Timeline.get_child(idx)
		
		if not "resource" in event:
			continue
		
		if not event.visible:
			continue
		
		if !event.resource is DialogicEndBranchEvent:
			if event.has_body_content or event.resource.can_contain_events:
				var icon_panel_height := 32*_scale
				var rect_position :Vector2= event.get_node('%IconPanel').global_position+Vector2(0,1)*event.get_node('%IconPanel').size+Vector2(0,-4)
				var color :Color= event.resource.event_color
				if event.is_selected():
					color *= selected_color_multiplier
				else:
					color *= color_multiplier
				if idx < $Timeline.get_child_count()-1 and event.current_indent_level < $Timeline.get_child(idx+1).current_indent_level:
					var end_node :Node= event.end_node
					var sub_idx := idx
					if !end_node:
						while sub_idx < $Timeline.get_child_count()-1:
							sub_idx += 1
							if $Timeline.get_child(sub_idx).current_indent_level == event.current_indent_level:
								end_node = $Timeline.get_child(sub_idx-1)
								break
					var rect_size := Vector2()
					if end_node != null:
						rect_size = Vector2(line_width, end_node.global_position.y+end_node.size.y-rect_position.y)
						if end_node.resource is DialogicEndBranchEvent and event.resource.can_contain_events:
							rect_size = Vector2(line_width, end_node.global_position.y+end_node.size.y/2-rect_position.y)
					else:
						rect_size = Vector2(line_width, $Timeline.get_child(-2).position.y+$Timeline.get_child(-2).size.y)
							
					draw_rect(Rect2(rect_position-global_position, rect_size), color)
					draw_rect(Rect2(Vector2(event.get_node('%IconPanel').global_position.x+line_width, rect_position.y+rect_size.y-line_width)-global_position, Vector2(horizontal_line_length, line_width)), color)

				elif event.expanded:
					draw_rect(Rect2(rect_position-global_position, Vector2(line_width, event.size.y-event.get_node('%IconPanel').size.y+10*_scale)), color.darkened(0.5))
