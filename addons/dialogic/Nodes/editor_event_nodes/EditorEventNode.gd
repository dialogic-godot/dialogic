tool
class_name DialogicEditorEventNode
extends Control

signal delelete_item_requested(item)
signal save_item_requested(item)

var DialogicUtil = load("res://addons/dialogic/Core/DialogicUtil.gd")
var base_resource:Resource = null
var idx:int = 0 setget _set_idx

export(NodePath) var IconNode_path:NodePath
export(NodePath) var TopContent_path:NodePath
export(NodePath) var CenterContent_path:NodePath
export(NodePath) var BottomContent_path:NodePath
export(NodePath) var IndexLbl_path:NodePath
export(NodePath) var MenuBtn_path:NodePath

onready var top_content_node:PanelContainer = get_node_or_null(TopContent_path)
onready var center_content_node:PanelContainer = get_node_or_null(CenterContent_path)
onready var bottom_content_node:PanelContainer = get_node_or_null(BottomContent_path)
onready var icon_node:TextureRect = get_node_or_null(IconNode_path)
onready var index_label_node = get_node_or_null(IndexLbl_path)
onready var menu_button_node:MenuButton = get_node(MenuBtn_path)

func _ready() -> void:
	
	if not base_resource:
		DialogicUtil.Logger.print(self,["There's no resource reference for this event", name])
		return
	
	if (base_resource as Resource).is_connected("changed", self, "_on_resource_change"):
		base_resource.connect("changed", self, "_on_resource_change")
	
	var menu_button_popup_node:PopupMenu = menu_button_node.get_popup()
	var _err = menu_button_popup_node.connect("id_pressed", self, "_on_MenuButtonPopup_id_pressed")
	assert(_err == OK)

func _set_idx(value):
	if index_label_node:
		idx = value
		index_label_node.text = str(value)


func _update_node_values() -> void:
	# If you can see this, you didn't override this method
	assert(false)

func _save_resource() -> void:
	emit_signal("save_item_requested", base_resource)


func _on_resource_change() -> void:
	_update_node_values()


func _on_MenuButtonPopup_id_pressed(id:int) -> void:
	if id == 0:
		emit_signal("delelete_item_requested", base_resource)


func _on_FoldButton_pressed() -> void:
	center_content_node.visible = !center_content_node.visible
	bottom_content_node.visible = !bottom_content_node.visible
