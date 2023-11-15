class_name DialogicLayoutLayer
extends Node

## Base class that should be extended by custom dialogic layout layers.


## Reference to the layout base that this layer is attached to.
var layout_base : DialogicLayoutBase


## Override this and load all your exported settings (apply them to the scene)
func _apply_export_overrides() -> void:
	pass


## Use this to get potential global settings.
func get_global_setting(setting_name:StringName, default:Variant) -> Variant:
	if layout_base == null:
		return default

	return layout_base._get_global_setting(setting_name, default)
