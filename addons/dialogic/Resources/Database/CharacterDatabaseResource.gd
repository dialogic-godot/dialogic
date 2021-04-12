tool
extends DialogicDatabaseResource

const DialogicUtil = preload("res://addons/dialogic/Core/DialogicUtil.gd")

func add(item:DialogicCharacterResource) -> void:
	DialogicUtil.Logger.print(self, ["Adding a character: ", item.resource_path])
	if item in resources.get_resources():
		push_warning("A resource is already there")
		var _r_array = resources.get_resources()
		var _idx = _r_array.find(item)
		if _idx != -1:
			_r_array[_idx] = item
			save(DialogicResources.TIMELINEDB_PATH)
			emit_signal("changed")
		return
	
	(resources as ResourceArray).add(item)
	save(DialogicResources.CHARACTERDB_PATH)
	emit_signal("changed")


func remove(item:DialogicCharacterResource) -> void:
	DialogicUtil.Logger.print(self,["removing a character:",item.resource_path])
	(resources as ResourceArray).remove(item)
	save(DialogicResources.CHARACTERDB_PATH)
	emit_signal("changed")


# Copied
func scan_characters_folder() -> void:
	push_warning("Scanning characters folder")
	var _d:Directory = Directory.new()
	if _d.open(DialogicResources.CHARACTERS_DIR) == OK:
		_d.list_dir_begin(false, true)
		var _file_name = _d.get_next()
		while _file_name != "":
			if not _d.current_is_dir():
				var _current_resources_files = []
				var _c_res = resources.get_resources()
				for _r in _c_res:
					if _r:
						var _r_file = _r.resource_path.get_file()
						_current_resources_files.append(_r_file)
				
				if not(_file_name in _current_resources_files):
					push_warning("File {} is not in the character database. Adding...".format({"":_file_name}))
					_current_resources_files.append(_file_name)
					add(load(DialogicResources.CHARACTERS_DIR+"/"+_file_name))
						
					
			_file_name = _d.get_next()
		_d.list_dir_end()
		push_warning("Done")

func _to_string() -> String:
	return "[CharacterDatabase]"
