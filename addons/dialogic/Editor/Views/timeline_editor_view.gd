tool
extends Control

const DialogicUtil = preload("res://addons/dialogic/Core/DialogicUtil.gd")

var base_resource_path:String = "" setget _set_base_resource

var _resource = null

func _set_base_resource(path:String):
	var f = File.new()
	if not f.file_exists(path):
		DialogicUtil.print("File {} doesn't exist".format(path))
		return

	base_resource_path = path
	_resource = ResourceLoader.load(path)
	DialogicUtil.print(["Using {res} at {path}".format({"res":_resource.get_class(), "path":path})])
