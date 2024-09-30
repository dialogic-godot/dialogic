@tool
class_name DialogicLayoutBase
extends Node

## Base class that should be extended by custom layouts.


## Method that adds a node as a layer
func add_layer(layer:DialogicLayoutLayer) -> Node:
	add_child(layer)
	return layer


## Method that returns the given child
func get_layer(index:int) -> Node:
	return get_child(index)


## Method to return all the layers
func get_layers() -> Array:
	var layers := []
	for child in get_children():
		if child is DialogicLayoutLayer:
			layers.append(child)
	return layers


## Method that is called to load the export overrides.
## This happens when the style is first introduced,
## but also when switching to a different style using the same scene!
func apply_export_overrides() -> void:
	_apply_export_overrides()
	for child in get_children():
		if child.has_method('_apply_export_overrides'):
			child._apply_export_overrides()


## Returns a setting on this base.
## This is useful so that layers can share settings like base_color, etc.
func get_global_setting(setting:StringName, default:Variant) -> Variant:
	if setting in self:
		return get(setting)

	if str(setting).to_lower() in self:
		return get(setting.to_lower())

	if 'global_'+str(setting) in self:
		return get('global_'+str(setting))

	return default


## To be overwritten. Apply the settings to your scene here.
func _apply_export_overrides() -> void:
	pass


#region HANDLE PERSISTENT DATA
################################################################################

func _enter_tree() -> void:
	_load_persistent_info(Engine.get_meta("dialogic_persistent_style_info", {}))


func _exit_tree() -> void:
	Engine.set_meta("dialogic_persistent_style_info", _get_persistent_info())


## To be overwritten. Return any info that a later used style might want to know.
func _get_persistent_info() -> Dictionary:
	return {}


## To be overwritten. Apply any info that a previous style might have stored and this style should use.
func _load_persistent_info(info: Dictionary) -> void:
	pass

#endregion
