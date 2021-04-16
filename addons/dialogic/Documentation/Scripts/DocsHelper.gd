tool
extends Node

# This file needs to be added as a Singleton
# to do this, add this line in the _init_ function of your plugin
# add_autoload_singleton('DocsHelper', "res://addons/<YourPluginName>/Documentation/Scripts/DocsHelper.gd")


var plugin_name = "dialogic"

var documentation_path = "res://addons/"+plugin_name+"/Documentation"

func _ready():
	get_documentation_content()

func get_documentation_content():
	return get_dir_contents(documentation_path+"/Content")

func get_dir_contents(rootPath: String) -> Dictionary:
	var directory_structure = {}
	var dir := Directory.new()

	if dir.open(rootPath) == OK:
		dir.list_dir_begin(true, false)
		directory_structure = _add_dir_contents(dir)
	else:
		push_error("Docs: An error occurred when trying to access the path.")

	return directory_structure

func _add_dir_contents(dir: Directory) -> Dictionary:
	var file_name = dir.get_next()

	var structure = {}
	while (file_name != ""):
		var path = dir.get_current_dir() + "/" + file_name

		if dir.current_is_dir():
			#print("Found directory: %s" % path)
			var subDir = Directory.new()
			subDir.open(path)
			subDir.list_dir_begin(true, false)
			structure[file_name] = _add_dir_contents(subDir)
		else:
			#print("Found file: %s" % path)
			if not structure.has("_files_"):
				structure["_files_"] = []
			if not file_name.ends_with(".md"):
				continue
			structure["_files_"].append(path)

		file_name = dir.get_next()
	dir.list_dir_end()
	return structure
