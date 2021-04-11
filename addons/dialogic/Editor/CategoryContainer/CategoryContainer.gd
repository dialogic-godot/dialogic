tool
extends PanelContainer
# Takes care abour displaying itself and managing the tree,
# but no tree items. Refer to the tree for that

signal tree_item_selected(tree_item)

var DialogicUtil = load("res://addons/dialogic/Core/DialogicUtil.gd")

const MAX_SIZE = Vector2(0,512)

var tree_resource:Resource = null setget _set_tree_resource
var min_size = Vector2(0, 50)

onready var tree_node = get_node("Control/Tree")
onready var popup_menu_node:PopupMenu = $PopupMenu
onready var confirmation_node:ConfirmationDialog = $ConfirmationDialog

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT:
		emit_signal("tree_item_selected", tree_node.get_root())
		show_category()
		pass

func force_update() -> void:
	tree_node.update_tree()

func show_category() -> void:
	tree_node.visible = true
	min_size = Vector2(0,50)
	var _tree_child = tree_node.get_root().get_children()
	if _tree_child:
		min_size.y = _explore_tree_recursively(_tree_child, 50)
	rect_min_size = Vector2(rect_min_size.x, min_size.y)
#	rect_min_size = Vector2(rect_min_size.x, MIN_SIZE.y)
#	size_flags_vertical = SIZE_EXPAND_FILL


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


func _explore_tree_recursively(from:TreeItem, with_val:int):
	var _val = with_val
	DialogicUtil.Logger.print(self,"Recursion with val: {v}".format({"v":_val}))
	if from.get_children():
		_val = _explore_tree_recursively(from.get_children(), _val*2)
	elif from.get_next():
		_val = _explore_tree_recursively(from.get_next(), _val+45)

	return _val


func _on_FoldButton_pressed() -> void:
	if tree_node.visible:
		hide_category()
	else:
		show_category()
		tree_node.update_tree()

# Note: I hate this implementation, but its the less
# breaking and scalable implementation

func _on_Tree_item_rmb_selected(position: Vector2) -> void:
	var _item:TreeItem = tree_node.get_selected()
	var mouse_pos = get_global_mouse_position()
	var rect = Rect2(mouse_pos, Vector2(60, 60))
	popup_menu_node.popup(rect)


func _on_PopupMenu_id_pressed(id: int) -> void:
	match id:
		0:
			tree_node.rename_item(tree_node.get_selected())
		2:
			confirmation_node.popup_centered_minsize()


func _on_ConfirmationDialog_confirmed() -> void:
	var _selected:TreeItem = tree_node.get_selected()
	var _meta = _selected.get_metadata(0)
	(tree_resource as DialogicDatabaseResource).remove(_meta)
	tree_node.remove_item(tree_node.get_selected())
	emit_signal("tree_item_selected", tree_node.get_root())


func _on_Tree_item_selected() -> void:
	emit_signal("tree_item_selected", tree_node.get_selected())


func _on_Tree_focus_exited() -> void:
	var _selected = tree_node.get_selected()
	if _selected:
		_selected.deselect(0)
