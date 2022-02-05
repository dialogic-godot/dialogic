extends Tween

var loop = 1

signal finished_animation

var _animation_data = []

enum PLAY_MODE {
	NORMAL,
	BACKWARDS
}

# Needed to use interpolate_property
var _fake_property: Dictionary = {}
var _callbacks := {}

func _ready():
	connect("tween_started", self, '_on_tween_started')
	connect("tween_step", self, '_on_tween_step_with_easing')
	connect("tween_step", self, '_on_tween_step_with_easing_callback')
	connect("tween_step", self, '_on_tween_step_with_easing_funcref')
	connect("tween_step", self, '_on_tween_step_without_easing')
	connect("tween_completed", self, '_on_tween_completed')
	

func play(node, animation_name, duration):
	var script = DialogicAnimaResources.get_animation_script(animation_name.strip_edges())

	if not script:
		printerr('animation not found: %s' % animation_name)

		return duration
	
	var real_duration = script.generate_animation(self, {'node':node, 'duration':duration, 'wait_time':0})
	
	if real_duration is float:
		duration = real_duration
	
	var index := 0
	
	for animation_data in _animation_data:
		var easing_points

		if animation_data.has('easing'):
			if animation_data.easing is FuncRef:
				easing_points = animation_data.easing
			else:
				easing_points = get_easing_points(animation_data.easing)

		if animation_data.has('easing_points'):
			easing_points = animation_data.easing_points

		animation_data._easing_points = easing_points

		animation_data._animation_callback = funcref(self, '_calculate_from_and_to')

		if easing_points is Array:
			animation_data._use_step_callback = '_on_tween_step_with_easing'
		elif easing_points is String:
			animation_data._use_step_callback = '_on_tween_step_with_easing_callback'
		elif easing_points is FuncRef:
			animation_data._use_step_callback = '_on_tween_step_with_easing_funcref'
		else:
			animation_data._use_step_callback = '_on_tween_step_without_easing'

		index += 1

	var started := start()

	if not started:
		printerr('something went wrong while trying to start the tween')
	
	if is_connected("tween_all_completed", self, 'finished_once'): disconnect("tween_all_completed", self, 'finished_once')
	connect('tween_all_completed', self, 'finished_once', [node, animation_name, duration])

func finished_once(node, animation, duration):
	loop -= 1
	if loop > 0:
		play(node, animation, duration)
	else:
		emit_signal('finished_animation')

# Given an array of frames generates the animation data using relative end value
#
# frames = [{
#	percentage = the percentage of the animation
#	to = the relative end value
#	easing_points = the easing points for the bezier curver (optional)
# }]
#
func add_relative_frames(data: Dictionary, property: String, frames: Array) -> float:
	return _add_frames(data, property, frames, true)

#
# Given an array of frames generates the animation data using absolute end value
#
# frames = [{
#	percentage = the percentage of the animation
#	to = the relative end value
#	easing_points = the easing points for the bezier curver (optional)
# }]
#
func add_frames(data: Dictionary, property: String, frames: Array) -> float:
	return _add_frames(data, property, frames)


func _add_frames(data: Dictionary, property: String, frames: Array, relative: bool = false) -> float:
	var duration: float = data.duration if data.has('duration') else 0.0
	var _wait_time: float = data._wait_time if data.has('_wait_time') else 0.0
	var last_duration := 0.0

	var keys_to_ignore = ['duration', '_wait_time']
	for frame in frames:
		var percentage = frame.percentage if frame.has('percentage') else 100.0
		percentage /= 100.0

		var frame_duration = max(0.000001, duration * percentage)
		var diff = frame_duration - last_duration
		var is_first_frame = true
		var is_last_frame = percentage == 1

		var animation_data = {
			property = property,
			relative = relative,
			duration = diff,
			_wait_time = _wait_time
		}

		# We need to restore the animation just before the node is animated
		# but we also need to consider that a node can have multiple
		# properties animated, so we need to restore it only before the first
		# animation starts
		for animation in _animation_data:
			if animation.node == data.node:
				is_first_frame = false

				if animation.has('_is_last_frame'):
					is_last_frame = false

		if is_first_frame:
			animation_data._is_first_frame = true

		if is_last_frame:
			animation_data._is_last_frame = true

		for key in frame:
			if key != 'percentage':
				animation_data[key] = frame[key]

		for key in data:
			if key == 'callback' and percentage < 1:
				animation_data.erase(key)
			elif keys_to_ignore.find(key) < 0:
				animation_data[key] = data[key]

		add_animation_data(animation_data)

		last_duration = frame_duration
		_wait_time += diff

	return _wait_time


