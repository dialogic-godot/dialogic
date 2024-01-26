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

@export var base_scene: PackedScene = null
@export var base_overrides := {}

@export var layers: Array[DialogicStyleLayer] = []



func _init(_name:="") -> void:
	if not _name.is_empty():
		name = _name


## This always returns the inheritance root's scene!
func get_base_scene() -> PackedScene:
	if base_scene == null:
		return DialogicUtil.get_default_layout_base()

	return get_inheritance_root().base_scene


## This always returns the full inherited roots layers!
func get_layer_list() -> PackedStringArray:
	return PackedStringArray(get_inheritance_root().layers.map(func(x:DialogicStyleLayer): return x.scene.resource_path))


func get_layer_count() -> int:
	return layers.size()


func get_layer_info(index:int) -> Dictionary:
	if index == -1:
		return {'path':get_base_scene().resource_path, 'overrides':base_overrides.duplicate()}

	if index < layers.size():
		if layers[index].scene != null:
			return {'path':layers[index].scene.resource_path, 'overrides':layers[index].overrides.duplicate()}
		else:
			return {'path':'', 'overrides':layers[index].overrides.duplicate()}

	return {'path':'', 'overrides':{}}


func get_layer_inherited_info(index:int, inherited_only:=false) -> Dictionary:
	var style := self
	var info := {'path':'', 'overrides':{}}
	if not inherited_only:
		info = get_layer_info(index)

	while style.inherits != null:
		style = style.inherits
		info = merge_layer_infos(info, style.get_layer_info(index))

	return info


func add_layer(scene:String, overrides:Dictionary = {}) -> void:
	layers.append(DialogicStyleLayer.new(scene, overrides))
	changed.emit()


func delete_layer(layer_index:int) -> void:
	if not has_layer(layer_index):
		return

	layers.remove_at(layer_index)
	changed.emit()


func move_layer(from_index:int, to_index:int) -> void:
	if not has_layer(from_index) or not has_layer(to_index-1):
		return

	var info: Resource = layers.pop_at(from_index)
	layers.insert(to_index, info)
	changed.emit()


func set_layer_scene(layer_index:int, scene:String) -> void:
	if not has_layer(layer_index):
		return

	if layer_index == -1:
		base_scene = load(scene)
	else:
		layers[layer_index].scene = load(scene)

	changed.emit()


func set_layer_setting(layer:int, setting:String, value:Variant) -> void:
	if not has_layer(layer):
		return

	if layer == -1:
		base_overrides[setting] = value
	else:
		layers[layer].overrides[setting] = value

	changed.emit()


func remove_layer_setting(layer:int, setting:String) -> void:
	if not has_layer(layer):
		return

	if layer == -1:
		base_overrides.erase(setting)
	else:
		layers[layer].overrides.erase(setting)

	changed.emit()


## This merges two layers (mainly their overrides). Layer a has priority!
func merge_layer_infos(layer_a:Dictionary, layer_b:Dictionary) -> Dictionary:
	var combined := layer_a.duplicate(true)

	combined.path = layer_b.path
	combined.overrides.merge(layer_b.overrides)

	return combined


func has_layer(index:int) -> bool:
	return index < layers.size()


func inherits_anything() -> bool:
	return inherits != null


func get_inheritance_root() -> DialogicStyle:
	if inherits == null:
		return self

	var style: DialogicStyle = self
	while style.inherits != null:
		style = style.inherits

	return style


func realize_inheritance() -> void:
	base_scene = get_base_scene()
	base_overrides = get_layer_inherited_info(-1)

	var _layers: Array[DialogicStyleLayer] = []
	for i in range(get_layer_count()):
		var info := get_layer_inherited_info(i)
		_layers.append(DialogicStyleLayer.new(info.path, info.overrides))

	layers = _layers
	inherits = null
	changed.emit()


func clone() -> DialogicStyle:
	var style := DialogicStyle.new()
	style.name = name
	if base_scene != null:
		style.base_scene = base_scene.duplicate()
	style.inherits = inherits
	style.base_overrides = base_overrides
	for layer_idx in range(get_layer_count()):
		var info := get_layer_info(layer_idx)
		style.add_layer(info.path, info.overrides)

	return style


func prepare() -> void:
	if base_scene:
		ResourceLoader.load_threaded_request(base_scene.resource_path)

	for layer in layers:
		if layer.scene:
			ResourceLoader.load_threaded_request(layer.scene.resource_path)
