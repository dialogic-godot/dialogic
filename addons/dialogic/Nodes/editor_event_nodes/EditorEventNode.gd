tool
class_name DialogicEditorEventNode
extends Control

const DialogicUtil = preload("res://addons/dialogic/Core/DialogicUtil.gd")
var base_resource:Resource = null

export(NodePath) var IconNode_path:NodePath
export(NodePath) var TopContent_path:NodePath
export(NodePath) var CenterContent_path:NodePath
export(NodePath) var BottomContent_path:NodePath

onready var top_content_node:PanelContainer = get_node_or_null(TopContent_path)
onready var center_content_node:PanelContainer = get_node_or_null(CenterContent_path)
onready var bottom_content_node:PanelContainer = get_node_or_null(BottomContent_path)
onready var icon_node:TextureRect = get_node_or_null(IconNode_path)

func _ready() -> void:
	if Engine.editor_hint:
		return
	
	if not base_resource:
		DialogicUtil.Logger.print(self,["There's no resource reference for this event", name])
		queue_free()
		return
	
	if (base_resource as Resource).is_connected("changed", self, "_on_resource_change"):
		base_resource.connect("changed", self, "_on_resource_change")
	

func _on_resource_change() -> void:
	pass


func _on_FoldButton_pressed() -> void:
	center_content_node.visible = !center_content_node.visible
	bottom_content_node.visible = !bottom_content_node.visible
