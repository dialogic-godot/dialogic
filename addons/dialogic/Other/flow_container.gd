tool
extends Container

class _LineData:
	var child_count:int = 0
	var min_line_height:int = 0
	var min_line_length:int = 0
	var stretch_avail:int = 0
	var stretch_ratio_total:float = 0

export(int) var hseparation = 1 setget set_h_separation
export(int) var vseparation = 1 setget set_v_separation
export(bool) var vertical:bool = false

var cached_size:int = 0
var cached_line_count:int = 0


func set_h_separation(value:int) -> void:
	hseparation = value
	add_constant_override("hseparation", value)
	property_list_changed_notify()
	queue_sort()


func set_v_separation(value:int) -> void:
	vseparation = value
	add_constant_override("vseparation", value)
	property_list_changed_notify()
	queue_sort()


func _resort() -> void:
	var separation_horizontal:int = get_constant("hseparation")
	var separation_vertical:int = get_constant("vseparation")
	
	# Not implemented in 3.4
	# var rtl = is_layout_rtl()
	var rtl = false

	var children_minsize_cache = {}

	var lines_data = []

	var ofs:Vector2;
	var line_height:int = 0;
	var line_length:int = 0;
	var line_stretch_ratio_total:float = 0;
	var current_container_size:int = get_rect().size.y if vertical else get_rect().size.x
	var children_in_current_line:int = 0

	# First pass for line wrapping and minimum size calculation.
	for i in get_child_count():
		var child:Control = get_child(i) as Control
		if (!child or !child.is_visible_in_tree()):
			continue
		
		if (child.is_set_as_toplevel()):
			continue

		var child_msc:Vector2 = child.get_combined_minimum_size()

		if (vertical): # /* Vertical */
			if (children_in_current_line > 0):
				ofs.y += separation_vertical;
			
			if (ofs.y + child_msc.y > current_container_size):
				line_length = ofs.y - separation_vertical;
				var line_data = _LineData.new()
				line_data.child_count = children_in_current_line
				line_data.min_line_height = line_height
				line_data.min_line_length = line_length
				line_data.stretch_avail = current_container_size - line_length
				line_data.stretch_ratio_total = line_stretch_ratio_total
				lines_data.push_back(line_data)

				# Move in new column (vertical line).
				ofs.x += line_height + separation_horizontal;
				ofs.y = 0;
				line_height = 0;
				line_stretch_ratio_total = 0;
				children_in_current_line = 0;

			line_height = max(line_height, child_msc.x);
			if (child.get_v_size_flags() & SIZE_EXPAND):
				line_stretch_ratio_total += child.get_stretch_ratio()
			
			ofs.y += child_msc.y;

		else: # /* HORIZONTAL */
			if (children_in_current_line > 0):
				ofs.x += separation_horizontal
			
			if (ofs.x + child_msc.x > current_container_size):
				line_length = ofs.x - separation_horizontal;
				var line_data = _LineData.new()
				line_data.child_count = children_in_current_line
				line_data.min_line_height = line_height
				line_data.min_line_length = line_length
				line_data.stretch_avail = current_container_size - line_length
				line_data.stretch_ratio_total = line_stretch_ratio_total
				lines_data.push_back(line_data)

				# Move in new line.
				ofs.y += line_height + separation_vertical;
				ofs.x = 0;
				line_height = 0;
				line_stretch_ratio_total = 0;
				children_in_current_line = 0;
			

			line_height = max(line_height, child_msc.y);
			if (child.get_h_size_flags() & SIZE_EXPAND):
				line_stretch_ratio_total += child.get_stretch_ratio()
			
			ofs.x += child_msc.x

		children_minsize_cache[child] = child_msc;
		children_in_current_line += 1
	
	line_length = (ofs.y) if vertical else (ofs.x)
	
	var ld:_LineData = _LineData.new()
	ld.child_count = children_in_current_line
	ld.min_line_length = line_height
	ld.min_line_length = line_length
	ld.stretch_avail = current_container_size - line_length
	ld.stretch_ratio_total = line_stretch_ratio_total
	lines_data.push_back(ld)

	# Second pass for in-line expansion and alignment.

	var current_line_idx = 0
	var child_idx_in_line = 0

	ofs.x = 0
	ofs.y = 0

	for i in get_child_count():
		var child:Control = get_child(i) as Control
		if (!child or !child.is_visible_in_tree()):
			continue
		
		if (child.is_set_as_toplevel()):
			continue
		
		var child_size:Vector2 = children_minsize_cache[child];

		var line_data:_LineData = lines_data[current_line_idx]
		if (child_idx_in_line >= lines_data[current_line_idx].child_count):
			current_line_idx += 1;
			child_idx_in_line = 0;
			if (vertical):
				ofs.x += line_data.min_line_height + separation_horizontal
				ofs.y = 0
			else:
				ofs.x = 0
				ofs.y += line_data.min_line_height + separation_vertical
			
			line_data = lines_data[current_line_idx]

		if (vertical): # /* VERTICAL */
			if (child.get_h_size_flags() & (SIZE_FILL | SIZE_SHRINK_CENTER | SIZE_SHRINK_END)):
				child_size.x = line_data.min_line_height;

			if (child.get_v_size_flags() & SIZE_EXPAND):
				var stretch:int = line_data.stretch_avail * child.get_stretch_ratio() / line_data.stretch_ratio_total
				child_size.y += stretch;
			

		else: # /* HORIZONTAL */
			if (child.get_v_size_flags() & (SIZE_FILL | SIZE_SHRINK_CENTER | SIZE_SHRINK_END)):
				child_size.y = line_data.min_line_height;

			if (child.get_h_size_flags() & SIZE_EXPAND):
				var stretch:int = line_data.stretch_avail * child.get_stretch_ratio() / line_data.stretch_ratio_total;
				child_size.x += stretch
		

		var child_rect:Rect2 = Rect2(ofs, child_size)
		if (rtl):
			child_rect.position.x = get_rect().size.x - child_rect.position.x - child_rect.size.x

		fit_child_in_rect(child, child_rect);

		if (vertical): # /* VERTICAL */
			ofs.y += child_size.y + separation_vertical;
		else: # /* HORIZONTAL */
			ofs.x += child_size.x + separation_horizontal;

		child_idx_in_line += 1
	
	cached_size = (ofs.x if vertical else ofs.y) + line_height;
	cached_line_count = lines_data.size();


func _get_minimum_size() -> Vector2:
	var minimum:Vector2 = Vector2()

	for i in get_child_count():
		var child:Control = get_child(i) as Control
		
		if (!child or !child.is_visible_in_tree()):
			continue
		
		if (child.is_set_as_toplevel()):
			continue

		var size:Vector2 = child.get_combined_minimum_size()

		if (vertical): # /* VERTICAL */
			minimum.y = max(minimum.y, size.y);
			minimum.x = cached_size;

		else: # /* HORIZONTAL */
			minimum.x = max(minimum.x, size.x);
			minimum.y = cached_size;

	return minimum;


func _notification(p_what:int) -> void:
	match (p_what):
		NOTIFICATION_SORT_CHILDREN:
			_resort();
			minimum_size_changed()
		
		NOTIFICATION_THEME_CHANGED:
			minimum_size_changed()
		
		NOTIFICATION_TRANSLATION_CHANGED:
			queue_sort()
