@tool
class_name DialogicVisualEditorField
extends Control

signal value_changed(property_name:String, value:Variant)
var property_name := ""

var event_resource: DialogicEvent = null

#region OVERWRITES
################################################################################

## To be overwritten
func _load_display_info(info:Dictionary) -> void:
	pass


## To be overwritten
func _set_value(value:Variant) -> void:
	pass


## To be overwritten
func _autofocus() -> void:
	pass

#endregion


func set_value(value:Variant) -> void:
	_set_value(value)


func take_autofocus() -> void:
	_autofocus()
