tool
extends CenterContainer

onready var texture_rect = $TextureRect

var previw_size = 200

func set_image(image: Texture):
	texture_rect.texture = image
	if image != null:
		texture_rect.rect_size = Vector2(previw_size, previw_size)
		texture_rect.rect_min_size = Vector2(previw_size, previw_size)
	else:
		texture_rect.rect_size = Vector2(0, 0)
		texture_rect.rect_min_size = Vector2(0, 0)
