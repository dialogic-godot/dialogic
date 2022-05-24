tool
extends ScrollContainer

# store last attempts since godot sometimes misses drop events
var _is_drag_receiving = false
var _last_event_button_drop_attempt = '' 
var _mouse_exited = false

# todo, getting timeline like this is prone to fail someday
onready var timeline_editor = get_parent()

func _ready():
	connect("mouse_entered", self, '_on_mouse_entered')
	connect("mouse_exited", self, '_on_mouse_exited')
	connect("gui_input", self, '_on_gui_input')


func can_drop_data(position, data):
	if data != null and data is Dictionary and data.has("source"):
		if data["source"] == "EventButton":
			if _last_event_button_drop_attempt.empty():
				timeline_editor.create_drag_and_drop_event(data["event_id"])
			_is_drag_receiving = true
			_last_event_button_drop_attempt = data["event_id"]
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
	if (event is InputEventMouseButton and is_visible_in_tree() and event.button_index == BUTTON_LEFT):
		if (_mouse_exited and _is_drag_receiving):
			cancel_drop()


func _on_gui_input(event):
	# godot sometimes misses drop events
	if (event is InputEventMouseButton and event.button_index == BUTTON_LEFT):
		if (_is_drag_receiving):
			if (_last_event_button_drop_attempt != ''):
				drop_data(Vector2.ZERO, { "source": "EventButton", "event_id": _last_event_button_drop_attempt} )
			_is_drag_receiving = false


func rendering_scale_correction(s, vector:Vector2) -> Vector2:
	if s == 1.25:
		return vector - Vector2(3, 2)
	if s == 1.5:
		return vector - Vector2(6, 6)
	if s == 1.75:
		return vector - Vector2(6, 7)
	if s == 2:
		return vector - Vector2(13, 8)
	return vector
	 


func _draw():
	var timeline_children = $TimeLine.get_children()
	var timeline_lenght = timeline_children.size()
	var line_color = Color("#4D4D4D")
	var test_color = Color(1,0,0,0.5)
	var _scale = DialogicUtil.get_editor_scale(self)
	var line_width = 3 * _scale
	var pos = Vector2(32 * _scale, 51 * _scale)
	
	pos = rendering_scale_correction(_scale, pos)
	
	for event in $TimeLine.get_children():
		if not 'event_data' in event:
			continue
		
		# If the event is the last one, don't draw anything aftwards
		if timeline_children[timeline_lenght-1] == event:
			return

		# Drawing long lines on questions and conditions
		if event.event_name == 'Question' or event.event_name == 'Condition':
			var keep_going = true
			var end_reference
			for e in timeline_children:
				if keep_going:
					if e.get_index() > event.get_index():
						if e.current_indent_level == event.current_indent_level:
							if e.event_name == 'End Branch':
								end_reference = e
								keep_going = false
							if e.event_name == 'Question' or event.event_name == 'Condition':
								keep_going = false
			if keep_going == false:
				if end_reference:
					# This line_size thing should be fixed, not sure why it is different when
					# the indent level is 0 and when it is bigger. 
					var line_size = 0
					if event.current_indent_level > 0:
						line_size = (event.indent_size * event.current_indent_level) + (4 * _scale)
					# end the line_size thingy

					# Drawing the line from the Question/Condition node to the End Branch one.
					draw_rect(Rect2(
								Vector2(pos.x + line_size -scroll_horizontal, pos.y-scroll_vertical)+event.rect_position,
								Vector2(line_width,
								(end_reference.rect_global_position.y - event.rect_global_position.y) - (43 * _scale))
							),
							line_color, true)

		# Drawing other lines and archs
		var next_event = timeline_children[event.get_index() + 1]
		if event.current_indent_level > 0:
			# Line at current indent
			var line_size = (event.indent_size * event.current_indent_level) + (4 * _scale)
			if next_event.event_name != 'End Branch' and event.event_name != 'Choice':
				if event.event_name != 'Question' and next_event.event_name == 'Choice':
					# Skip drawing lines before going to the next choice
					pass
				else:
					draw_rect(Rect2(
							Vector2(pos.x + line_size -scroll_horizontal, pos.y - scroll_vertical)+event.rect_position,
							Vector2(line_width, event.rect_size.y - (40 * _scale))
						),
						line_color,
						true)
		else:
			# Root (level 0) Vertical Line
			draw_rect(Rect2(
					Vector2(pos.x-scroll_horizontal, pos.y - scroll_vertical)+event.rect_position,
					Vector2(line_width, event.rect_size.y - (40 * _scale))
					),
				line_color,
				true)
				
		# Drawing arc
		if event.event_name == 'Choice':
			# Connecting with the question 
			var arc_start = Vector2(
				(event.indent_size * (event.current_indent_level)) + (16.2 * _scale),
				5
			)
			var arc_point_count = 12 * _scale
			var arc_radius = 24 * _scale
			var start_angle = 90
			var end_angle = 185

			if event.current_indent_level == 1:
				arc_start.x = (event.indent_size * (event.current_indent_level)) + (12.5 * _scale)
			
			arc_start = rendering_scale_correction(_scale, arc_start)

			draw_arc(
				Vector2(arc_start.x-scroll_horizontal, arc_start.y - scroll_vertical) + event.rect_position,
				arc_radius,
				deg2rad(start_angle),
				deg2rad(end_angle),
				arc_point_count, #point count
				line_color,
				line_width - (1 * _scale),
				true
			)

			# Don't draw arc if next event is another choice event
			if next_event.event_name == "Choice" or next_event.event_name == "End Branch":
				continue

			# Connecting with the next event

			arc_start.x = (event.indent_size * (event.current_indent_level + 1)) + (16 * _scale)
			arc_start.y = (pos.y + (8 * _scale))
			
			arc_start = rendering_scale_correction(_scale, arc_start)

			draw_arc(
				Vector2(arc_start.x-scroll_horizontal, arc_start.y - scroll_vertical) + event.rect_position,
				arc_radius,
				deg2rad(start_angle),
				deg2rad(end_angle),
				arc_point_count,
				line_color,
				line_width - (1 * _scale),
				true
			)
