extends Control

var character_data = {
	'name': 'Default',
	'image': "res://addons/dialogic/Example Assets/portraits/df-3.png",
	'color': Color(0.973511, 1, 0.152344),
	'file': ''
}
var positions = {
	'left': Vector2(-400, 0),
	'right': Vector2(+400, 0),
	'center': Vector2(0, 0),
	'center_right': Vector2(200, 0),
	'center_left': Vector2(-200, 0)}
var direction = 'left'
var debug = false

func init(expression: String = '', position_offset = 'left') -> void:
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
	if $TextureRect.texture:
		rect_position -= Vector2(
			$TextureRect.texture.get_width() * 0.5,
			$TextureRect.texture.get_height()
		) * custom_scale


func _ready():
	if debug:
		print('Character data loaded: ', character_data)
		print(rect_position, $TextureRect.rect_size)
		$Tween.connect("tween_all_completed", self, "queue_free")


func set_portrait(expression: String) -> void:
	if expression == '':
		expression = 'Default'
	var portraits = character_data['portraits']
	for p in portraits:
		if p['name'] == expression:
			if ResourceLoader.exists(p['path']):
				$TextureRect.texture = load(p['path'])
			else:
				$TextureRect.texture = Texture.new()


# Tween stuff
func fade_in(node = self, time = 0.5):
	tween_modulate(Color(1,1,1,0), Color(1,1,1,1), time)
	
	var end_pos = Vector2(0, -40) # starting at center
	if direction == 'right':
		end_pos = Vector2(+40, 0)
	elif direction == 'left':
		end_pos = Vector2(-40, 0)
	else:
		node.rect_position += Vector2(0, 40)
	
	var tween_node = node.get_node('Tween')
	tween_node.interpolate_property(
		node, "rect_position", node.rect_position, node.rect_position + end_pos, time,
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT
	)
	tween_node.start()


func fade_out(node = self, time = 0.5):
	tween_modulate(modulate, Color(1,1,1,0), time)
	


func focus():
	tween_modulate(modulate, Color(1,1,1,1))
	var _parent = get_parent()
	if _parent:
		# Make sure that this portrait is the last to be _draw -ed
		_parent.move_child(self, _parent.get_child_count())


func focusout():
	tween_modulate(modulate, Color(0.5,0.5,0.5,1))
	var _parent = get_parent()
	if _parent:
		# Render this portrait first
		_parent.move_child(self, 0)


func tween_modulate(from_value, to_value, time = 0.5):
	var tween_node = $Tween
	tween_node.interpolate_property(
		self, "modulate", from_value, to_value, time,
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT
	)
	tween_node.start()
	return tween_node
