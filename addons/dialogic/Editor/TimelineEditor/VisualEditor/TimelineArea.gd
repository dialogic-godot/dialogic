@tool
extends ScrollContainer

# Script of the TimelineArea (that contains the event blocks).
# Manages the drawing of the event lines and event dragging.


enum DragTypes {NOTHING, NEW_EVENT, EXISTING_EVENTS}

var drag_type: DragTypes = DragTypes.NOTHING
var drag_data: Variant
var drag_to_position := 0:
	set(value):
		drag_to_position = value
		drag_to_position_updated = true
var dragging := false
var drag_to_position_updated := false


signal drag_completed(type, index, data)
signal drag_canceled()


func _ready() -> void:
	resized.connect(add_extra_scroll_area_to_timeline)
	%Timeline.child_entered_tree.connect(add_extra_scroll_area_to_timeline)

	# This prevents the view to turn black if you are editing this scene in Godot
	if find_parent('EditorView'):
		%TimelineArea.get_theme_color("background_color", "CodeEdit")


#region EVENT DRAGGING
################################################################################

func start_dragging(type:DragTypes, data:Variant) -> void:
	dragging = true
	drag_type = type
	drag_data = data
	drag_to_position_updated = false


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


func finish_dragging() -> void:
	dragging = false
	if drag_to_position_updated and get_global_rect().has_point(get_global_mouse_position()):
		drag_completed.emit(drag_type, drag_to_position, drag_data)
	else:
		drag_canceled.emit()
	queue_redraw()

#endregion


#region LINE DRAWING
################################################################################

func _draw() -> void:
	var line_width := 5 * DialogicUtil.get_editor_scale()
	var horizontal_line_length := 100 * DialogicUtil.get_editor_scale()
	var color_multiplier := Color(1,1,1,0.25)
	var selected_color_multiplier := Color(1,1,1,1)


	## Draw Event Lines
	for idx in range($Timeline.get_child_count()):
		var block: Control = $Timeline.get_child(idx)

		if not "resource" in block:
			continue

		if not block.visible:
			continue

		if block.resource is DialogicEndBranchEvent:
			continue

		if not (block.has_any_enabled_body_content or block.resource.can_contain_events):
			continue

		var icon_panel_height: int = block.get_node('%IconPanel').size.y
		var rect_position: Vector2 = block.get_node('%IconPanel').global_position+Vector2(0,1)*block.get_node('%IconPanel').size+Vector2(0,-4)
		var color: Color = block.resource.event_color

		if block.is_selected() or block.end_node and block.end_node.is_selected():
			color *= selected_color_multiplier
		else:
			color *= color_multiplier

		if block.expanded and not block.resource.can_contain_events:
			draw_rect(Rect2(rect_position-global_position+Vector2(line_width, 0), Vector2(line_width, block.size.y-block.get_node('%IconPanel').size.y)), color)

		## If the indentation has not changed, nothing else happens
		if idx >= $Timeline.get_child_count()-1 or block.current_indent_level >= $Timeline.get_child(idx+1).current_indent_level:
			continue

		## Draw connection between opening and end branch events
		if block.resource.can_contain_events:
			var end_node: Node = block.end_node

			if end_node != null:
				var v_length: float = end_node.global_position.y+end_node.size.y/2-rect_position.y
				#var rect_size := Vector2(line_width, )
				var offset := Vector2(line_width, 0)

				# Draw vertical line
				draw_rect(Rect2(rect_position-global_position+offset, Vector2(line_width, v_length)), color)
				# Draw horizonal line (on END BRANCH event)
				draw_rect(Rect2(
							rect_position.x+line_width-global_position.x+offset.x,
							rect_position.y+v_length-line_width-global_position.y,
							horizontal_line_length-offset.x,
							line_width),
							color)

		if block.resource.wants_to_group:
			var group_color: Color = block.resource.event_color*color_multiplier
			var group_starter := true
			if idx != 0:
				var block_above := $Timeline.get_child(idx-1)
				if block_above.resource.event_name == block.resource.event_name:
					group_starter = false
				if block_above.resource is DialogicEndBranchEvent and block_above.parent_node.resource.event_name == block.resource.event_name:
					group_starter = false

			## Draw small horizontal line on any event in group
			draw_rect(Rect2(
					rect_position.x-global_position.x-line_width,
					rect_position.y-global_position.y-icon_panel_height/2,
					line_width,
					line_width),
					group_color)

			if group_starter:
				## Find the last event in the group (or that events END BRANCH)
				var sub_idx := idx
				var group_end_idx := idx
				while sub_idx < $Timeline.get_child_count()-1:
					sub_idx += 1
					if $Timeline.get_child(sub_idx).current_indent_level == block.current_indent_level-1:
						group_end_idx = sub_idx-1
						break

				var end_node := $Timeline.get_child(group_end_idx)

				var offset := Vector2(-2*line_width, -icon_panel_height/2)
				var v_length: float = end_node.global_position.y - rect_position.y + icon_panel_height

				## Draw vertical line
				draw_rect(Rect2(
							rect_position.x - global_position.x + offset.x,
							rect_position.y - global_position.y + offset.y,
							line_width,
							v_length),
							group_color)


	## Draw line that indicates the dragging position
	if dragging and get_global_rect().has_point(get_global_mouse_position()):
		var height: int = 0
		if drag_to_position == %Timeline.get_child_count():
			height = %Timeline.get_child(-1).global_position.y+%Timeline.get_child(-1).size.y-global_position.y-(line_width/2.0)
		else:
			height = %Timeline.get_child(drag_to_position).global_position.y-global_position.y-(line_width/2.0)

		draw_line(Vector2(0, height), Vector2(size.x*0.9, height), get_theme_color("accent_color", "Editor"), line_width*.3)

#endregion


#region SPACE BELOW
################################################################################

func add_extra_scroll_area_to_timeline(fake_arg:Variant=null) -> void:
	if %Timeline.get_children().size() > 4:
		%Timeline.custom_minimum_size.y = 0
		%Timeline.size.y = 0
		if %Timeline.size.y + 200 > %TimelineArea.size.y:
			%Timeline.custom_minimum_size = Vector2(0, %Timeline.size.y + 200)

#endregion
