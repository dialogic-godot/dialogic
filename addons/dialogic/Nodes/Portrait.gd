extends Control

var character_data = {
	'name': 'Default',
	'image': "res://addons/dialogic/Example Assets/portraits/df-3.png",
	'color': Color(0.973511, 1, 0.152344),
	'file': '',
	'mirror_portraits': false
}
var positions = {
	'left': Vector2(-400, 0),
	'right': Vector2(+400, 0),
	'center': Vector2(0, 0),
	'center_right': Vector2(200, 0),
	'center_left': Vector2(-200, 0)}

var direction = 'left'
var debug = false
var fading_out = false

func init(expression: String = '', position_offset = 'left', mirror = false) -> void:
	rect_position += positions[position_offset]
	direction = position_offset
	modulate = Color(1,1,1,0)
	
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

	set_portrait(expression)
	
	if $TextureRect.get('texture'):
		rect_position -= Vector2(
			$TextureRect.texture.get_width() * 0.5,
			$TextureRect.texture.get_height()
		) * custom_scale
	
	# the mirror setting of the character
	if character_data["data"].has('mirror_portraits'):
		if character_data["data"]['mirror_portraits']:
			$TextureRect.flip_h = true
	# the mirror setting of the join event
	if mirror:
		$TextureRect.flip_h = !$TextureRect.flip_h


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
	
	var portraits = character_data['portraits']
	for p in portraits:
		if p['name'] == expression:
			if is_scene(p['path']):
				var custom_node = load(p['path'])
				var instance = custom_node.instance()
				instance.name = 'DialogicCustomPortraitScene'
				add_child(instance)
				
				$TextureRect.texture = ImageTexture.new()
			else:
				if ResourceLoader.exists(p['path']):
					$TextureRect.texture = load(p['path'])
				else:
					$TextureRect.texture = ImageTexture.new()


# Tween stuff
func fade_in(time = 0.5):
	tween_modulate(modulate, Color(1,1,1, 1), time)
	
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
	if not fading_out:
		tween_modulate(modulate, Color(0.5,0.5,0.5, 1))
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