func add_animation_data(animation_data: Dictionary, play_mode: int = PLAY_MODE.NORMAL) -> void:
	_animation_data.push_back(animation_data)

	var index = str(_animation_data.size())
	var duration = animation_data.duration if animation_data.has('duration') else 1
	var property_key = 'p' + index
	
	_fake_property[property_key] = 0.0

	if animation_data.has('on_completed') and animation_data.has('_is_last_frame'):
		_callbacks[property_key] = animation_data.on_completed

	var from := 0.0 if play_mode == PLAY_MODE.NORMAL else 1.0
	var to := 1.0 - from

	interpolate_property(
		self,
		'_fake_property:' + property_key,
		from,
		to,
		duration,
		Tween.TRANS_LINEAR,
		Tween.EASE_IN_OUT,
		animation_data._wait_time
	)


func _on_tween_step_with_easing(object: Object, key: NodePath, _time: float, elapsed: float):
	var index := _get_animation_data_index(key)

	if _animation_data[index]._use_step_callback != '_on_tween_step_with_easing':
		return

	var easing_points = _animation_data[index]._easing_points
	var p1 = easing_points[0]
	var p2 = easing_points[1]
	var p3 = easing_points[2]
	var p4 = easing_points[3]

	var easing_elapsed = _cubic_bezier(Vector2.ZERO, Vector2(p1, p2), Vector2(p3, p4), Vector2(1, 1), elapsed)

	_animation_data[index]._animation_callback.call_func(index, easing_elapsed)

func _on_tween_step_with_easing_callback(object: Object, key: NodePath, _time: float, elapsed: float):
	var index := _get_animation_data_index(key)

	if _animation_data[index]._use_step_callback != '_on_tween_step_with_easing_callback':
		return

	var easing_points_function = _animation_data[index]._easing_points
	var easing_callback = funcref(self, easing_points_function)
	var easing_elapsed = easing_callback.call_func(elapsed)

	_animation_data[index]._animation_callback.call_func(index, easing_elapsed)

func _on_tween_step_with_easing_funcref(object: Object, key: NodePath, _time: float, elapsed: float):
	var index := _get_animation_data_index(key)

	if _animation_data[index]._use_step_callback != '_on_tween_step_with_easing_funcref':
		return

	var easing_callback = _animation_data[index]._easing_points
	var easing_elapsed = easing_callback.call_func(elapsed)

	_animation_data[index]._animation_callback.call_func(index, easing_elapsed)

func _on_tween_step_without_easing(object: Object, key: NodePath, _time: float, elapsed: float):
	var index := _get_animation_data_index(key)

	if _animation_data[index]._use_step_callback != '_on_tween_step_without_easing':
		return

	_animation_data[index]._animation_callback.call_func(index, elapsed)

func _get_animation_data_index(key: NodePath) -> int:
	var s = str(key)

	return int(s.replace('_fake_property:p', '')) - 1

func _cubic_bezier(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, t: float) -> float:
	var q0 = p0.linear_interpolate(p1, t)
	var q1 = p1.linear_interpolate(p2, t)
	var q2 = p2.linear_interpolate(p3, t)

	var r0 = q0.linear_interpolate(q1, t)
	var r1 = q1.linear_interpolate(q2, t)

	var s = r0.linear_interpolate(r1, t)

	return s.y

