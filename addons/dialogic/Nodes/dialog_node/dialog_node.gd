tool
class_name DialogicDialogNode
extends Control

export(NodePath) var TextNode_path:NodePath
export(NodePath) var NameNode_path:NodePath
export(NodePath) var NextIndicator_path:NodePath
export(float) var text_speed:float = 0.02

var event_finished = false

onready var TextNode:RichTextLabel = (get_node(TextNode_path) as RichTextLabel)
onready var NameNode:Label = (get_node(NameNode_path) as Label)
onready var NextIndicatorNode := get_node(NextIndicator_path)

func _process(delta: float) -> void:
	NextIndicatorNode.visible = event_finished
