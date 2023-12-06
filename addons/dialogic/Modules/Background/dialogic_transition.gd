@tool
extends Resource
class_name DialogicTransition

const default_shader = preload("res://addons/dialogic/Modules/Background/default_background_transition.gdshader")

@export var shader: Shader = default_shader

@export var inherits : DialogicTransition = null

@export var base_overrides := {}

@export var name := "Transition":
	get:
		if name.is_empty():
			return "Unkown Transition"
		return name


func _init(_name:="") -> void:
	if not _name.is_empty():
		name = _name


func realize_inheritance() -> void:
	base_overrides = get_transition_overrides()
	
	inherits = null
	changed.emit()


## This always returns the inheritance root's shader.
func get_shader() -> Shader:
	var shader := get_inheritance_root().shader
	
	return shader if shader else default_shader


func set_parameter(name: String, value: Variant) -> void:
	base_overrides[name] = value
	
	changed.emit()


func remove_paramter(name: String) -> void:
	base_overrides.erase(name)
	
	changed.emit()


func inherits_anything() -> bool:
	return inherits != null


func get_transition_overrides(inherited_only:=false) -> Dictionary:
	var transition := self
	var overrides := base_overrides.duplicate(true) if !inherited_only else {}
	
	while transition.inherits != null:
		transition = transition.inherits
		overrides.merge(transition.base_overrides)
	
	return overrides


func get_inheritance_root() -> DialogicTransition:
	if inherits == null:
		return self
	
	var transition : DialogicTransition = self
	while transition.inherits != null:
		transition = transition.inherits
	
	return transition


func clone() -> DialogicTransition:
	var transition := DialogicTransition.new()
	transition.name = name
	transition.inherits = inherits
	transition.base_overrides = base_overrides
	
	return transition
