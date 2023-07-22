extends Control

@onready var tail : Line2D = $Tail
@onready var bubble : Control = $Background
var speaker_node : Node = null
var character : DialogicCharacter = null
var max_width := 300

var bubble_rect : Rect2 = Rect2(0.0, 0.0, 2.0, 2.0)
var base_position := Vector2.ZERO

var base_direction := Vector2(1.0, -1.0).normalized()
var safe_zone := 50.0
var padding := Vector2()

func _ready() -> void:
	scale = Vector2.ZERO
	modulate.a = 0.0
	if speaker_node: 
		position = speaker_node.get_global_transform_with_canvas().origin


func _process(delta):
	if speaker_node: 
		base_position = speaker_node.get_global_transform_with_canvas().origin
	
	var center := get_viewport_rect().size / 2.0
	
	var dist_x := abs(base_position.x - center.x)
	var dist_y := abs(base_position.y - center.y)
	var x_e := center.x - bubble_rect.size.x
	var y_e := center.y - bubble_rect.size.y
	var influence_x := remap(clamp(dist_x, x_e, center.x), x_e, center.x * 0.8, 0.0, 1.0)
	var influence_y := remap(clamp(dist_y, y_e, center.y), y_e, center.y * 0.8, 0.0, 1.0)
	if base_position.x > center.x: influence_x = -influence_x
	if base_position.y > center.y: influence_y = -influence_y
	var edge_influence := Vector2(influence_x, influence_y)
	
	var direction := (base_direction + edge_influence).normalized()
	
	var p : Vector2 = base_position + direction * (safe_zone + lerp(bubble_rect.size.y, bubble_rect.size.x, abs(direction.x)) * 0.4)
	p = p.clamp(bubble_rect.size / 2.0, get_viewport_rect().size - bubble_rect.size / 2.0)
	
	position = lerp(position, p, 10.0 * delta)
	
	var point_a : Vector2 = Vector2.ZERO
	var point_b : Vector2 = (base_position - position) * 0.5
	
	var offset = Vector2.from_angle(point_a.angle_to_point(point_b)) * bubble_rect.size * abs(direction.x) * 0.4
	
	point_a += offset
	point_b += offset * 0.5
	
	var curve := Curve2D.new()
	var direction_point := Vector2(0, (point_b.y - point_a.y))
	curve.add_point(point_a, Vector2.ZERO, direction_point * 0.5)
	curve.add_point(point_b)
	tail.points = curve.tessellate(5)
	tail.width = bubble_rect.size.x * 0.15


func open() -> void:
	show()
	%DialogText.enabled = true
	var open_tween := create_tween().set_parallel(true)
	open_tween.tween_property(self, "scale", Vector2.ONE, 0.1).from(Vector2.ZERO)
	open_tween.tween_property(self, "modulate:a", 1.0, 0.1).from(0.0)
	


func close() -> void:
	%DialogText.enabled = false
	var close_tween := create_tween().set_parallel(true)
	close_tween.tween_property(self, "scale", Vector2.ONE * 0.8, 0.1)
	close_tween.tween_property(self, "modulate:a", 0.0, 0.1)
	await close_tween.finished
	hide()


func _on_dialog_text_started_revealing_text():
	var font :Font = %DialogText.get_theme_font("normal_font")
	%DialogText.size = font.get_multiline_string_size(%DialogText.get_parsed_text(), HORIZONTAL_ALIGNMENT_LEFT, max_width, %DialogText.get_theme_font_size("normal_font_size"))
	if Dialogic.Choices.is_question(Dialogic.current_event_idx):
		font = $DialogText/ChoiceContainer/DialogicNode_ChoiceButton.get_theme_font('font')
		%DialogText.size.y += font.get_string_size(%DialogText.get_parsed_text(), HORIZONTAL_ALIGNMENT_LEFT, max_width, $DialogText/ChoiceContainer/DialogicNode_ChoiceButton.get_theme_font_size("font_size")).y
	%DialogText.position = -%DialogText.size/2
	
	_resize_bubble()


func _resize_bubble() -> void:
	var bubble_size :Vector2 = %DialogText.size+(padding*2)
	var half_size :Vector2= (bubble_size / 2.0)
	%DialogText.pivot_offset = half_size
	bubble.pivot_offset = half_size
	bubble_rect = Rect2(position, bubble_size * Vector2(1.1, 1.1))
	bubble.size = bubble_size
	bubble.position = -half_size
	
	var t := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	t.tween_property(bubble, "scale", Vector2.ONE, 0.2).from(Vector2.ZERO)
	
	# set bubble's ratio
	var bubble_ratio := Vector2.ONE
	if bubble_rect.size.x < bubble_rect.size.y:
		bubble_ratio.y = bubble_rect.size.y / bubble_rect.size.x
	else:
		bubble_ratio.x = bubble_rect.size.x / bubble_rect.size.y
	
	bubble.material.set("shader_parameter/ratio", bubble_ratio)

