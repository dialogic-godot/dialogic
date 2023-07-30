@tool
extends ScrollContainer

# Script of the TimelineArea (that contains the event blocks).
# Manages the drawing of the event lines and event dragging.


enum DragTypes {NOTHING, NEW_EVENT, EXISTING_EVENTS}

var drag_type : DragTypes = DragTypes.NOTHING
var drag_data : Variant
var drag_to_position := 0
var dragging := false


signal drag_completed(type, index, data)
signal drag_canceled()


func _ready() -> void:
	resized.connect(add_extra_scroll_area_to_timeline)
	%Timeline.child_entered_tree.connect(add_extra_scroll_area_to_timeline)
	
	# This prevents the view to turn black if you are editing this scene in Godot
	if find_parent('EditorView'):
		%TimelineArea.get_theme_color("background_color", "CodeEdit")


################### EVENT DRAGGING #############################################
################################################################################

func start_dragging(type:DragTypes, data:Variant) -> void:
	dragging = true
	drag_type = type
	drag_data = data


func _input(event:InputEvent) -> void:
	if !dragging:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if !event.is_pressed():
			finish_dragging()


func _process(delta:float) -> void:
	if !dragging:
		return
	
	for child in %Timeline.get_children():
		if (child.global_position.y < get_global_mouse_position().y) and \
			(child.global_position.y+child.size.y > get_global_mouse_position().y):
			
			if get_global_mouse_position().y > child.global_position.y+(child.size.y/2.0):
				drag_to_position = child.get_index()+1
				queue_redraw()
			else:
				drag_to_position = child.get_index()
				queue_redraw()


func finish_dragging():
	dragging = false
	if get_global_rect().has_point(get_global_mouse_position()):
		drag_completed.emit(drag_type, drag_to_position, drag_data)
	else:
		drag_canceled.emit()
	queue_redraw()
		


##################### LINE DRAWING #############################################
################################################################################

func _draw() -> void:
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
		
		if event.resource is DialogicEndBranchEvent:
			continue
		
		if not (event.has_any_enabled_body_content or event.resource.can_contain_events):
			continue
		
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
			
			if !end_node: # this doesn't have an end node (e.g. text event with choices in it)
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
				rect_size = Vector2(line_width, $Timeline.get_child(-1).global_position.y+$Timeline.get_child(-4).size.y-rect_position.y)
					
			draw_rect(Rect2(rect_position-global_position, rect_size), color)
			draw_rect(Rect2(Vector2(event.get_node('%IconPanel').global_position.x+line_width, rect_position.y+rect_size.y-line_width)-global_position, Vector2(horizontal_line_length, line_width)), color)

		elif event.expanded:
			draw_rect(Rect2(rect_position-global_position, Vector2(line_width, event.size.y-event.get_node('%IconPanel').size.y+10*_scale)), color.darkened(0.5))
	
	if dragging and get_global_rect().has_point(get_global_mouse_position()):
		var height :int = 0
		if drag_to_position == %Timeline.get_child_count():
			height = %Timeline.get_child(-1).global_position.y+%Timeline.get_child(-1).size.y-global_position.y-(line_width/2.0)
		else:
			height = %Timeline.get_child(drag_to_position).global_position.y-global_position.y-(line_width/2.0)
		
		draw_line(Vector2(0, height), Vector2(size.x*0.9, height), get_theme_color("accent_color", "Editor"), line_width*0.2)

##################### SPACE BELOW ##############################################
################################################################################

func add_extra_scroll_area_to_timeline(fake_arg:Variant=null) -> void:
	if %Timeline.get_children().size() > 4:
		%Timeline.custom_minimum_size.y = 0
		%Timeline.size.y = 0
		if %Timeline.size.y + 200 > %TimelineArea.size.y:
			%Timeline.custom_minimum_size = Vector2(0, %Timeline.size.y + 200)
