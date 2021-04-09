tool
extends DialogicDatabaseResource

const DialogicUtil = preload("res://addons/dialogic/Core/DialogicUtil.gd")


func add(res:Resource):
	DialogicUtil.Logger.print(self,["adding a resource:",res.resource_path])
	resources.add(res)
	save(DialogicResources.TIMELINEDB_PATH)
	emit_signal("changed")

func scan_timelines_folder() -> void:
	var _d:Directory = Directory.new()
	if _d.open(DialogicResources.TIMELINES_DIR) == OK:
		_d.list_dir_begin(false, true)
		var _file_name = _d.get_next()
		while _file_name != "":
			if not _d.current_is_dir():
				var _current_resources_files = []
				var _c_res = resources.get_resources()
				for _r in _c_res:
					var _r_file = _r.resource_path.get_file()
					_current_resources_files.append(_r_file)
				
				for _r in _c_res:
					var _r_file = _r.resource_path.get_file()
					if not(_file_name in _current_resources_files):
						print_debug(_file_name+"is not in the timelines database")
					
			_file_name = _d.get_next()
		_d.list_dir_end()

func _to_string() -> String:
	return "[TimelineDatabase]"