func _calculate_from_and_to(index: int, value: float) -> void:
	var animation_data = _animation_data[index]
	var node = animation_data.node

	var do_calculate = true

	if animation_data.has('_recalculate_from_to') and not animation_data._recalculate_from_to and animation_data.has('_property_data'):
		do_calculate = false

	if do_calculate:
		_do_calculate_from_to(node, animation_data)

	if animation_data._property_data.has('subkey'):
		animation_data._animation_callback = funcref(self, '_on_animation_with_subkey')
	elif animation_data._property_data.has('key'):
		animation_data._animation_callback = funcref(self, '_on_animation_with_key')
	else:
		animation_data._animation_callback = funcref(self, '_on_animation_without_key')

	_animation_data[index]._animation_callback.call_func(index, value)

func _do_calculate_from_to(node: Node, animation_data: Dictionary) -> void:
	var from
	var to
	var relative = animation_data.relative if animation_data.has('relative') else false
	var node_from = DialogicAnimaPropertiesHelper.get_property_initial_value(node, animation_data.property)

	if animation_data.has('from'):
		from = _maybe_convert_from_deg_to_rad(node, animation_data, animation_data.from)
		from = _maybe_calculate_relative_value(relative, from, node_from)
	else:
		from = node_from
		animation_data.__from = from

	if animation_data.has('to'):
		to = _maybe_convert_from_deg_to_rad(node, animation_data, animation_data.to)
		to = _maybe_calculate_relative_value(relative, to, from)
	else:
		to = from
		animation_data.__to = to

	if animation_data.has('pivot'):
		if node is Spatial:
			printerr('3D Pivot not supported yet')
		else:
			DialogicAnimaPropertiesHelper.set_2D_pivot(animation_data.node, animation_data.pivot)

	animation_data._property_data = DialogicAnimaPropertiesHelper.map_property_to_godot_property(node, animation_data.property)
	
	animation_data._property_data.diff = to - from
	animation_data._property_data.from = from

func _maybe_calculate_relative_value(relative, value, current_node_value):
	if not relative:
		return value

	return value + current_node_value

func _maybe_convert_from_deg_to_rad(node: Node, animation_data: Dictionary, value):
	if not node is Spatial or animation_data.property.find('rotation') < 0:
		return value

	if value is Vector3:
		return Vector3(deg2rad(value.x), deg2rad(value.y), deg2rad(value.z))

	return deg2rad(value)

func _on_animation_with_key(index: int, elapsed: float) -> void:
	var animation_data = _animation_data[index]
	var property_data = _animation_data[index]._property_data
	var node = animation_data.node
	var value = property_data.from + (property_data.diff * elapsed)

	node[property_data.property_name][property_data.key] = value

func _on_animation_with_subkey(index: int, elapsed: float) -> void:
	var animation_data = _animation_data[index]
	var property_data = _animation_data[index]._property_data
	var node = animation_data.node
	var value = property_data.from + (property_data.diff * elapsed)

	node[property_data.property_name][property_data.key][property_data.subkey] = value

func _on_animation_without_key(index: int, elapsed: float) -> void:
	var animation_data = _animation_data[index]
	var property_data = _animation_data[index]._property_data
	var node = animation_data.node
	var value = property_data.from + (property_data.diff * elapsed)

	if property_data.has('callback'):
		property_data.callback.call_func(property_data.param, value)

		return

	node[property_data.property_name] = value

#
# We don't want the user to specify the from/to value as color
# we animate opacity.
# So this function converts the "from = #" -> Color(.., .., .., #)
# same for the to value
#
func _maybe_adjust_modulate_value(animation_data: Dictionary, value):
	var property = animation_data.property
	var node = animation_data.node

	if not property == 'opacity':
		return value

	if value is int or value is float:
		var color = node.modulate

		color.a = value

		return color

	return value

func _on_tween_completed(_ignore, property_name: String) -> void:
	var property_key = property_name.replace(':_fake_property:', '')

	if _callbacks.has(property_key):
		var callback = _callbacks[property_key]

		if not callback is Array or callback.size() == 1:
			callback[0].call_func()
		else:
			callback[0].call_funcv(callback[1])

func _on_tween_started(_ignore, key) -> void:
	var index := _get_animation_data_index(key)
	#var hide_strategy = _visibility_strategy
	var animation_data = _animation_data[index]

