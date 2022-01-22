extends Control

var z_index = 0

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

var current_state := {'character':'', 'portrait':'', 'position':'', 'mirrored':false}


func init(expression: String = '') -> void:
	set_portrait(expression)


func _ready():
	if debug:
		print('Character data loaded: ', character_data)
		print(rect_position, $TextureRect.rect_size)


func set_portrait(expression: String) -> void:
	current_state['portrait'] = expression
	if expression == "(Don't change)":
		return

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
	current_state['mirrored'] = value
	if character_data["data"].has('mirror_portraits'):
		if character_data["data"]['mirror_portraits']:
			$TextureRect.flip_h = !value
		else:
			$TextureRect.flip_h = value
	else:
		$TextureRect.flip_h = value


func move_to_position(position_offset, animation= 0, time = 4):
	modulate = Color.transparent
	
	var positions = {
		'left': Vector2(-400, 0),
		'right': Vector2(+400, 0),
		'center': Vector2(0, 0),
		'center_right': Vector2(200, 0),
		'center_left': Vector2(-200, 0)}
	
	direction = position_offset
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
		
	animate_in(animation, time)

func animate_in(animation = 0, time = -1):
	if animation == -1:
		animation = DialogicUtil.get_default_animation_id()
	var data = DialogicUtil.get_animation_data(animation)
	print("animatew", data, time)
	
	if time == -1:
		time = data['default_length']
	
	# do custom animation
	## INSTANT animation:
	if animation == 1:
		modulate = Color.white
	## FLOAT_UP animation:
	elif animation == 2:
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
	## FADE animation
	elif animation == 3:
		tween_modulate(Color.transparent, Color.white, time)
	## POP animation
	elif animation == 4:
		$Tween.interpolate_property(self, 'modulate', Color.transparent, Color.white, time, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
		$TextureRect.rect_pivot_offset = $TextureRect.rect_size/2
		$Tween.interpolate_property($TextureRect, 'rect_scale', Vector2(0,0), Vector2(1,1), time, Tween.TRANS_BOUNCE, Tween.EASE_OUT)
	
	$Tween.start()


func fade_out(time = 0.5):
	fading_out = true
	var end = modulate
	end.a = 0
	tween_modulate(modulate, end, time)
	$Tween.connect("tween_all_completed", self, "queue_free")


func focus():
	if not ($Tween.is_active() or fading_out):
		tween_modulate(modulate, Color(1,1,1, 1))


func focusout(dim_color = Color(0.5, 0.5, 0.5, 1.0)):
	if single_portrait_mode:
		dim_color.a = 0
	if not fading_out:
		tween_modulate(modulate, dim_color)


func tween_modulate(from_value, to_value, time = 0.5):
	$Tween.stop(self, 'modulation')
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
