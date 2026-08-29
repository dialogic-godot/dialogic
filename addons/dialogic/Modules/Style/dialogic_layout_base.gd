@tool
@icon("layout_layer_icon.svg")
class_name DialogicLayoutBase
extends Node

## Base class that should be extended by custom layouts.


## Emitted after dialogic has applied export overrides
signal overrides_applied

func _init() -> void:

	## This is to attempt upgrading old style scenes to the new system.
	if not has_meta("export_overrides"):
		update_export_overrides()

	overrides_applied.connect(_on_overrides_applied)

	_load_persistent_info(Engine.get_meta("dialogic_persistent_style_info", {}))


## Method that adds a node as a layer
func add_layer(layer:DialogicLayoutLayer) -> Node:
	add_child(layer)
	return layer


## Method to return all the layers
func get_layers() -> Array[DialogicLayoutLayer]:
	var layers: Array[DialogicLayoutLayer] = []
	for child in get_children():
		if child is DialogicLayoutLayer:
			layers.append(child)
	return layers


func get_layer_id_list() -> PackedStringArray:
	return PackedStringArray(get_layers().map(func(x) -> String: return x.get_meta("style_layer_id", x.name)))


func get_layer_by_id(id:String) -> DialogicLayoutLayer:
	for child in get_children():
		if child is DialogicLayoutLayer and child.get_meta("style_layer_id", child.name) == id:
			return child
	return null


func _on_overrides_applied() -> void:
	if not is_node_ready():
		await ready

	for layer in get_layers():
		if layer.disabled:
			layer.process_mode = Node.PROCESS_MODE_DISABLED
		else:
			layer.process_mode = Node.PROCESS_MODE_INHERIT


## @deprecated
## TODO: Remove when dropping support for pre alpha 21 Styles
## Method that is called to load the export overrides.
## This happens when the style is first introduced,
## but also when switching to a different style using the same scene!
func apply_export_overrides() -> void:
	_apply_export_overrides()
	for child in get_children():
		if child.has_method("_apply_export_overrides"):
			child._apply_export_overrides()


## @deprecated
## TODO: Remove when dropping support for pre alpha 21 Styles
## Returns a setting on this base.
## This is useful so that layers can share settings like base_color, etc.
func get_global_setting(setting:StringName, default:Variant) -> Variant:
	if setting in self:
		return get(setting)

	if str(setting).to_lower() in self:
		return get(setting.to_lower())

	if "global_"+str(setting) in self:
		return get("global_"+str(setting))

	return default

## @deprecated
## TODO: Remove when dropping support for pre alpha 21 Styles
## To be overwritten. Apply the settings to your scene here.
func _apply_export_overrides() -> void:
	pass


#region HANDLE PERSISTENT DATA
################################################################################



func _exit_tree() -> void:
	var info: Dictionary = Engine.get_meta("dialogic_persistent_style_info", {})
	info.merge(_get_persistent_info(), true)
	Engine.set_meta("dialogic_persistent_style_info", info)


## To be overwritten. Return any info that a later used style might want to know.
func _get_persistent_info() -> Dictionary:
	return {}


## To be overwritten. Apply any info that a previous style might have stored and this style should use.
func _load_persistent_info(_info: Dictionary) -> void:
	pass

#endregion

## @deprecated
## TODO: Remove when dropping support for pre alpha 21 Styles
func update_export_overrides() -> Array[Dictionary]:
	var properties: Array[Dictionary] = self.script.get_script_property_list()
	var settings: Array[Dictionary] = []

	var current_group := {}
	var current_subgroup := {}

	for i in properties:
		if i["usage"] & PROPERTY_USAGE_CATEGORY == PROPERTY_USAGE_CATEGORY:
			continue

		if i["usage"] & PROPERTY_USAGE_GROUP == PROPERTY_USAGE_GROUP:
			settings.append({"type":"Category", "name":i.get("name", "General")})
			current_group = i
			current_subgroup = {}

		elif i["usage"] & PROPERTY_USAGE_SUBGROUP == PROPERTY_USAGE_SUBGROUP:
			settings.append({"type":"Node", "name":".", "display_name":i.get("name", "")},)
			current_subgroup = i

		elif i["usage"] & PROPERTY_USAGE_EDITOR == PROPERTY_USAGE_EDITOR:
			if current_group.get("name", "") == "Private":
				continue

			if current_group.is_empty():
				settings.append({"type":"Category", "name":"General"})
				current_group = {"name":"General"}

			if current_subgroup.is_empty():
				settings.append({"type":"Node", "name":".", "display_name":"General"})
				current_subgroup = {"name":"General"}

			settings.append({"type":"Property", "name":i.get("name", "")},
		)
	set_meta("export_overrides", settings)
	print("Updated layer scene ", get_script().resource_path)

	return settings
