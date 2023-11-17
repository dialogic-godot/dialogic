@tool
extends Resource
class_name DialogicTransition

const default_shader = preload("res://addons/dialogic/Modules/Background/default_background_transition.gdshader")

@export var shader: Shader = default_shader

var parameters : Dictionary

func _get_property_list() -> Array[Dictionary]:
	return _get_filtered_uniforms()

func _set(property: StringName, value: Variant) -> bool:
	if property == "shader":
		if value == null:
			shader = default_shader
		else:
			shader = value
		parameters.clear()
	elif _get_filtered_uniforms().any(func (uniform) : return uniform["name"] == property):
		parameters[property] = value
	
	return false

func _get(property: StringName) -> Variant:
	if property == "shader":
		return shader
	elif parameters.has(property):
		return parameters[property]
	
	return null

func _get_filtered_uniforms() -> Array[Dictionary]:
	var uniforms = shader.get_shader_uniform_list()
	var filtered_uniforms: Array[Dictionary] = []
	
	for uniform in shader.get_shader_uniform_list():
		if uniform["name"] == "progress" || uniform["name"] == "previous_background" || uniform["name"] == "next_background":
			continue
		
		filtered_uniforms.append(uniform)
	
	return filtered_uniforms

func _to_string() -> String:
	return "<{shader}, {parameters}>".format({"shader":var_to_str(shader), "parameters":var_to_str(parameters)})
