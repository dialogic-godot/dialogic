@tool
extends Node2D

# If the custom portrait accepts a change, then accept it here
func _update_portrait(passed_character:DialogicCharacter, passed_portrait:String) -> void:
	if passed_portrait == "":
		passed_portrait = passed_character['default_portrait']
	
	if $Sprite.frames.has_animation(passed_portrait):
		$Sprite.play(passed_portrait)

func _on_animated_sprite_2d_animation_finished():
	$Sprite.frame = randi()%$Sprite.frames.get_frame_count($Sprite.animation)
	$Sprite.play()

func _get_covered_rect() -> Rect2:
	return Rect2($Sprite.position, $Sprite.frames.get_frame($Sprite.animation, 0).get_size()*$Sprite.scale)
