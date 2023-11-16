@tool
class_name DialogicLayoutBase
extends Node

## Base class that should be extended by custom layouts.


func add_layer(layer:DialogicLayoutLayer) -> Node:
	add_child(layer)
	return layer


func get_layer(index:int) -> Node:
	return get_child(index)


func get_layers() -> Array:
	var layers := []
	for child in get_children():
		if child is DialogicLayoutLayer:
			layers.append(child)
	return layers


func appply_export_overrides() -> void:
	_apply_export_overrides()
	for child in get_children():
		if child.has_method('_apply_export_overrides'):
			child._apply_export_overrides()


func _apply_export_overrides() -> void:
	pass


func get_global_setting(setting:StringName, default:Variant) -> Variant:
	if setting in self:
		return get(setting)

	if str(setting).to_lower() in self:
		return get(setting.to_lower())

	if 'global_'+str(setting) in self:
		return get('global_'+str(setting))

	return default
