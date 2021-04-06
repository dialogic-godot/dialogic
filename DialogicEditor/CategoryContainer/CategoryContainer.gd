tool
extends PanelContainer

const MIN_SIZE = Vector2(0,140)
const MAX_SIZE = Vector2(0,512)

onready var tree_node = $Control/Tree

func _ready() -> void:
	pass

func show_category() -> void:
	tree_node.visible = true
	rect_min_size = Vector2(rect_min_size.x, MIN_SIZE.y)
	size_flags_vertical = SIZE_EXPAND_FILL


func hide_category() -> void:
	tree_node.visible = false
	rect_min_size = Vector2(rect_min_size.x, 0)
	size_flags_vertical = SIZE_FILL


func _on_FoldButton_pressed() -> void:
	if tree_node.visible:
		hide_category()
	else:
		show_category()
