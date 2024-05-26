@tool
class_name DCSS
	
static func inline(style:Dictionary) -> StyleBoxFlat:
	var scale:float = DialogicUtil.get_editor_scale()
	var s := StyleBoxFlat.new()
	for property in style.keys():
		match property:
			'border-left':
				s.set('border_width_left', style[property] * scale)
			'border-radius':
				var radius:float = style[property] * scale
				s.set('corner_radius_top_left', radius)
				s.set('corner_radius_top_right', radius)
				s.set('corner_radius_bottom_left', radius)
				s.set('corner_radius_bottom_right', radius)
			'background':
				s.set('bg_color', style[property])
			'border':
				var width:float = style[property] * scale
				s.set('border_width_left', width)
				s.set('border_width_right', width)
				s.set('border_width_top', width)
				s.set('border_width_bottom', width)
			'border-color':
				s.set('border_color', style[property])
			'padding':
				var value_v: float = 0.0
				var value_h: float = 0.0
				if style[property] is int:
					value_v = style[property] * scale
					value_h = value_v
				else:
					value_v = style[property][0] * scale
					value_h = style[property][1] * scale
				s.set('content_margin_top', value_v)
				s.set('content_margin_bottom', value_v)
				s.set('content_margin_left', value_h)
				s.set('content_margin_right', value_h)
			'padding-right':
				s.set('content_margin_right', style[property] * scale)
			'padding-left':
				s.set('content_margin_left', style[property] * scale)
	return s

static func style(node, style:Dictionary) -> StyleBoxFlat:
	var s:StyleBoxFlat = inline(style)
	
	node.set('theme_override_styles/normal', s)
	node.set('theme_override_styles/focus', s)
	node.set('theme_override_styles/read_only', s)
	node.set('theme_override_styles/hover', s)
	node.set('theme_override_styles/pressed', s)
	node.set('theme_override_styles/disabled', s)
	node.set('theme_override_styles/panel', s)
	return s
