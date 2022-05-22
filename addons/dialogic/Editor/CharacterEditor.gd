tool
extends Control

func new_character(path):
	print('hi')
	var resource = DialogicCharacter.new()
	resource.resource_path = path
	ResourceSaver.save(path, resource)
