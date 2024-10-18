@tool
extends Resource
class_name DialogicStyle

## A style represents a collection of layers and settings.
## A style can inherit from another style.


@export var name := "Style":
	get:
		if name.is_empty():
			return "Unkown Style"
		return name

@export var inherits: DialogicStyle = null

## Stores the layer order
@export var layer_list: Array[String] = []
## Stores the layer infos
@export var layer_info := {
	"" : DialogicStyleLayer.new()
}




func _init(_name := "") -> void:
	if not _name.is_empty():
		name = _name



#region BASE METHODS
# These methods are local, meaning they do NOT take inheritance into account.


## Returns the amount of layers (the base layer is not included).
func get_layer_count() -> int:
	return layer_list.size()


## Returns the index of the layer with [param id] in the layer list.
## Returns -1 for the base layer (id=="") which is not in the layer list.
func get_layer_index(id:String) -> int:
	return layer_list.find(id)


## Returns `true` if [param id] is a valid id for a layer.
func has_layer(id:String) -> bool:
	return id in layer_info or id == ""


## Returns `true` if [param index] is a valid index for a layer.
func has_layer_index(index:int) -> bool:
	return index < layer_list.size()


## Returns the id of the layer at [param index].
func get_layer_id_at_index(index:int) -> String:
	if index == -1:
		return ""
	if has_layer_index(index):
		return layer_list[index]
	return ""


func get_layer_info(id:String) -> Dictionary:
	var info := {"id": id, "path": "", "overrides": {}}

	if has_layer(id):
		var layer_resource: DialogicStyleLayer = layer_info[id]

		if layer_resource.scene != null:
			info.path = layer_resource.scene.resource_path
		elif id == "":
			info.path = DialogicUtil.get_default_layout_base().resource_path

		info.overrides = layer_resource.overrides.duplicate()

	return info

#endregion


#region MODIFICATION METHODS
# These methods modify the layers of this style.


## Returns a new layer id not yet in use.
func get_new_layer_id() -> String:
	var i := 16
	while String.num_int64(i, 16) in layer_info:
		i += 1
	return String.num_int64(i, 16)


## Adds a layer with the given scene and overrides.
## Returns the new layers id.
func add_layer(scene:String, overrides:Dictionary = {}, id:= "##") -> String:
	if id == "##":
		id = get_new_layer_id()
	layer_info[id] = DialogicStyleLayer.new(scene, overrides)
	layer_list.append(id)
	changed.emit()
	return id


## Deletes the layer with the given id.
## Deleting the base layer is not allowed.
func delete_layer(id:String) -> void:
	if not has_layer(id) or id == "":
		return

	layer_info.erase(id)
	layer_list.erase(id)

	changed.emit()


## Moves the layer at [param from_index] to [param to_index].
func move_layer(from_index:int, to_index:int) -> void:
	if not has_layer_index(from_index) or not has_layer_index(to_index-1):
		return

	var id := layer_list.pop_at(from_index)
	layer_list.insert(to_index, id)

	changed.emit()


## Changes the scene property of the DialogicStyleLayer resource at [param layer_id].
func set_layer_scene(layer_id:String, scene:String) -> void:
	if not has_layer(layer_id):
		return

	layer_info[layer_id].scene = load(scene)
	changed.emit()


func set_layer_overrides(layer_id:String, overrides:Dictionary) -> void:
	if not has_layer(layer_id):
		return

	layer_info[layer_id].overrides = overrides
	changed.emit()


## Changes an override of the DialogicStyleLayer resource at [param layer_id].
func set_layer_setting(layer_id:String, setting:String, value:Variant) -> void:
	if not has_layer(layer_id):
		return

	layer_info[layer_id].overrides[setting] = value
	changed.emit()


## Resets (removes) an override of the DialogicStyleLayer resource at [param layer_id].
func remove_layer_setting(layer_id:String, setting:String) -> void:
	if not has_layer(layer_id):
		return

	layer_info[layer_id].overrides.erase(setting)
	changed.emit()

#
#endregion


#region INHERITANCE METHODS
# These methods are what you should usually use to get info about this style.


## Returns `true` if this style is inheriting from another style.
func inherits_anything() -> bool:
	return inherits != null


## Returns the base style of this style.
func get_inheritance_root() -> DialogicStyle:
	if not inherits_anything():
		return self

	var style: DialogicStyle = self
	while style.inherits_anything():
		style = style.inherits

	return style


## This merges some [param layer_info] with it's param ancestors layer info.
func merge_layer_infos(layer_info:Dictionary, ancestor_info:Dictionary) -> Dictionary:
	var combined := layer_info.duplicate(true)

	combined.path = ancestor_info.path
	combined.overrides.merge(ancestor_info.overrides)

	return combined


## Returns the layer info of the layer at [param id] taking into account inherited info.
## If [param inherited_only] is `true`, the local info is not included.
func get_layer_inherited_info(id:String, inherited_only := false) -> Dictionary:
	var style := self
	var info := {"id": id, "path": "", "overrides": {}}

	if not inherited_only:
		info = get_layer_info(id)

	while style.inherits_anything():
		style = style.inherits
		info = merge_layer_infos(info, style.get_layer_info(id))

	return info


## Returns the layer list of the root style.
func get_layer_inherited_list() -> Array:
	var list := layer_list

	if inherits_anything():
		list = get_inheritance_root().layer_list

	return list


## Applies inherited info to the local layers.
## Then removes inheritance.
func realize_inheritance() -> void:
	layer_list = get_layer_inherited_list()

	var new_layer_info := {}
	for id in layer_info:
		var info := get_layer_inherited_info(id)
		new_layer_info[id] = DialogicStyleLayer.new(info.get("path", ""), info.get("overrides", {}))

	layer_info = new_layer_info
	inherits = null
	changed.emit()


#endregion

## Creates a fresh new style with the same settings.
func clone() -> DialogicStyle:
	var style := DialogicStyle.new()
	style.name = name
	style.inherits = inherits

	var base_info := get_layer_info("")
	set_layer_scene("", base_info.path)
	set_layer_overrides("", base_info.overrides)

	for id in layer_list:
		var info := get_layer_info(id)
		style.add_layer(info.path, info.overrides, id)

	return style


## Starts preloading all the scenes used by this style.
func prepare() -> void:
	for id in layer_info:
		if layer_info[id].scene:
			ResourceLoader.load_threaded_request(layer_info[id].scene.resource_path)


#region UPDATE OLD STYLES
# TODO deprecated when going into beta

# TODO  Deprecated, only for Styles before alpha 16!
@export var base_scene: PackedScene = null
# TODO Deprecated, only for Styles before alpha 16!
@export var base_overrides := {}
# TODO Deprecated, only for Styles before alpha 16!
@export var layers: Array[DialogicStyleLayer] = []

func update_from_pre_alpha16() -> void:
	if not layers.is_empty():
		var idx := 0
		for layer in layers:
			var id := "##"
			if inherits_anything():
				id = get_layer_inherited_list()[idx]
			if layer.scene:
				add_layer(layer.scene.resource_path, layer.overrides, id)
			else:
				add_layer("", layer.overrides, id)
			idx += 1
		layers.clear()

	if not base_scene == null:
		set_layer_scene("", base_scene.resource_path)
		base_scene = null
	if not base_overrides.is_empty():
		set_layer_overrides("", base_overrides)
		base_overrides.clear()


#endregion
