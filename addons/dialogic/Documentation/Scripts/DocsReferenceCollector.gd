tool
extends EditorScript
class_name ReferenceCollector
# Finds and generates a code reference from gdscript files.
#
# To use this tool:
#
# - Place this script and Collector.gd in your Godot project folder.
# - Open the script in the script editor.
# - Modify the properties below to control the tool's behavior.
# - Go to File -> Run to run the script in the editor.


var Collector: SceneTree = load("res://addons/dialogic/Documentation/Scripts/DocsCollector.gd").new()
# A list of directories to collect files from.
var directories := ["res://addons/dialogic/Nodes/"]
# If true, explore each directory recursively
var is_recursive: = true
# A list of patterns to filter files.
var patterns := ["*.gd"]
# Output path to save the class reference.
var save_path := "res://reference.json"


func _run() -> void:
	var files := PoolStringArray()
	for dirpath in directories:
		files.append_array(Collector.find_files(dirpath, patterns, is_recursive))
	var json: String = Collector.print_pretty_json(Collector.get_reference(files))
	Collector.save_text(save_path, json)
