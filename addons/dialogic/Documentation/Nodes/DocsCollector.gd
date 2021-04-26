tool
extends SceneTree
# Finds and generates a code reference from gdscript files.


# Returns a list of file paths found in the directory.
#
# **Arguments**
#
# - dirpath: path to the directory from which to search files.
# - patterns: an array of string match patterns, where "*" matches zero or more
#   arbitrary characters and "?" matches any single character except a period
#   ("."). You can use it to find files by extensions. To find only GDScript
#   files, ["*.gd"]
# - is_recursive: if `true`, walks over subdirectories recursively, returning all
#   files in the tree.
func find_files(
	dirpath := "", patterns := PoolStringArray(), is_recursive := false, do_skip_hidden := true
) -> PoolStringArray:
	var file_paths := PoolStringArray()
	var directory := Directory.new()

	if not directory.dir_exists(dirpath):
		printerr("The directory does not exist: %s" % dirpath)
		return file_paths
	if not directory.open(dirpath) == OK:
		printerr("Could not open the following dirpath: %s" % dirpath)
		return file_paths

	directory.list_dir_begin(true, do_skip_hidden)
	var file_name := directory.get_next()
	var subdirectories := PoolStringArray()
	while file_name != "":
		if directory.current_is_dir() and is_recursive:
			var subdirectory := dirpath.plus_file(file_name)
			file_paths.append_array(find_files(subdirectory, patterns, is_recursive))
		else:
			for pattern in patterns:
				if file_name.match(pattern):
					file_paths.append(dirpath.plus_file(file_name))
		file_name = directory.get_next()

	directory.list_dir_end()
	return file_paths


# Saves text to a file.
func save_text(path := "", content := "") -> void:
	var dirpath := path.get_base_dir()
	var basename := path.get_file()
	if not dirpath:
		printerr("Couldn't save: the path %s is invalid." % path)
		return
	if not basename.is_valid_filename():
		printerr("Couldn't save: the file name, %s, contains invalid characters." % basename)
		return

	var directory := Directory.new()
	if not directory.dir_exists(dirpath):
		directory.make_dir(dirpath)

	var file := File.new()

	file.open(path, File.WRITE)
	file.store_string(content)
	file.close()
	print("Saved data to %s" % path)


# Parses a list of GDScript files and returns a list of dictionaries with the
# code reference data.
#
# If `refresh_cache` is true, will refresh Godot's cache and get fresh symbols.
func get_reference(files := PoolStringArray(), refresh_cache := false) -> Dictionary:
	var data := {
		name = ProjectSettings.get_setting("application/config/name"),
		description = ProjectSettings.get_setting("application/config/description"),
		version = ProjectSettings.get_setting("application/config/version"),
		classes = []
	}
	var workspace = Engine.get_singleton('GDScriptLanguageProtocol').get_workspace()
	for file in files:
		if not file.ends_with(".gd"):
			continue
		if refresh_cache:
			workspace.parse_local_script(file)
		var symbols: Dictionary = workspace.generate_script_api(file)
		if symbols["name"] == "":
			symbols["name"] = file.get_file()
		data["classes"].append(symbols)
	return data


func print_pretty_json(reference: Dictionary) -> String:
	return JSON.print(reference, "  ")