#	if animation_data.has('hide_strategy'):
#		hide_strategy = animation_data.hide_strategy

	var node = animation_data.node
	var should_restore_visibility := false
	var should_restore_modulate := false

#	if hide_strategy == Anima.VISIBILITY.HIDDEN_ONLY:
#		should_restore_visibility = true
#	elif hide_strategy == Anima.VISIBILITY.HIDDEN_AND_TRANSPARENT:
#		should_restore_modulate = true
#		should_restore_visibility = true
#	elif hide_strategy == Anima.VISIBILITY.TRANSPARENT_ONLY:
#		should_restore_modulate = true

	if should_restore_modulate:
		var old_modulate = node.get_meta('_old_modulate')

		if old_modulate:
			node.modulate = old_modulate

	if should_restore_visibility:
		node.show()

	var should_trigger_on_started: bool = animation_data.has('_is_first_frame') and animation_data._is_first_frame and animation_data.has('on_started')
	if should_trigger_on_started:
		var fn: FuncRef
		var args: Array = []
		if animation_data.on_started is Array:
			fn = animation_data.on_started[0]
			args = animation_data.on_started.slice(1, -1)
		else:
			fn = animation_data.on_started

		fn.call_funcv(args)


####################################################################################################
####################################################################################################
##										FROM ANIMA EASING
####################################################################################################
####################################################################################################

enum EASING {
	LINEAR,   
	EASE,
	EASE_IN_OUT,
	EASE_IN,
	EASE_OUT,
	EASE_IN_SINE,
	EASE_OUT_SINE,
	EASE_IN_OUT_SINE,
	EASE_IN_QUAD,
	EASE_OUT_QUAD,
	EASE_IN_OUT_QUAD,
	EASE_IN_CUBIC,
	EASE_OUT_CUBIC,
	EASE_IN_OUT_CUBIC,
	EASE_IN_QUART,
	EASE_OUT_QUART,
	EASE_IN_OUT_QUART,
	EASE_IN_QUINT,
	EASE_OUT_QUINT,
	EASE_IN_OUT_QUINT,
	EASE_IN_EXPO,
	EASE_OUT_EXPO,
	EASE_IN_OUT_EXPO,
	EASE_IN_CIRC,
	EASE_OUT_CIRC,
	EASE_IN_OUT_CIRC,
	EASE_IN_BACK,
	EASE_OUT_BACK,
	EASE_IN_OUT_BACK,
	EASE_IN_ELASTIC,
	EASE_OUT_ELASTIC,
	EASE_IN_OUT_ELASTIC,
	EASE_IN_BOUNCE,
	EASE_OUT_BOUNCE,
	EASE_IN_OUT_BOUNCE,
}

