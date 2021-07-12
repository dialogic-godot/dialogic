extends Control

var character_data = {
	'name': 'Default',
	'image': "res://addons/dialogic/Example Assets/portraits/df-3.png",
	'color': Color(0.973511, 1, 0.152344),
	'file': '',
	'mirror_portraits': false
}

var single_portrait_mode = false
var direction = 'left'
var debug = false
var fading_out = false


func init(expression: String = '') -> void:
	set_portrait(expression)


func _ready():
	if debug:
		print('Character data loaded: ', character_data)
		print(rect_position, $TextureRect.rect_size)


func set_portrait(expression: String) -> void:
	if expression == '':
		expression = 'Default'
	
	# Clearing old custom scenes
	for n in get_children():
		if 'DialogicCustomPortraitScene' in n.name:
			n.queue_free()

	var default
	for p in character_data['portraits']:
		if p['name'] == expression:
			if is_scene(p['path']):
				var custom_node = load(p['path'])
				var instance = custom_node.instance()
				instance.name = 'DialogicCustomPortraitScene'
				add_child(instance)
				
				$TextureRect.texture = ImageTexture.new()
				return
			else:
				if ResourceLoader.exists(p['path']):
					$TextureRect.texture = load(p['path'])
				else:
					$TextureRect.texture = ImageTexture.new()
				return
		# Saving what the default is to fallback to it.
		if p['name'] == 'Default':
			default = p['path']
	
	# Everything failed, go with the default one
	if ResourceLoader.exists(default):
		$TextureRect.texture = load(default)
	else:
		$TextureRect.texture = ImageTexture.new()


func set_mirror(value):
	if character_data["data"].has('mirror_portraits'):
		if character_data["data"]['mirror_portraits']:
			$TextureRect.flip_h = !value
		else:
			$TextureRect.flip_h = value
	else:
		$TextureRect.flip_h = value


func move_to_position(position_offset, time = 0.5):
	var positions = {
		'left': Vector2(-400, 0),
		'right': Vector2(+400, 0),
		'center': Vector2(0, 0),
		'center_right': Vector2(200, 0),
		'center_left': Vector2(-200, 0)}
	
	direction = position_offset
	modulate = Color(1,1,1,0)
	tween_modulate(modulate, Color(1,1,1, 1), time)
	rect_position = positions[position_offset]
	
	# Setting the scale of the portrait
	var custom_scale = Vector2(1, 1)
	if character_data.has('data'):
		if character_data['data'].has('scale'):
			custom_scale = Vector2(
				float(character_data['data']['scale']) / 100,
				float(character_data['data']['scale']) / 100
			)
			rect_scale = custom_scale
		if character_data['data'].has('offset_x'):
			rect_position += Vector2(
				character_data['data']['offset_x'],
				character_data['data']['offset_y']
			)
			
	if $TextureRect.get('texture'):
		rect_position -= Vector2(
			$TextureRect.texture.get_width() * 0.5,
			$TextureRect.texture.get_height()
		) * custom_scale
		
	fade_in()


# Tween stuff
func fade_in(time = 0.5):
	tween_modulate(modulate, Color(1,1,1, 1), time)
	
	if single_portrait_mode == false:
		var end_pos = Vector2(0, -40) # starting at center
		if direction == 'right':
			end_pos = Vector2(+40, 0)
		elif direction == 'left':
			end_pos = Vector2(-40, 0)
		else:
			rect_position += Vector2(0, 40)

		$TweenPosition.interpolate_property(
			self, "rect_position", rect_position, rect_position + end_pos, time,
			Tween.TRANS_LINEAR, Tween.EASE_IN_OUT
		)
		$TweenPosition.start()


func fade_out(time = 0.5):
	fading_out = true
	var end = modulate
	end.a = 0
	tween_modulate(modulate, end, time)
	$Tween.connect("tween_all_completed", self, "queue_free")


func focus():
	if not fading_out:
		tween_modulate(modulate, Color(1,1,1, 1))
		var _parent = get_parent()
		if _parent:
			# Make sure that this portrait is the last to be _draw -ed
			_parent.move_child(self, _parent.get_child_count())


func focusout():
	var alpha = 1
	if single_portrait_mode:
		alpha = 0
	if not fading_out:
		tween_modulate(modulate, Color(0.5,0.5,0.5, alpha))
		var _parent = get_parent()
		if _parent:
			# Render this portrait first
			_parent.move_child(self, 0)


func tween_modulate(from_value, to_value, time = 0.5):
	$Tween.interpolate_property(
		self, "modulate", from_value, to_value, time,
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT
	)
	$Tween.start()
	return $Tween


func is_scene(path) -> bool:
	if '.tscn' in path.to_lower():
		return true
	return false
