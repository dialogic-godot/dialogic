tool
extends Container

# The flow container will fit as many children in a row as it can
# using their minimum size, and will then continue on the next row.
# Does not use SIZE_EXPAND flags of children.

# TODO: half-respect vertical SIZE_EXPAND flags by expanding the child to match
#       the tallest child in that row?
# TODO: Respect scaled children?
# TODO: Can we find a way to intuitively use a child's horizontal SIZE_EXPAND
#       flag?

export var horizontal_margin: float = 5
export var vertical_margin: float = 5

# Used to make our parent re-evaluate our size when we have to create more or
# less rows to fit in all the children.
var _reported_height_at_last_minimum_size_call: float = 0


func _init() -> void:
	size_flags_horizontal = SIZE_EXPAND_FILL


func _ready():
	pass


func _get_minimum_size() -> Vector2:
	var max_child_width: float = 0
	
	for child in get_children():
		if not child.has_method("get_combined_minimum_size"):
			break
		
		var requested_size: Vector2 = child.get_combined_minimum_size()
		if requested_size.x > max_child_width:
			max_child_width = requested_size.x
	
	var height := _calculate_layout(false)
	_reported_height_at_last_minimum_size_call = height
	
	return Vector2(max_child_width, height)


func _notification(what):
	if (what==NOTIFICATION_SORT_CHILDREN):
		var height = _calculate_layout(true)
		
		if height != _reported_height_at_last_minimum_size_call:
			_make_parent_reevaluate_our_size()

# If apply is true, the children will actually be moved to the calculated
# locations.
# Returns the resulting height.
func _calculate_layout(apply: bool) -> float:
	var child_position: Vector2 = Vector2(0, 0)
	var row_height: float = 0
	var container_width: float = rect_size.x
	var num_children_in_current_row: float = 0
	
	for child in get_children():
		if not child.has_method("get_combined_minimum_size"):
			continue
		if not child.visible:
			continue
		
		var child_min_size: Vector2 = child.get_combined_minimum_size()
		
		if num_children_in_current_row > 0:
			child_position.x += horizontal_margin
		
		if child_position.x + child_min_size.x > container_width:
			# Go to the next row.
			child_position = Vector2(0, child_position.y + row_height + vertical_margin)
			row_height = 0
			num_children_in_current_row = 0
		
		if apply:
			fit_child_in_rect(child, Rect2(child_position, child_min_size))
		
		if child_min_size.y > row_height:
			row_height = child_min_size.y
		
		child_position.x += child_min_size.x
		num_children_in_current_row += 1
	
	return child_position.y + row_height


func _make_parent_reevaluate_our_size():
	# Hacky solution. Once there is a function for this, use it.
	rect_min_size = Vector2(0, 20000)
	rect_min_size = Vector2(0, 0)


# Code by https://github.com/Wcubed/horizontal_flow_container
# MIT License

# Copyright (c) 2020 Wybe Westra

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 #SOFTWARE.
