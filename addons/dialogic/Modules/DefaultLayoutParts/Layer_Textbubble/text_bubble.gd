extends Control

@onready var tail: Line2D = ($Group/Tail as Line2D)
@onready var bubble: Control = ($Group/Background as Control)
@onready var text: DialogicNode_DialogText = (%DialogText as DialogicNode_DialogText)
# The choice container is added by the TextBubble layer
@onready var choice_container: Container = null
@onready var name_label: Label = (%NameLabel as Label)
@onready var name_label_box: PanelContainer = (%NameLabelPanel as PanelContainer)
@onready var name_label_holder: HBoxContainer = $DialogText/NameLabelPositioner

var node_to_point_at: Node = null
var current_character: DialogicCharacter = null

var max_width := 300

var bubble_rect: Rect2 = Rect2(0.0, 0.0, 2.0, 2.0)
var base_position := Vector2.ZERO

var base_direction := Vector2(1.0, -1.0).normalized()
var safe_zone := 50.0
var padding := Vector2()

var name_label_alignment := HBoxContainer.ALIGNMENT_BEGIN
var name_label_offset := Vector2()
var force_choices_on_separate_lines := false

# Sets the padding shader paramter.
# It's the amount of spacing around the background to allow some wobbeling.
var bg_padding := 30


func _ready() -> void:
	reset()
	DialogicUtil.autoload().Choices.choices_shown.connect(_on_choices_shown)


func reset() -> void:
	scale = Vector2.ZERO
	modulate.a = 0.0

	tail.points = []
	bubble_rect = Rect2(0,0,2,2)

	base_position = get_speaker_canvas_position()
	position = base_position


func _process(delta:float) -> void:
	base_position = get_speaker_canvas_position()

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

	var p: Vector2 = base_position + direction * (
		safe_zone + lerp(bubble_rect.size.y, bubble_rect.size.x, abs(direction.x)) * 0.4
		)
	p = p.clamp(bubble_rect.size / 2.0, get_viewport_rect().size - bubble_rect.size / 2.0)

	position = position.lerp(p, 5 * delta)

	var point_a: Vector2 = Vector2.ZERO
	var point_b: Vector2 = (base_position - position) * 0.75

	var offset: Vector2 = Vector2.from_angle(point_a.angle_to_point(point_b)) * bubble_rect.size * abs(direction.x) * 0.4

	point_a += offset
	point_b += offset * 0.5

	var curve := Curve2D.new()
	var direction_point := Vector2(0, (point_b.y - point_a.y))
	curve.add_point(point_a, Vector2.ZERO, direction_point * 0.5)
	curve.add_point(point_b)
	tail.points = curve.tessellate(5)
	tail.width = bubble_rect.size.x * 0.15


func open() -> void:
	set_process(true)
	show()
	text.enabled = true
	var open_tween := create_tween().set_parallel(true)
	open_tween.tween_property(self, "scale", Vector2.ONE, 0.1).from(Vector2.ZERO)
	open_tween.tween_property(self, "modulate:a", 1.0, 0.1).from(0.0)


func close() -> void:
	text.enabled = false
	var close_tween := create_tween().set_parallel(true)
	close_tween.tween_property(self, "scale", Vector2.ONE * 0.8, 0.2)
	close_tween.tween_property(self, "modulate:a", 0.0, 0.2)
	await close_tween.finished
	hide()
	set_process(false)


func _on_dialog_text_started_revealing_text():
	_resize_bubble(get_base_content_size(), true)


func _resize_bubble(content_size:Vector2, popup:=false) -> void:
	var bubble_size: Vector2 = content_size+(padding*2)+Vector2.ONE*bg_padding
	var half_size: Vector2= (bubble_size / 2.0)
	bubble.pivot_offset = half_size
	bubble_rect = Rect2(position, bubble_size * Vector2(1.1, 1.1))
	bubble.position = -half_size
	bubble.size = bubble_size

	text.size = content_size
	text.position = -(content_size/2.0)

	if popup:
		var t := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		t.tween_property(bubble, "scale", Vector2.ONE, 0.2).from(Vector2.ZERO)
	else:
		bubble.scale = Vector2.ONE

	bubble.material.set(&"shader_parameter/box_size", bubble_size)
	name_label_holder.position = Vector2(0, bubble.position.y - text.position.y - name_label_holder.size.y/2.0)
	name_label_holder.position += name_label_offset
	name_label_holder.alignment = name_label_alignment
	name_label_holder.size.x = text.size.x


func _on_choices_shown(info:Dictionary) -> void:
	if !is_visible_in_tree():
		return

	await get_tree().process_frame

	var content_size := get_base_content_size()
	content_size.y += choice_container.size.y
	content_size.x = max(content_size.x, choice_container.size.x)
	_resize_bubble(content_size)


func get_base_content_size() -> Vector2:
	var font: Font = text.get_theme_font(&"normal_font")
	return font.get_multiline_string_size(
		text.get_parsed_text(),
		HORIZONTAL_ALIGNMENT_LEFT,
		max_width,
		text.get_theme_font_size(&"normal_font_size")
		)


func add_choice_container(node:Container, alignment:=FlowContainer.ALIGNMENT_BEGIN) -> void:
	if choice_container:
		choice_container.get_parent().remove_child(choice_container)
		choice_container.queue_free()

	node.name = "ChoiceContainer"
	choice_container = node
	node.set_anchors_preset(LayoutPreset.PRESET_BOTTOM_WIDE)
	node.grow_vertical = Control.GROW_DIRECTION_BEGIN
	text.add_child(node)

	if node is HFlowContainer:
		(node as HFlowContainer).alignment = alignment

	for i:int in range(5):
		choice_container.add_child(DialogicNode_ChoiceButton.new())
		if node is HFlowContainer:
			continue
		match alignment:
			HBoxContainer.ALIGNMENT_BEGIN:
				(choice_container.get_child(-1) as Control).size_flags_horizontal = SIZE_SHRINK_BEGIN
			HBoxContainer.ALIGNMENT_CENTER:
				(choice_container.get_child(-1) as Control).size_flags_horizontal = SIZE_SHRINK_CENTER
			HBoxContainer.ALIGNMENT_END:
				(choice_container.get_child(-1) as Control).size_flags_horizontal = SIZE_SHRINK_END

	for child:Button in choice_container.get_children():
		var prev := child.get_parent().get_child(wrap(child.get_index()-1, 0, choice_container.get_child_count()-1)).get_path()
		var next := child.get_parent().get_child(wrap(child.get_index()+1, 0, choice_container.get_child_count()-1)).get_path()
		child.focus_next = next
		child.focus_previous = prev
		child.focus_neighbor_left = prev
		child.focus_neighbor_top = prev
		child.focus_neighbor_right = next
		child.focus_neighbor_bottom = next


func get_speaker_canvas_position() -> Vector2:
	if node_to_point_at:
		if node_to_point_at is Node3D:
			base_position = get_viewport().get_camera_3d().unproject_position(
				(node_to_point_at as Node3D).global_position)
		if node_to_point_at is CanvasItem:
			base_position = (node_to_point_at as CanvasItem).get_global_transform_with_canvas().origin
	return base_position
