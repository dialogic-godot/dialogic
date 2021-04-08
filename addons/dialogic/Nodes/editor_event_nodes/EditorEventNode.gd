class_name DialogicEditorEventNode
extends Control

const DialogicUtil = preload("res://addons/dialogic/Core/DialogicUtil.gd")
var base_resource:Resource = null

func _ready() -> void:
	if not base_resource:
		DialogicUtil.Logger.print(self,["There's no resource reference for this event", name])
		queue_free()
		return
	
	if (base_resource as Resource).is_connected("changed", self, "_on_resource_change"):
		base_resource.connect("changed", self, "_on_resource_change")
	

func _on_resource_change() -> void:
	pass