const _easing_mapping = {
	EASING.LINEAR: null,
	EASING.EASE: [0.25, 0.1, 0.25, 1],
	EASING.EASE_IN_OUT: [0.42, 0, 0.58, 1],
	EASING.EASE_IN: [0.42, 0, 1, 1],
	EASING.EASE_OUT: [0, 0, 0.58, 1],
	EASING.EASE_IN_SINE: [0, 0, 1, .5],
	EASING.EASE_OUT_SINE: [0.61, 1, 0.88, 1],
	EASING.EASE_IN_OUT_SINE: [0.37, 0, 0.63, 1],
	EASING.EASE_IN_QUAD: [0.11, 0, 0.5, 0],
	EASING.EASE_OUT_QUAD: [0.5, 1.0, 0.89, 1],
	EASING.EASE_IN_OUT_QUAD: [0.45, 0, 0.55, 1],
	EASING.EASE_IN_CUBIC: [0.32, 0, 0.67, 0],
	EASING.EASE_OUT_CUBIC: [0.33, 1, 0.68, 1],
	EASING.EASE_IN_OUT_CUBIC: [0.65, 0, 0.35, 1],
	EASING.EASE_IN_QUART: [0.5, 0, 0.75, 0],
	EASING.EASE_OUT_QUART: [0.25, 1, 0.5, 1],
	EASING.EASE_IN_OUT_QUART: [0.76, 0, 0.24, 1],
	EASING.EASE_IN_QUINT: [0.64, 0, 0.78, 0],
	EASING.EASE_OUT_QUINT: [0.22, 1, 0.36, 1],
	EASING.EASE_IN_OUT_QUINT: [0.83, 0, 0.17, 1],
	EASING.EASE_IN_EXPO: [0.7, 0, 0.84, 0],
	EASING.EASE_OUT_EXPO: [0.16, 1, 0.3, 1],
	EASING.EASE_IN_OUT_EXPO: [0.87, 0, 0.13, 1],
	EASING.EASE_IN_CIRC: [0.55, 0, 0.1, 0.45],
	EASING.EASE_OUT_CIRC: [0, 0.55, 0.45, 1],
	EASING.EASE_IN_OUT_CIRC: [0.85, 0, 0.15, 1],
	EASING.EASE_IN_BACK: [0.36, 0, 0.66, -0.56],
	EASING.EASE_OUT_BACK: [0.36, 1.56, 0.64, 1],
	EASING.EASE_IN_OUT_BACK: [0.68, -0.6, 0.32, 1.6],
	EASING.EASE_IN_ELASTIC: 'ease_in_elastic',
	EASING.EASE_OUT_ELASTIC: 'ease_out_elastic',
	EASING.EASE_IN_OUT_ELASTIC: 'ease_in_out_elastic',
	EASING.EASE_IN_BOUNCE: 'ease_in_bounce',
	EASING.EASE_OUT_BOUNCE: 'ease_out_bounce',
	EASING.EASE_IN_OUT_BOUNCE: 'ease_in_out_bounce'
}

const _ELASTIC_C4: float = (2.0 * PI) / 3.0
const _ELASTIC_C5: float = (2.0 * PI) / 4.5

static func get_easing_points(easing_name):
	if _easing_mapping.has(easing_name):
		return _easing_mapping[easing_name]

	printerr('Easing not found: ' + str(easing_name))

	return _easing_mapping[EASING.LINEAR]

static func ease_in_elastic(elapsed: float) -> float:
	if elapsed == 0:
		return 0.0
	elif elapsed == 1:
		return 1.0

	return -pow(2, 10 * elapsed - 10) * sin((elapsed * 10 - 10.75) * _ELASTIC_C4)

static func ease_out_elastic(elapsed: float) -> float:
	if elapsed == 0:
		return 0.0
	elif elapsed == 1:
		return 1.0

	return pow(2, -10 * elapsed) * sin((elapsed * 10 - 0.75) * _ELASTIC_C4) + 1

static func ease_in_out_elastic(elapsed: float) -> float:
	if elapsed == 0:
		return 0.0
	elif elapsed == 1:
		return 1.0
	elif elapsed < 0.5:
		return -(pow(2, 20 * elapsed - 10) * sin((20 * elapsed - 11.125) * _ELASTIC_C5)) / 2

	return (pow(2, -20 * elapsed + 10) * sin((20 * elapsed - 11.125) * _ELASTIC_C5)) / 2 + 1

const n1 = 7.5625;
const d1 = 2.75;

static func ease_in_bounce(elapsed: float) -> float:
	return 1 - ease_out_bounce(1.0 - elapsed)

static func ease_out_bounce(elapsed: float) -> float:
	if elapsed < 1 / d1:
		return n1 * elapsed * elapsed;
	elif elapsed < 2 / d1:
		elapsed -= 1.5 / d1

		return n1 * elapsed * elapsed + 0.75;
	elif elapsed < 2.5 / d1:
		elapsed -= 2.25 / d1

		return n1 * elapsed * elapsed + 0.9375;

	elapsed -= 2.625 / d1
	return n1 * elapsed * elapsed + 0.984375;

static func ease_in_out_bounce(elapsed: float) -> float:
	if elapsed < 0.5:
		return (1 - ease_out_bounce(1 - 2 * elapsed)) / 2
	
	return (1 + ease_out_bounce(2 * elapsed - 1)) / 2
