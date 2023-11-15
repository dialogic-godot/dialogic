@tool
class_name DialogicLayoutBase
extends Node

## Base class that should be extended by custom layouts.


func _add_layer(layer:DialogicLayoutLayer) -> Node:
	add_child(layer)
	return layer


func _get_layer(layer_name:String) -> Node:
	return get_node(layer_name)


func _apply_export_overrides() -> void:
	for child in get_children():
		if child.has_method('_apply_export_overrides'):
			child._apply_export_overrides()


func _get_global_setting(setting:StringName, default:Variant) -> Variant:
	if setting in self:
		return get(setting)

	if str(setting).to_lower() in self:
		return get(setting.to_lower())

	if 'global_'+str(setting) in self:
		return get('global_'+str(setting))

	return default
