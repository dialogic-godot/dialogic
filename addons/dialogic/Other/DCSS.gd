tool
class_name DCSS

static func style(node, style:Dictionary) -> StyleBoxFlat:
	var scale = DialogicUtil.get_editor_scale()
	var s = StyleBoxFlat.new()
	for property in style.keys():
		if property == 'border-radius':
			var radius = style[property] * scale
			s.set('corner_radius_top_left', radius)
			s.set('corner_radius_top_right', radius)
			s.set('corner_radius_bottom_left', radius)
			s.set('corner_radius_bottom_right', radius)
		if property == 'background':
			s.set('bg_color', Color(style[property]))
		if property == 'border':
			var width = style[property] * scale
			s.set('border_width_left', width)
			s.set('border_width_right', width)
			s.set('border_width_top', width)
			s.set('border_width_bottom', width)
		if property == 'border-color':
			s.set('border_color', Color(style[property]))
		if property == 'padding':
			var value_v = style[property][0] * scale
			var value_h = style[property][1] * scale
			s.set('content_margin_top', value_v)
			s.set('content_margin_bottom', value_v)
			s.set('content_margin_left', value_h)
			s.set('content_margin_right', value_h)
	#print('scale is: ', scale)
	
	node.set('custom_styles/normal', s)
	node.set('custom_styles/focus', s)
	node.set('custom_styles/read_only', s)
	node.set('custom_styles/hover', s)
	node.set('custom_styles/pressed', s)
	node.set('custom_styles/disabled', s)
	return s
