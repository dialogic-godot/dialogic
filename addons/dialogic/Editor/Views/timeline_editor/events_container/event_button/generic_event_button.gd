tool
extends Button

# must be a DialogicEventResource
export (Resource) var event_resource:Resource

onready var tween_node = $Tween

func _pressed() -> void:
	emit_signal("pressed", event_resource.get_script().new())


func expand() -> void:
	var _font = get_font("font")
	var _offset = rect_size + Vector2(10,0)
	var _text_size = _font.get_string_size(text) + _offset
	_text_size = Vector2(_text_size.x, 0)
	tween_node.interpolate_property(
		self, 
		"rect_size", 
		null, _text_size,
		0.1, Tween.TRANS_BOUNCE, Tween.EASE_IN)
	tween_node.start()


func contract() -> void:
	tween_node.interpolate_property(
		self, 
		"rect_min_size", 
		rect_size, Vector2.ZERO,
		0.2, Tween.TRANS_LINEAR, Tween.EASE_OUT, 0.2)
	tween_node.start()


func _on_mouse_entered() -> void:
	expand()


func _on_mouse_exited() -> void:
	contract()


func _on_Tween_completed(object: Object, key: NodePath) -> void:
	rect_min_size = rect_size
