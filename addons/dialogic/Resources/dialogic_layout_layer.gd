@tool
class_name DialogicLayoutLayer
extends Node

## Base class that should be extended by custom dialogic layout layers.


## This is turned on automatically when the layout is realized [br] [br]
## Turn it off, if you want to modify the settings of the nodes yourself.
@export var apply_overrides_on_ready := false


func _ready() -> void:
	if apply_overrides_on_ready and not Engine.is_editor_hint():
		_apply_export_overrides()


## Override this and load all your exported settings (apply them to the scene)
func _apply_export_overrides() -> void:
	pass


## Use this to get potential global settings.
func get_global_setting(setting_name:StringName, default:Variant) -> Variant:
	return get_parent().get_global_setting(setting_name, default)
