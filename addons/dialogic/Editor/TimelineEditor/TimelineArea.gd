tool
extends ScrollContainer

var _drag_drop_indicator = null
# store last attempts since godot sometimes misses drop events
var _is_drag_receiving = false
var _last_event_button_drop_attempt = '' 
var _mouse_exited = false

func _ready():
	connect("mouse_entered", self, '_on_mouse_entered')
	connect("mouse_exited", self, '_on_mouse_exited')
	connect("gui_input", self, '_on_gui_input')


func can_drop_data(position, data):
	if (data != null and data is Dictionary and data.has("source")):
		if (data["source"] == "EventButton"):
			# position drop indicator
			_set_indicator_position(position)
			_is_drag_receiving = true
			_last_event_button_drop_attempt = data["event_name"]
			return true
	
	_remove_drop_indicator()
	return false
	

func cancel_drop():
	_is_drag_receiving = false
	_last_event_button_drop_attempt = ''
	_remove_drop_indicator()
	pass

	
func drop_data(position, data):
	# todo, getting timeline like this is prone to fail someday
	var timeline_editor = get_parent()
	
	# add event
	if (data["source"] == "EventButton"):
		var piece = timeline_editor.create_event(data["event_name"])
		if (piece != null and _drag_drop_indicator != null):
			var parent = piece.get_parent()
			if (parent != null):
				parent.remove_child(piece)
				parent.add_child_below_node(_drag_drop_indicator, piece)
				timeline_editor.indent_events()
				# @todo _select_item seems to be a "private" function
				# maybe expose it as "public" or add a public helper function
				# to TimelineEditor.gd
				timeline_editor._select_item(piece)
				
	_is_drag_receiving = false
	_last_event_button_drop_attempt = ''
	_remove_drop_indicator()
	
	
func _on_mouse_exited():
	_mouse_exited = true
	
  
func _on_mouse_entered():
	_mouse_exited = false	
	
  
func _input(event):
	if (event is InputEventMouseButton and is_visible_in_tree() and event.button_index == BUTTON_LEFT):
		if (_mouse_exited and _is_drag_receiving):
			cancel_drop()
			
      
func _on_gui_input(event):
	# godot sometimes misses drop events
	if (event is InputEventMouseButton and event.button_index == BUTTON_LEFT):
		if (_is_drag_receiving):
			if (_last_event_button_drop_attempt != ''):
				drop_data(Vector2.ZERO, { "source": "EventButton", "event_name": _last_event_button_drop_attempt} )
			_is_drag_receiving = false
			_remove_drop_indicator()
	pass
	
	
func _create_drop_indicator():
	_remove_drop_indicator()
	
	var timeline = get_child(0)
	if (timeline == null):
		return
	
	var indicator = ColorRect.new()
	indicator.name = "DropIndicator"
	indicator.rect_size.y = 100
	indicator.rect_min_size.y = 100
	indicator.color = Color(0.35, 0.37, 0.44) # default editor light blue
	indicator.mouse_filter = MOUSE_FILTER_IGNORE
	
	# add indent node like the other scene nodes have
	var indent = Control.new()
	indent.rect_min_size.x = 25
	indent.visible = false
	indent.name = "Indent"
	indicator.add_child(indent)
	
	var label = Label.new()
	label.text = "Drop here"
	indicator.add_child(label)
	
	timeline.add_child(indicator)
	
	_drag_drop_indicator = indicator
	
	
func _remove_drop_indicator():	
	if (_drag_drop_indicator != null):
		_drag_drop_indicator.get_parent().remove_child(_drag_drop_indicator)
		_drag_drop_indicator.queue_free()
		
	_drag_drop_indicator = null
	
	
func _set_indicator_position(position):
	var timeline = get_child(0)
	if (timeline == null):
		return
		
	if (_drag_drop_indicator == null):
		_create_drop_indicator()
		
	var highest_index = 0
	var index = 0
	for child in timeline.get_children():
		if child.get_local_mouse_position().y > 0 and index > highest_index:
			highest_index = index
		index += 1
		
	if (_drag_drop_indicator.is_inside_tree()):
		timeline.move_child(_drag_drop_indicator, max(0, highest_index))
	pass
