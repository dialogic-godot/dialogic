tool
extends PanelContainer

const MIN_SIZE = Vector2(0,140)
const MAX_SIZE = Vector2(0,512)

var tree_resource:Resource = null setget _set_tree_resource

onready var tree_node:Tree = $Control/Tree

func force_update() -> void:
	tree_node.update_tree()

func show_category() -> void:
	tree_node.visible = true
	rect_min_size = Vector2(rect_min_size.x, MIN_SIZE.y)
	size_flags_vertical = SIZE_EXPAND_FILL


func hide_category() -> void:
	tree_node.visible = false
	rect_min_size = Vector2(rect_min_size.x, 0)
	size_flags_vertical = SIZE_FILL


func _set_tree_resource(_resource:Resource):
	if not _resource:
		print_debug("No resource")
		return
	tree_resource = _resource
	if not _resource.is_connected("changed", tree_node, "_on_base_resource_change"):
		var _err = _resource.connect("changed", tree_node, "_on_base_resource_change")
		if _err != OK:
			print_debug("FATAL ERROR: ", _err)
	tree_node.set_base(_resource)


func _on_FoldButton_pressed() -> void:
	if tree_node.visible:
		hide_category()
	else:
		show_category()
		tree_node.update_tree()
